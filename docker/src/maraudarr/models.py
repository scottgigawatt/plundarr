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
    """Describe one selectable service and its Maraudarr-owned sources."""

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
    """Describe an opinionated starting selection for a stack."""

    id: str
    title: str
    description: str
    compose_summary: tuple[str, ...]
    core: tuple[str, ...]
    defaults: tuple[str, ...]

    @property
    def services(self) -> tuple[str, ...]:
        """Return every service selected by default."""

        return self.core + self.defaults


@dataclass(frozen=True)
class StackPlan:
    """Store a resolved service selection in deterministic output order."""

    preset: Preset
    services: tuple[Service, ...]
    auto_added: tuple[str, ...]

    @property
    def service_ids(self) -> tuple[str, ...]:
        """Return selected service identifiers."""

        return tuple(service.id for service in self.services)
