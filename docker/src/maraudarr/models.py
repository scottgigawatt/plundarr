#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# models.py: Immutable service, preset, and resolved stack data models.
#

"""Catalog models used while planning a generated Plundarr stack."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class Service:
    """Describe one selectable service and its Maraudarr-owned sources.

    Attributes:
        id: Stable catalog identifier used by presets and CLI selections.
        title: Human-readable service name displayed by Maraudarr.
        description: Short explanation of the service's stack responsibility.
        category: UI group used when presenting selectable services.
        url: Upstream project or service information URL.
        order: Primary deterministic position in generated output.
        compose: Catalog-root-relative Compose source path.
        environment: Catalog-root-relative environment source path.
        service: Compose service key extracted from the source chart.
        requires: Service IDs added automatically as hard dependencies.
        recommended: Related service IDs shown as non-mandatory companions.
    """

    id: str
    title: str
    description: str
    category: str
    url: str
    order: int
    compose: str
    environment: str
    service: str
    requires: tuple[str, ...]
    recommended: tuple[str, ...]


@dataclass(frozen=True)
class Preset:
    """Describe an opinionated starting selection for a stack.

    Attributes:
        id: Stable identifier accepted by the CLI.
        title: Human-readable preset name displayed by Maraudarr.
        description: Short explanation of the preset's intended voyage.
        compose_summary: Comment lines inserted into the generated chart header.
        project_name: Compose project namespace used by fresh environments.
        network_subnet: Default private network allocated to the preset.
        network_ip_range: Default container allocation range within the subnet.
        network_gateway: Default gateway address within the subnet.
        media_root: Host directory containing the preset's media libraries.
        plex_libraries: Library directories mounted when Plex is selected.
        core: Service IDs that cannot be removed from this preset.
        defaults: Optional service IDs selected when the preset starts.
    """

    id: str
    title: str
    description: str
    compose_summary: tuple[str, ...]
    project_name: str
    network_subnet: str
    network_ip_range: str
    network_gateway: str
    media_root: str
    plex_libraries: tuple[str, ...]
    core: tuple[str, ...]
    defaults: tuple[str, ...]

    @property
    def services(self) -> tuple[str, ...]:
        """Return every core and optional service selected by default.

        Returns:
            Service IDs in preset declaration order, with core services first.
        """
        return self.core + self.defaults


@dataclass(frozen=True)
class StackPlan:
    """Store a resolved service selection in deterministic output order.

    Attributes:
        preset: Preset that supplied the plan's identity and core services.
        services: Fully resolved services in stable generation order.
        auto_added: Required service IDs absent from the explicit selection.
    """

    preset: Preset
    services: tuple[Service, ...]
    auto_added: tuple[str, ...]

    @property
    def service_ids(self) -> tuple[str, ...]:
        """Return selected service identifiers in generation order.

        Returns:
            Service IDs matching the order of ``services``.
        """
        return tuple(service.id for service in self.services)
