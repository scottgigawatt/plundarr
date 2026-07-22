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
import tomllib
from pathlib import Path

from maraudarr.models import Preset, Service, StackPlan


class CatalogError(ValueError):
    """Report invalid catalog data or an impossible stack request."""


def default_catalog_root() -> Path:
    """Locate Maraudarr assets in either the image or source checkout."""

    configured_root = os.environ.get("MARAUDARR_CATALOG_ROOT")
    if configured_root:
        return Path(configured_root).resolve()

    return Path(__file__).resolve().parents[2]


class Catalog:
    """Provide validated service metadata, presets, and source paths."""

    def __init__(self, root: Path | None = None) -> None:
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
        """Convert one TOML service table into a typed model."""

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
        """Convert one TOML preset table into a typed model."""

        return Preset(
            id=preset_id,
            title=str(values["title"]),
            description=str(values["description"]),
            compose_summary=tuple(str(item) for item in values["compose_summary"]),
            core=tuple(str(item) for item in values.get("core", [])),
            defaults=tuple(str(item) for item in values.get("defaults", [])),
        )

    def _validate(self) -> None:
        """Reject missing files and unknown dependency or preset references."""

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

        for preset in self.presets.values():
            unknown_services = set(preset.services) - self.services.keys()
            if unknown_services:
                names = ", ".join(sorted(unknown_services))
                raise CatalogError(
                    f"Preset '{preset.id}' references unknown services: {names}."
                )

    def preset(self, preset_id: str) -> Preset:
        """Return one preset or raise an error listing valid choices."""

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
        """Resolve dependencies and return a deterministically ordered plan."""

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
        """Resolve one path within Maraudarr's owned catalog root."""

        source_path = (self.root / relative_path).resolve()
        if self.root not in source_path.parents and source_path != self.root:
            raise CatalogError(f"Source path escapes Maraudarr root: {relative_path}.")
        return source_path

    def config_path(self, service: Service) -> Path:
        """Return the optional config seed directory for one service."""

        return self.source_path(f"services/{service.id}/config")
