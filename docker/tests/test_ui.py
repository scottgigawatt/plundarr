#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# test_ui.py: Verify Maraudarr's dependency-free preset and service listings.
#

"""Exercise readable no-color terminal listings for Maraudarr choices."""

from __future__ import annotations

import io
import unittest
from contextlib import redirect_stdout
from pathlib import Path

from maraudarr.catalog import Catalog
from maraudarr.ui import UI


class MaraudarrUiTests(unittest.TestCase):
    """Keep plain output readable when terminal styling is unavailable."""

    @classmethod
    def setUpClass(cls) -> None:
        """Load the catalog once for the terminal-listing checks."""

        cls.catalog = Catalog(Path(__file__).resolve().parents[1])

    def test_plain_preset_listing_uses_voyage_labels(self) -> None:
        """Show each preset's purpose and default services in clear sections."""

        output = io.StringIO()
        with redirect_stdout(output):
            UI(plain=True).show_presets(
                list(self.catalog.presets.values()),
                self.catalog.services,
            )

        listing = output.getvalue()
        self.assertIn("🗺️ Preset voyages", listing)
        self.assertIn("🏴‍☠️ Plundarr", listing)
        self.assertIn("Included by default:", listing)

    def test_plain_service_listing_groups_services_by_category(self) -> None:
        """Use category headings instead of one undifferentiated service list."""

        output = io.StringIO()
        with redirect_stdout(output):
            UI(plain=True).show_service_choices(
                sorted(self.catalog.services.values(), key=lambda item: item.order)
            )

        listing = output.getvalue()
        self.assertIn("🧰 Service cargo", listing)
        self.assertIn("🛡️ VPN foundation", listing)
        self.assertIn("⬇️ Download clients", listing)
        self.assertIn("qBittorrent", listing)


if __name__ == "__main__":
    unittest.main()
