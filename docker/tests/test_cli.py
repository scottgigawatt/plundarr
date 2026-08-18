#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# test_cli.py: Verify Maraudarr chooses isolated preset project directories.
#

"""Exercise Maraudarr command-line output directory selection."""

from __future__ import annotations

import argparse
import os
import unittest
from pathlib import Path
from unittest.mock import patch

from maraudarr.catalog import Catalog
from maraudarr.cli import _output_path


class MaraudarrCliTests(unittest.TestCase):
    """Keep exact and preset-root output modes distinct."""

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
        environment = os.environ.copy()
        environment.pop("MARAUDARR_OUTPUT_ROOT", None)
        with patch.dict(os.environ, environment, clear=True):
            self.assertEqual(
                _output_path(arguments, self.catalog.resolve("plex")),
                Path("/output/dist/plex"),
            )


if __name__ == "__main__":
    unittest.main()
