#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# catalog.py: Load, validate, and resolve Maraudarr service and preset metadata.
#

"""Load Maraudarr's modular service catalog and resolve stack selections."""

from __future__ import annotations

import os
import re
import tomllib
from collections.abc import Mapping, Sequence
from ipaddress import IPv4Address, IPv4Network, ip_address, ip_network
from pathlib import Path
from typing import cast

from maraudarr.models import Preset, Service, StackPlan
from maraudarr.text import TemplateError, extract_service


class CatalogError(ValueError):
    """Report invalid catalog data or an impossible stack request."""


def _strings(value: object) -> tuple[str, ...]:
    """Validate a catalog list before passing its items to immutable models."""
    if not isinstance(value, list):
        raise CatalogError("Expected a list of catalog strings.")

    # TOML decoding establishes containers but cannot provide their generic item types.
    items = cast(Sequence[object], value)
    result: list[str] = []

    for item in items:
        if not isinstance(item, str):
            raise CatalogError("Expected a string in a catalog list.")

        result.append(item)

    return tuple(result)


def _integer(value: object) -> int:
    """Require a TOML integer for ordering and port offsets."""
    if not isinstance(value, int) or isinstance(value, bool):
        raise CatalogError("Expected a catalog integer.")

    return value


def _volume_descriptions(value: object) -> dict[str, str]:
    """Validate storage descriptions before they enter the typed service model."""
    if not isinstance(value, dict):
        raise CatalogError("Expected a named volume table.")

    fields = cast(Mapping[object, object], value)
    descriptions: dict[str, str] = {}

    for name, description in fields.items():
        if not isinstance(name, str) or not isinstance(description, str):
            raise CatalogError("Named volumes require string names and storage descriptions.")

        descriptions[name] = description

    return descriptions


def default_catalog_root() -> Path:
    """Locate Maraudarr assets in either the image or source checkout.

    Returns:
        The resolved ``MARAUDARR_CATALOG_ROOT`` override when configured;
        otherwise, the package's owning ``docker`` directory.
    """
    configured_root = os.environ.get("MARAUDARR_CATALOG_ROOT")
    if configured_root:
        return Path(configured_root).resolve()

    return Path(__file__).resolve().parents[2]


class Catalog:
    """Provide validated service metadata, presets, and owned source paths.

    Attributes:
        root: Resolved directory containing catalog, template, and service data.
        services: Service metadata keyed by stable catalog identifier.
        presets: Preset metadata keyed by stable preset identifier.
    """

    def __init__(self, root: Path | None = None) -> None:
        """Load and validate one Maraudarr catalog tree.

        Args:
            root: Optional catalog root. The environment-aware default is used
                when this value is absent.

        Raises:
            CatalogError: If files, dependencies, or preset references are
                invalid.
            OSError: If the catalog cannot be read from disk.
            tomllib.TOMLDecodeError: If ``catalog.toml`` is malformed.
        """
        self.root = (root or default_catalog_root()).resolve()
        catalog_path = self.root / "catalog" / "catalog.toml"

        with catalog_path.open("rb") as catalog_file:
            data = tomllib.load(catalog_file)

        self.services = {
            service_id: self._load_service(service_id, values)
            for service_id, values in data["services"].items()
        }
        self.presets = {
            preset_id: self._load_preset(preset_id, values)
            for preset_id, values in data["presets"].items()
        }
        self._validate()

    @staticmethod
    def _load_service(service_id: str, values: dict[str, object]) -> Service:
        """Normalize one trusted TOML service table into a typed model."""
        service_name = str(values.get("service", service_id))
        base_path = f"services/{service_id}"
        return Service(
            id=service_id,
            title=str(values["title"]),
            description=str(values["description"]),
            category=str(values["category"]),
            url=str(values["url"]),
            order=_integer(values["order"]),
            compose=str(values.get("compose", f"{base_path}/compose.yml")),
            environment=str(values.get("environment", f"{base_path}/environment.env")),
            service=service_name,
            compose_services=_strings(values.get("compose_services", [service_name])),
            named_volumes=_volume_descriptions(values.get("named_volumes", {})),
            requires=_strings(values.get("requires", [])),
            recommended=_strings(values.get("recommended", [])),
        )

    @staticmethod
    def _load_preset(preset_id: str, values: dict[str, object]) -> Preset:
        """Normalize one trusted TOML preset table into a typed model."""
        return Preset(
            id=preset_id,
            title=str(values["title"]),
            description=str(values["description"]),
            compose_summary=_strings(values["compose_summary"]),
            project_name=str(values["project_name"]),
            network_subnet=str(values["network_subnet"]),
            network_ip_range=str(values["network_ip_range"]),
            network_gateway=str(values["network_gateway"]),
            media_root=str(values["media_root"]),
            media_libraries=_strings(values["media_libraries"]),
            host_port_offset=_integer(values.get("host_port_offset", 0)),
            core=_strings(values.get("core", [])),
            defaults=_strings(values.get("defaults", [])),
        )

    def _validate(self) -> None:
        """Reject missing sources and cross-references before resolution."""
        volume_owners: dict[str, str] = {}
        compose_owners: dict[str, str] = {}
        for service in self.services.values():
            for volume, description in service.named_volumes.items():
                if not re.fullmatch(r"[a-z][a-z0-9_-]*", volume):
                    raise CatalogError(
                        f"Service '{service.id}' has invalid named volume: {volume!r}."
                    )
                if volume in volume_owners:
                    raise CatalogError(f"Named volume '{volume}' has multiple declarations.")
                if not description.strip() or len(description.splitlines()) != 1:
                    raise CatalogError(
                        f"Named volume '{volume}' requires a single-line storage description."
                    )
                volume_owners[volume] = service.id
            for relative_path in (service.compose, service.environment):
                if not self.source_path(relative_path).is_file():
                    raise CatalogError(
                        f"Service '{service.id}' source does not exist: {relative_path}."
                    )
            if service.service not in service.compose_services:
                raise CatalogError(
                    f"Service '{service.id}' must include its primary Compose service."
                )
            source = self.source_path(service.compose).read_text()
            for name in service.compose_services:
                if name in compose_owners:
                    raise CatalogError(f"Compose service '{name}' has multiple owners.")
                try:
                    extract_service(source, name)
                except TemplateError as error:
                    raise CatalogError(str(error)) from error
                compose_owners[name] = service.id
            for dependency in service.requires + service.recommended:
                if dependency not in self.services:
                    raise CatalogError(
                        f"Service '{service.id}' references unknown service '{dependency}'."
                    )

        preset_networks: dict[str, IPv4Network] = {}
        project_names: dict[str, str] = {}
        for preset in self.presets.values():
            unknown_services = set(preset.services) - self.services.keys()
            if unknown_services:
                names = ", ".join(sorted(unknown_services))
                raise CatalogError(f"Preset '{preset.id}' references unknown services: {names}.")
            unknown_libraries = set(preset.media_libraries) - {
                "anime",
                "movies",
                "scenes",
                "tv",
            }
            if unknown_libraries:
                names = ", ".join(sorted(unknown_libraries))
                raise CatalogError(
                    f"Preset '{preset.id}' references unknown media libraries: {names}."
                )
            if preset.host_port_offset < 0:
                raise CatalogError(f"Preset '{preset.id}' has a negative host port offset.")

            try:
                subnet = ip_network(preset.network_subnet)
                ip_range = ip_network(preset.network_ip_range)
                gateway = ip_address(preset.network_gateway)
            except ValueError as error:
                raise CatalogError(
                    f"Preset '{preset.id}' has invalid IPv4 network settings: {error}."
                ) from error
            if not isinstance(subnet, IPv4Network) or not isinstance(gateway, IPv4Address):
                raise CatalogError(f"Preset '{preset.id}' must use IPv4 network settings.")
            if not isinstance(ip_range, IPv4Network) or not ip_range.subnet_of(subnet):
                raise CatalogError(f"Preset '{preset.id}' IP range must be inside its subnet.")
            if gateway not in ip_range:
                raise CatalogError(f"Preset '{preset.id}' gateway must be inside its IP range.")
            for other_id, other_network in preset_networks.items():
                if subnet.overlaps(other_network):
                    raise CatalogError(
                        f"Preset '{preset.id}' network overlaps preset '{other_id}'."
                    )
            preset_networks[preset.id] = subnet

            other_preset = project_names.get(preset.project_name)
            if other_preset:
                raise CatalogError(
                    f"Preset '{preset.id}' reuses the Compose project name from "
                    f"preset '{other_preset}'."
                )
            project_names[preset.project_name] = preset.id

    def preset(self, preset_id: str) -> Preset:
        """Return a named preset.

        Args:
            preset_id: Stable catalog identifier for the requested preset.

        Returns:
            The matching immutable preset.

        Raises:
            CatalogError: If the identifier is unknown. The message includes
                every available preset identifier.
        """
        try:
            return self.presets[preset_id]
        except KeyError as error:
            choices = ", ".join(sorted(self.presets))
            raise CatalogError(
                f"Unknown preset '{preset_id}'. Available presets: {choices}."
            ) from error

    def resolve(
        self,
        preset_id: str,
        add: set[str] | None = None,
        remove: set[str] | None = None,
        selected: set[str] | None = None,
    ) -> StackPlan:
        """Resolve one preset and service selection into a generation plan.

        Args:
            preset_id: Preset supplying stack identity and core services.
            add: Service IDs explicitly added after the starting selection.
            remove: Optional service IDs removed before additions are applied.
            selected: Complete starting selection for interactive or custom
                flows. Preset defaults are used when this value is absent.

        Returns:
            An immutable plan containing recursively resolved dependencies in
            deterministic catalog order.

        Raises:
            CatalogError: If the preset or a requested service is unknown, or
                if a custom selection would produce an empty stack.
        """
        preset = self.preset(preset_id)
        requested = set(preset.services if selected is None else selected)
        requested.difference_update(remove or set())
        requested.update(add or set())
        requested.update(preset.core)

        unknown_services = requested - self.services.keys()
        if unknown_services:
            names = ", ".join(sorted(unknown_services))
            raise CatalogError(f"Unknown services requested: {names}.")
        if not requested:
            raise CatalogError("A custom stack must contain at least one service.")

        # Record the user-visible selection before recursively adding required
        # services so the UI can explain which dependencies joined the fleet.
        explicitly_requested = set(requested)
        pending = list(requested)
        while pending:
            service_id = pending.pop()
            for dependency in self.services[service_id].requires:
                if dependency not in requested:
                    requested.add(dependency)
                    pending.append(dependency)

        ordered_services = tuple(
            sorted(
                (self.services[service_id] for service_id in requested),
                key=lambda service: (service.order, service.id),
            )
        )
        return StackPlan(
            preset=preset,
            services=ordered_services,
            auto_added=tuple(sorted(requested - explicitly_requested)),
        )

    def source_path(self, relative_path: str) -> Path:
        """Resolve a path that must remain inside the catalog root.

        Args:
            relative_path: Catalog-root-relative source path.

        Returns:
            The normalized absolute source path.

        Raises:
            CatalogError: If normalization would escape the owned root.
        """
        source_path = (self.root / relative_path).resolve()
        if self.root not in source_path.parents and source_path != self.root:
            raise CatalogError(f"Source path escapes Maraudarr root: {relative_path}.")
        return source_path

    def config_path(self, service: Service) -> Path:
        """Return the optional config seed directory for one service.

        Args:
            service: Service whose project-owned config seeds are requested.

        Returns:
            The normalized path beneath ``services/<id>/config``.

        Raises:
            CatalogError: If the derived source path escapes the catalog root.
        """
        return self.source_path(f"services/{service.id}/config")
