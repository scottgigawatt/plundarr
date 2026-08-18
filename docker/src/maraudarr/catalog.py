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
from ipaddress import IPv4Address, IPv4Network, ip_address, ip_network
from pathlib import Path

import tomllib

from maraudarr.models import Preset, Service, StackPlan


class CatalogError(ValueError):
    """Report invalid catalog data or an impossible stack request."""


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
            order=int(values["order"]),
            compose=str(values.get("compose", f"{base_path}/compose.yml")),
            environment=str(
                values.get("environment", f"{base_path}/environment.env")
            ),
            service=service_name,
            requires=tuple(str(item) for item in values.get("requires", [])),
            recommended=tuple(
                str(item) for item in values.get("recommended", [])
            ),
        )

    @staticmethod
    def _load_preset(preset_id: str, values: dict[str, object]) -> Preset:
        """Normalize one trusted TOML preset table into a typed model."""
        return Preset(
            id=preset_id,
            title=str(values["title"]),
            description=str(values["description"]),
            compose_summary=tuple(str(item) for item in values["compose_summary"]),
            project_name=str(values["project_name"]),
            network_subnet=str(values["network_subnet"]),
            network_ip_range=str(values["network_ip_range"]),
            network_gateway=str(values["network_gateway"]),
            media_root=str(values["media_root"]),
            media_libraries=tuple(str(item) for item in values["media_libraries"]),
            host_port_offset=int(values.get("host_port_offset", 0)),
            core=tuple(str(item) for item in values.get("core", [])),
            defaults=tuple(str(item) for item in values.get("defaults", [])),
        )

    def _validate(self) -> None:
        """Reject missing sources and cross-references before resolution."""
        for service in self.services.values():
            for relative_path in (service.compose, service.environment):
                if not self.source_path(relative_path).is_file():
                    raise CatalogError(
                        f"Service '{service.id}' source does not exist: {relative_path}."
                    )
            for dependency in service.requires + service.recommended:
                if dependency not in self.services:
                    raise CatalogError(
                        f"Service '{service.id}' references unknown service "
                        f"'{dependency}'."
                    )

        preset_networks: dict[str, IPv4Network] = {}
        project_names: dict[str, str] = {}
        for preset in self.presets.values():
            unknown_services = set(preset.services) - self.services.keys()
            if unknown_services:
                names = ", ".join(sorted(unknown_services))
                raise CatalogError(
                    f"Preset '{preset.id}' references unknown services: {names}."
                )
            unknown_libraries = set(preset.media_libraries) - {
                "anime",
                "movies",
                "scenes",
                "tv",
            }
            if unknown_libraries:
                names = ", ".join(sorted(unknown_libraries))
                raise CatalogError(
                    f"Preset '{preset.id}' references unknown media libraries: "
                    f"{names}."
                )
            if preset.host_port_offset < 0:
                raise CatalogError(
                    f"Preset '{preset.id}' has a negative host port offset."
                )

            try:
                subnet = ip_network(preset.network_subnet)
                ip_range = ip_network(preset.network_ip_range)
                gateway = ip_address(preset.network_gateway)
            except ValueError as error:
                raise CatalogError(
                    f"Preset '{preset.id}' has invalid IPv4 network settings: {error}."
                ) from error
            if not isinstance(subnet, IPv4Network) or not isinstance(
                gateway, IPv4Address
            ):
                raise CatalogError(
                    f"Preset '{preset.id}' must use IPv4 network settings."
                )
            if not isinstance(ip_range, IPv4Network) or not ip_range.subnet_of(
                subnet
            ):
                raise CatalogError(
                    f"Preset '{preset.id}' IP range must be inside its subnet."
                )
            if gateway not in ip_range:
                raise CatalogError(
                    f"Preset '{preset.id}' gateway must be inside its IP range."
                )
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
