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
    """Normalize a comma-separated CLI value and discard empty entries."""
    return {item.strip() for item in (value or "").split(",") if item.strip()}


def _add_output_arguments(parser: argparse.ArgumentParser) -> None:
    """Add exact-output and preset-directory output options to one command."""
    output_group = parser.add_mutually_exclusive_group()
    output_group.add_argument(
        "--output",
        help="Exact directory that receives one generated Plundarr project.",
    )
    output_group.add_argument(
        "--output-root",
        help="Parent directory that receives one project directory per preset.",
    )


def _parser() -> argparse.ArgumentParser:
    """Create the parser shared by interactive and deterministic commands."""
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
    _add_output_arguments(build_parser)

    configure_parser = subparsers.add_parser(
        "configure",
        help="Choose a preset and services interactively.",
    )
    _add_output_arguments(configure_parser)

    subparsers.add_parser("presets", help="Show every preset and its services.")
    subparsers.add_parser("services", help="Show every selectable service.")
    return parser


def _write(catalog: Catalog, plan: StackPlan, output: Path, ui: UI) -> int:
    """Confirm and generate one plan while reporting progress through the UI."""
    ui.show_plan(plan)
    if not ui.confirm():
        raise UserCancelled("Voyage cancelled before the stack was built.")

    ui.progress("🧭 Charting the selected services...")
    ui.progress("📦 Packing the environment and config cargo...")
    compose_path, env_path, config_path = write_stack(catalog, plan, output)
    ui.progress("🔎 Docker Compose inspection passed.")
    ui.success(plan, str(compose_path), str(env_path), str(config_path))
    return 0


def _output_path(arguments: argparse.Namespace, plan: StackPlan) -> Path:
    """Resolve an exact output directory or the preset directory below a root."""
    if arguments.output:
        return Path(arguments.output).resolve()

    output_root = arguments.output_root or os.environ.get(
        "MARAUDARR_OUTPUT_ROOT", "/output/dist"
    )
    return (Path(output_root).resolve() / plan.preset.id).resolve()


def _interactive_plan(catalog: Catalog, ui: UI) -> StackPlan:
    """Collect an interactive selection and resolve its dependencies."""
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
    """Run the Maraudarr command-line application.

    Args:
        arguments: Optional argument vector excluding the executable name.
            Process arguments are used when this value is absent.

    Returns:
        ``0`` after a successful command, ``1`` after a catalog, rendering, or
        operating-system failure, or ``130`` after intentional cancellation.

    Note:
        Argument-parser usage errors and ``--version`` retain argparse's normal
        ``SystemExit`` behavior.
    """
    raw_arguments = list(sys.argv[1:] if arguments is None else arguments)

    # Normalize --plain so argparse accepts it before or after the subcommand.
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
            output_path = _output_path(arguments_namespace, plan)
            return _write(catalog, plan, output_path, ui)

        plan = _interactive_plan(catalog, ui)
        output_path = _output_path(arguments_namespace, plan)
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
