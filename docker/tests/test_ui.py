#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# test_ui.py: Verify Maraudarr's preset and service terminal listings.
#

"""Exercise readable plain and styled terminal listings for Maraudarr choices."""

from __future__ import annotations

import io
import unittest
from contextlib import redirect_stdout
from pathlib import Path

from maraudarr.catalog import Catalog
from maraudarr.ui import RICH_AVAILABLE, UI


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
        self.assertIn("📚 Calibre-Web Automated", listing)
        self.assertIn("🎭 Duplex", listing)
        self.assertIn("🔭 Watchtower", listing)
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
        self.assertIn("🎭 Plex utilities", listing)
        self.assertIn("qBittorrent", listing)
        self.assertIn("Lidarr", listing)
        self.assertIn("Recyclarr", listing)

    def test_recyclarr_success_requires_a_preview_before_sync(self) -> None:
        """Call out Recyclarr's API credentials and preview-first workflow."""

        output = io.StringIO()
        plan = self.catalog.resolve("plundarr", add={"lidarr", "recyclarr"})
        with redirect_stdout(output):
            UI(plain=True).success(
                plan,
                "dist/plundarr/docker-compose.yml",
                "dist/plundarr/.env",
                "dist/plundarr/config",
            )

        listing = output.getvalue()
        self.assertIn(
            "Set Recyclarr API keys and preview the sync before applying it.",
            listing,
        )
        self.assertIn("Check download, media, and config paths in .env.", listing)

    def test_duplex_success_reminds_users_to_review_external_paths(self) -> None:
        """Call out the host-specific Kometa and Plex paths before launch."""

        output = io.StringIO()
        plan = self.catalog.resolve("duplex")
        with redirect_stdout(output):
            UI(plain=True).success(
                plan,
                "dist/duplex/docker-compose.yml",
                "dist/duplex/.env",
                "dist/duplex/config",
            )

        listing = output.getvalue()
        self.assertIn("Check Kometa, Plex, and config paths in .env.", listing)
        self.assertIn("make up PRESET=duplex", listing)

    def test_calibre_web_automated_success_calls_out_storage_paths(self) -> None:
        """Remind standalone CWA users to review its persistent mounts."""

        output = io.StringIO()
        plan = self.catalog.resolve("calibre-web-automated")
        with redirect_stdout(output):
            UI(plain=True).success(
                plan,
                "dist/calibre-web-automated/docker-compose.yml",
                "dist/calibre-web-automated/.env",
                "dist/calibre-web-automated/config",
            )

        listing = output.getvalue()
        self.assertIn("Check CWA config, ingest, and library paths in .env.", listing)
        self.assertIn("make up PRESET=calibre-web-automated", listing)

    @unittest.skipUnless(RICH_AVAILABLE, "Rich is not installed")
    def test_styled_tables_keep_emoji_outside_grid_cells(self) -> None:
        """Avoid terminal-dependent emoji widths inside bordered table columns."""

        from rich.console import Console

        output = io.StringIO()
        ui = UI()
        ui.console = Console(
            color_system=None,
            file=output,
            force_terminal=False,
            width=120,
        )

        ui.show_presets(
            list(self.catalog.presets.values()),
            self.catalog.services,
        )
        ui.show_service_choices(
            sorted(self.catalog.services.values(), key=lambda item: item.order)
        )

        listing = output.getvalue()
        self.assertIn("Plundarr", listing)
        self.assertIn("VPN foundation", listing)
        self.assertNotIn("🏴‍☠️ Plundarr", listing)
        self.assertNotIn("🛡️ VPN foundation", listing)


if __name__ == "__main__":
    unittest.main()
