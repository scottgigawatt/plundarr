#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# test_jellyfin_clients.py: Verify optional clients and preserved Web customization.
#

"""Protect browser URL boundaries, preset isolation, and operator-owned Web files."""

import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from maraudarr.catalog import Catalog
from maraudarr.render import (
    render_compose,
    render_environment,
    render_homepage_services,
    write_stack,
)
from maraudarr.text import extract_service


class JellyfinClientsTests(unittest.TestCase):
    """Keep Vue optional and Web customization durable across regeneration."""

    def setUp(self) -> None:
        """Use the real catalog so service and preset contracts are tested together."""
        self.catalog = Catalog(Path(__file__).resolve().parents[1])

    def test_vue_is_optional_and_can_use_an_external_server(self) -> None:
        """Selecting a browser client must not silently deploy another media server."""
        service = self.catalog.services["jellyfin-vue"]
        self.assertEqual(service.requires, ())
        self.assertEqual(service.recommended, ("jellyfin",))

        for preset in self.catalog.presets.values():
            self.assertNotIn("jellyfin-vue", preset.services)
            if not preset.services:
                continue

            with self.subTest(preset=preset.id):
                plan = self.catalog.resolve(preset.id)
                self.assertNotIn("JELLYFIN_VUE_", render_environment(self.catalog, plan, None))
                self.assertNotIn("  jellyfin-vue:", render_compose(self.catalog, plan))

        external = self.catalog.resolve("custom", add={"jellyfin-vue", "homepage"})
        self.assertNotIn("jellyfin", external.service_ids)
        self.assertEqual(external.auto_added, ())
        removed = self.catalog.resolve("boudoirr", add={"jellyfin-vue"}, remove={"jellyfin"})
        self.assertIn("jellyfin-vue", removed.service_ids)
        self.assertNotIn("jellyfin", removed.service_ids)

    def test_vue_ports_and_homepage_follow_preset_offsets(self) -> None:
        """Browser links follow published ports while Vue retains internal port 80."""
        for preset, port in (("boudoirr", 18082), ("jellyfin", 28082), ("custom", 38082)):
            with self.subTest(preset=preset):
                plan = self.catalog.resolve(preset, add={"jellyfin-vue", "homepage"})
                environment = render_environment(self.catalog, plan, None, generate_secrets=False)
                compose = render_compose(self.catalog, plan)
                card = render_homepage_services(self.catalog, plan)
                self.assertIn(
                    f'JELLYFIN_VUE_WEBUI_PORT="${{JELLYFIN_VUE_WEBUI_PORT:-{port}}}"', environment
                )
                self.assertIn(f"http://host.or.ip:{port}", environment)
                self.assertIn("${JELLYFIN_VUE_WEBUI_PORT}:80", compose)
                self.assertIn("- Jellyfin Vue:", card)
                self.assertIn("HOMEPAGE_VAR_JELLYFIN_VUE_HREF", compose)

        without = self.catalog.resolve("boudoirr", add={"homepage"})
        self.assertNotIn("HOMEPAGE_VAR_JELLYFIN_VUE", render_compose(self.catalog, without))
        self.assertNotIn("- Jellyfin Vue:", render_homepage_services(self.catalog, without))
        client_only = self.catalog.resolve("custom", add={"jellyfin-vue"})
        self.assertNotIn(
            "HOMEPAGE_VAR_JELLYFIN_VUE", render_environment(self.catalog, client_only, None)
        )

    def test_vue_retains_its_image_user_and_independent_healthcheck(self) -> None:
        """The nginx-owned startup config requires its image identity and writable root."""
        plan = self.catalog.resolve("jellyfin", add={"jellyfin-vue"})
        client = extract_service(render_compose(self.catalog, plan), "jellyfin-vue")
        self.assertIn("<<: *default-container", client)
        self.assertNotIn("rootless-container", client)
        self.assertNotIn("read_only:", client)
        self.assertNotIn("depends_on:", client)
        self.assertNotIn("volumes:", client)
        self.assertIn("http://127.0.0.1:80/config.json", client)
        self.assertIn("- no-new-privileges:true", client)
        self.assertIn("JELLYFIN_VUE_DEFAULT_SERVERS", client)

    def test_web_mounts_are_read_only_and_reject_missing_host_sources(self) -> None:
        """Missing file binds must fail rather than shadow config.json with a directory."""
        plan = self.catalog.resolve("jellyfin")
        server = extract_service(render_compose(self.catalog, plan), "jellyfin")
        self.assertIn("source: ${JELLYFIN_WEB_CONFIG_PATH}", server)
        self.assertIn("target: /jellyfin/jellyfin-web/config.json", server)
        self.assertIn("source: ${JELLYFIN_WEB_CUSTOM_PATH}", server)
        self.assertIn("target: /jellyfin/jellyfin-web/custom", server)
        self.assertEqual(server.count("create_host_path: false"), 2)
        self.assertEqual(server.count("read_only: true"), 2)

        external = self.catalog.resolve("custom", add={"jellyfin-vue"})
        self.assertNotIn(
            "JELLYFIN_WEB_CONFIG_PATH", render_environment(self.catalog, external, None)
        )

    def test_regeneration_preserves_web_files_paths_and_application_state(self) -> None:
        """Adding/removing Vue must retain private settings, theme edits, and server data."""
        with tempfile.TemporaryDirectory() as temporary, patch("maraudarr.render.validate_compose"):
            output = Path(temporary)
            base = self.catalog.resolve("jellyfin")
            write_stack(self.catalog, base, output)
            web = output / "config/jellyfin/web"
            config = web / "config.json"
            theme = web / "custom/boudoirr.css"
            original = json.loads(config.read_text())
            self.assertIn("htmlVideoPlayer/plugin", original["plugins"])
            self.assertEqual(original["menuLinks"], [])

            # A private operator file, custom theme, and database all remain authoritative.
            edited = '{"menuLinks": [{"name": "Requests", "url": "https://example.test"}]}\n'
            config.write_text(edited)
            theme.write_text("/* Operator theme */\n")
            database = output / "config/jellyfin/config/library.db"
            database.write_bytes(b"operator database")
            env = output / ".env"
            env.write_text(
                env.read_text().replace(
                    'JELLYFIN_WEB_CONFIG_PATH="${JELLYFIN_WEB_CONFIG_PATH:-./config/jellyfin/web/config.json}"',
                    'JELLYFIN_WEB_CONFIG_PATH="/operator/web/config.json"',
                )
            )
            selected = self.catalog.resolve("jellyfin", add={"jellyfin-vue"})
            write_stack(self.catalog, selected, output)
            write_stack(self.catalog, base, output)

            self.assertEqual(config.read_text(), edited)
            self.assertEqual(theme.read_text(), "/* Operator theme */\n")
            self.assertEqual(database.read_bytes(), b"operator database")
            self.assertIn('JELLYFIN_WEB_CONFIG_PATH="/operator/web/config.json"', env.read_text())
            self.assertFalse((output / "config/jellyfin-vue").exists())

    def test_privacy_example_only_removes_external_web_players(self) -> None:
        """Offline configuration must retain playback and navigation capabilities."""
        web = self.catalog.root / "services/jellyfin/config/web"
        standard = json.loads((web / "config.json").read_text())
        privacy = json.loads((web / "privacy-config.json").read_text())
        removed = set(standard["plugins"]) - set(privacy["plugins"])
        self.assertEqual(removed, {"chromecastPlayer/plugin", "youtubePlayer/plugin"})
        self.assertIn("htmlVideoPlayer/plugin", privacy["plugins"])
        self.assertIn("syncPlay/plugin", privacy["plugins"])
        self.assertEqual(privacy["themes"], standard["themes"])

    def test_theme_collection_is_local_and_preserved(self) -> None:
        """New theme choices must retain their local base and survive operator edits."""
        names = ("oceanic", "noir-cinema", "aurora-glass", "rose-editorial", "emerald-lounge")
        with tempfile.TemporaryDirectory() as temporary, patch("maraudarr.render.validate_compose"):
            output = Path(temporary)
            plan = self.catalog.resolve("jellyfin")
            write_stack(self.catalog, plan, output)
            custom = output / "config/jellyfin/web/custom"

            for name in names:
                with self.subTest(theme=name):
                    source = (custom / f"{name}.css").read_text()
                    self.assertIn('@import url("theme-base.css");', source)
                    self.assertNotIn("https://", source)
                    self.assertNotIn("http://", source)
                    self.assertIn("--theme-accent-channel:", source)

            # The base is also operator-owned; regeneration must preserve both layers.
            (custom / "theme-base.css").write_text("/* Private base edits */\n")
            (custom / "aurora-glass.css").write_text("/* Private theme edits */\n")
            write_stack(self.catalog, plan, output)
            self.assertEqual((custom / "theme-base.css").read_text(), "/* Private base edits */\n")
            self.assertEqual(
                (custom / "aurora-glass.css").read_text(), "/* Private theme edits */\n"
            )
