#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# cli.py: Parse Maraudarr commands and coordinate interactive stack generation.
#

"""Command-line interface for the Maraudarr generator."""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

from maraudarr import __version__
from maraudarr.catalog import Catalog, CatalogError
from maraudarr.models import StackPlan
from maraudarr.render import RenderError, write_stack
from maraudarr.ui import UI, UserCancelled


def _comma_set(value: str | None) -> set[str]:
    """Convert a comma-separated command value into normalized service IDs."""

    return {item.strip() for item in (value or "").split(",") if item.strip()}


def _parser() -> argparse.ArgumentParser:
    """Create the complete Maraudarr command parser."""

    parser = argparse.ArgumentParser(
        prog="maraudarr",
        description="Generate a polished, reusable Plundarr Docker Compose stack.",
    )
    parser.add_argument(
        "--plain",
        action="store_true",
        help="Disable styled terminal output.",
    )
    parser.add_argument(
        "--version",
        action="version",
        version=f"Maraudarr {__version__}",
    )
    subparsers = parser.add_subparsers(dest="command")

    build_parser = subparsers.add_parser(
        "build",
        help="Generate a stack without interactive prompts.",
    )
    build_parser.add_argument(
        "--preset",
        default="plundarr",
        help="Preset used as the starting service selection.",
    )
    build_parser.add_argument(
        "--add",
        default="",
        help="Comma-separated services to add.",
    )
    build_parser.add_argument(
        "--remove",
        default="",
        help="Comma-separated optional services to remove.",
    )
    build_parser.add_argument(
        "--output",
        default=os.environ.get("MARAUDARR_OUTPUT", "/output"),
        help="Repository directory that receives generated Plundarr files.",
    )

    configure_parser = subparsers.add_parser(
        "configure",
        help="Choose a preset and services interactively.",
    )
    configure_parser.add_argument(
        "--output",
        default=os.environ.get("MARAUDARR_OUTPUT", "/output"),
        help="Repository directory that receives generated Plundarr files.",
    )

    subparsers.add_parser("presets", help="Show every preset and its services.")
    subparsers.add_parser("services", help="Show every selectable service.")
    return parser


def _write(catalog: Catalog, plan: StackPlan, output: Path, ui: UI) -> int:
    """Confirm, generate, and report one resolved stack plan."""

    ui.show_plan(plan)
    if not ui.confirm():
        raise UserCancelled("Voyage cancelled before the stack was built.")

    ui.progress("🧭 Charting the selected services...")
    ui.progress("📦 Packing the environment and config cargo...")
    compose_path, env_path, config_path = write_stack(catalog, plan, output)
    ui.progress("🔎 Docker Compose inspection passed.")
    ui.success(plan, str(compose_path), str(env_path), str(config_path))
    return 0


def _interactive_plan(catalog: Catalog, ui: UI) -> StackPlan:
    """Collect an interactive preset and service selection."""

    ui.welcome()
    presets = list(catalog.presets.values())
    ui.show_presets(presets, catalog.services)
    preset_id = ui.choose_preset(presets)
    preset = catalog.preset(preset_id)
    selectable_services = [
        service
        for service in sorted(catalog.services.values(), key=lambda item: item.order)
        if service.id not in preset.core
    ]
    ui.show_service_choices(selectable_services)
    selected = ui.choose_services(selectable_services, set(preset.defaults))
    return catalog.resolve(preset_id, selected=selected)


def main(arguments: list[str] | None = None) -> int:
    """Run Maraudarr and return a process-compatible status code."""

    raw_arguments = list(sys.argv[1:] if arguments is None else arguments)
    plain_requested = "--plain" in raw_arguments
    raw_arguments = [item for item in raw_arguments if item != "--plain"]
    arguments_namespace = _parser().parse_args(raw_arguments)
    arguments_namespace.plain = arguments_namespace.plain or plain_requested
    ui = UI(plain=arguments_namespace.plain)

    try:
        catalog = Catalog()
        command = arguments_namespace.command or "configure"

        if command == "presets":
            ui.welcome()
            ui.show_presets(list(catalog.presets.values()), catalog.services)
            return 0

        if command == "services":
            ui.welcome()
            ui.show_service_choices(
                sorted(catalog.services.values(), key=lambda item: item.order)
            )
            return 0

        if command == "build":
            plan = catalog.resolve(
                arguments_namespace.preset,
                add=_comma_set(arguments_namespace.add),
                remove=_comma_set(arguments_namespace.remove),
            )
            output_path = Path(arguments_namespace.output).resolve()
            return _write(catalog, plan, output_path, ui)

        plan = _interactive_plan(catalog, ui)
        output_path = Path(arguments_namespace.output).resolve()
        return _write(catalog, plan, output_path, ui)
    except UserCancelled as error:
        ui.cancelled(str(error))
        return 130
    except (CatalogError, RenderError, OSError) as error:
        ui.error(
            str(error),
            "Review the selected preset and service settings, then try again.",
        )
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
