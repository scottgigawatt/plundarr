#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# test_cli.py: Verify Maraudarr selections and isolated preset project directories.
#

"""Exercise CLI defaults, interactive selections, and output directory policy."""

from __future__ import annotations

import argparse
import io
import os
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

from maraudarr.catalog import Catalog

# Test internal planning and output policy without writing a generated deployment.
from maraudarr.cli import (
    _interactive_plan,  # pyright: ignore[reportPrivateUsage]
    _output_path,  # pyright: ignore[reportPrivateUsage]
    main,
)
from maraudarr.models import Service, StackPlan
from maraudarr.ui import UI


class MaraudarrCliTests(unittest.TestCase):
    """Keep CLI selections consistent and generated preset directories distinct."""

    @classmethod
    def setUpClass(cls) -> None:
        """Load the shared source catalog once for these output tests."""

        cls.catalog = Catalog(Path(__file__).resolve().parents[1])

    def test_output_root_places_each_preset_in_its_own_directory(self) -> None:
        """Avoid Compose, environment, and config collisions between presets."""

        arguments = argparse.Namespace(output=None, output_root="/tmp/maraudarr")

        self.assertEqual(
            _output_path(arguments, self.catalog.resolve("plundarr")),
            Path("/tmp/maraudarr/plundarr").resolve(),
        )
        self.assertEqual(
            _output_path(arguments, self.catalog.resolve("boudoirr")),
            Path("/tmp/maraudarr/boudoirr").resolve(),
        )

    def test_exact_output_remains_available_for_automation(self) -> None:
        """Keep matrix and advanced callers able to select one exact directory."""

        arguments = argparse.Namespace(output="/tmp/maraudarr-case", output_root=None)

        self.assertEqual(
            _output_path(arguments, self.catalog.resolve("jellyfin")),
            Path("/tmp/maraudarr-case").resolve(),
        )

    def test_default_output_root_is_the_dist_directory(self) -> None:
        """Make direct image use follow the same deployment layout as Make."""

        arguments = argparse.Namespace(output=None, output_root=None)

        # Remove any operator override so this case exercises the image default output root.
        environment = os.environ.copy()
        environment.pop("MARAUDARR_OUTPUT_ROOT", None)

        with patch.dict(os.environ, environment, clear=True):
            self.assertEqual(
                _output_path(arguments, self.catalog.resolve("plex")),
                Path("/output/dist/plex"),
            )

    def test_boudoirr_cli_default_and_removal_reach_the_generation_plan(self) -> None:
        """Keep deterministic builds and explicit removal consistent with the catalog."""
        plans: list[StackPlan] = []

        def capture_write(catalog: Catalog, plan: StackPlan, output: Path, ui: UI) -> int:
            """Record resolved selections without writing private deployment files."""
            plans.append(plan)
            return 0

        with (
            patch("maraudarr.cli.Catalog", return_value=self.catalog),
            patch("maraudarr.cli._write", side_effect=capture_write),
        ):
            self.assertEqual(main(["build", "--preset", "boudoirr", "--plain"]), 0)
            self.assertEqual(
                main(["build", "--preset", "boudoirr", "--remove", "velvarr", "--plain"]),
                0,
            )

        self.assertIn("velvarr", plans[0].service_ids)
        self.assertNotIn("velvarr", plans[1].service_ids)

    def test_boudoirr_interactive_default_can_be_unchecked(self) -> None:
        """Pass Velvarr to the picker as checked cargo without making it a core service."""
        ui = UI(plain=True)
        offered: list[set[str]] = []
        defaults: list[set[str]] = []
        plans: list[StackPlan] = []

        for omit_velvarr in (False, True):

            def choose_services(
                services: list[Service], selected: set[str], *, omit: bool = omit_velvarr
            ) -> set[str]:
                """Keep the initial selection or simulate unchecking Velvarr."""
                offered.append({service.id for service in services})
                defaults.append(selected.copy())
                return selected - {"velvarr"} if omit else selected

            # Replace terminal input while exercising the real interactive plan resolution.
            with (
                redirect_stdout(io.StringIO()),
                patch.object(ui, "choose_preset", return_value="boudoirr"),
                patch.object(ui, "choose_services", side_effect=choose_services),
            ):
                plans.append(_interactive_plan(self.catalog, ui))

        for available, checked in zip(offered, defaults, strict=True):
            self.assertIn("velvarr", available)
            self.assertIn("velvarr", checked)

        self.assertIn("velvarr", plans[0].service_ids)
        self.assertNotIn("velvarr", plans[1].service_ids)


if __name__ == "__main__":
    unittest.main()
