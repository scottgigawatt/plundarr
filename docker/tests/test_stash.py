#
# Copyright 2025-2026 Scott Gigawatt
#
# SPDX-License-Identifier: Apache-2.0
#
# test_stash.py: Verify removable Stash selection and shared-media storage boundaries.
#

"""Cover Stash defaults, conditional integrations, and durable operator state."""

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


class StashTests(unittest.TestCase):
    """Keep cataloging independent from download management and playback servers."""

    def setUp(self) -> None:
        """Load the production catalog for every service-selection scenario."""
        self.catalog = Catalog(Path(__file__).resolve().parents[1])

    def test_default_is_removable_without_pulling_in_companions(self) -> None:
        """Select Stash only for Boudoirr by default and never require another server."""
        service = self.catalog.services["stash"]
        self.assertIn("stash", self.catalog.preset("boudoirr").defaults)
        self.assertNotIn("stash", self.catalog.preset("boudoirr").core)
        self.assertEqual(service.requires, ())
        self.assertEqual(service.named_volumes, {})
        self.assertEqual(self.catalog.resolve("custom", selected={"stash"}).service_ids, ("stash",))

        for preset in self.catalog.presets:
            if preset in {"boudoirr", "custom"}:
                continue

            with self.subTest(preset=preset):
                plan = self.catalog.resolve(preset)
                self.assertNotIn("stash", plan.service_ids)
                self.assertNotIn("STASH_", render_environment(self.catalog, plan, None))

        removed = self.catalog.resolve("boudoirr", remove={"stash"})
        self.assertNotIn("stash", removed.service_ids)
        self.assertTrue({"cruisarr", "jellyfin"}.issubset(removed.service_ids))

    def test_writable_children_keep_other_media_read_only_and_state_separate(self) -> None:
        """Allow creator organization and recycling without writes to Whisparr libraries."""
        plan = self.catalog.resolve("boudoirr")
        service = extract_service(render_compose(self.catalog, plan), "stash")
        self.assertIn("${STASH_DATA_PATH}:/data:ro", service)
        self.assertNotIn("/data:rw", service)
        self.assertIn("source: ${STASH_CREATORS_PATH}", service)
        self.assertIn("target: /data/scenes/creators", service)
        self.assertIn("${STASH_RECYCLE_PATH}:/data/recycle/stash:rw", service)
        self.assertIn("read_only: false", service)
        self.assertIn("create_host_path: false", service)
        self.assertNotIn("/downloads", service)
        self.assertNotIn("network_mode:", service)
        self.assertNotIn("depends_on:", service)
        self.assertNotIn("profiles:", service)
        self.assertIn("*rootless-container", service)
        self.assertIn("*security-hardening", service)
        self.assertIn("STASH_CONFIG_FILE: /config/config.yml", service)
        self.assertIn("USER: stash", service)
        self.assertNotIn("/root/", service)
        self.assertIn("http://127.0.0.1:9999/healthz", service)

        for name in ("config", "metadata", "cache", "blobs", "generated"):
            with self.subTest(storage=name):
                self.assertIn(f"${{STASH_{name.upper()}_PATH}}:/{name}:rw", service)

    def test_preset_paths_ports_and_homepage_follow_selection(self) -> None:
        """Keep browser ports offset while Jellyfin and Stash share the same /data root."""
        for preset, port, media in (
            ("plundarr", 9999, "/volume1/plex"),
            ("boudoirr", 19999, "/volume1/jellyfin"),
            ("jellyfin", 29999, "/volume1/jellyfin"),
            ("custom", 39999, "/volume1/plex"),
        ):
            with self.subTest(preset=preset):
                plan = self.catalog.resolve(preset, add={"stash", "jellyfin", "homepage"})
                environment = render_environment(self.catalog, plan, None, generate_secrets=False)
                compose = render_compose(self.catalog, plan)
                homepage = render_homepage_services(self.catalog, plan)
                self.assertIn(f'STASH_WEBUI_PORT="${{STASH_WEBUI_PORT:-{port}}}"', environment)
                self.assertIn(f'STASH_DATA_PATH="${{STASH_DATA_PATH:-{media}}}"', environment)
                self.assertIn(
                    f'STASH_CREATORS_PATH="${{STASH_CREATORS_PATH:-{media}/scenes/creators}}"',
                    environment,
                )
                self.assertIn(
                    f'STASH_RECYCLE_PATH="${{STASH_RECYCLE_PATH:-{media}/recycle/stash}}"',
                    environment,
                )
                self.assertIn(f'JELLYFIN_DATA_PATH="${{JELLYFIN_DATA_PATH:-{media}}}"', environment)
                self.assertIn("${STASH_WEBUI_PORT}:9999", compose)
                self.assertIn("- Stash:", homepage)
                self.assertIn("HOMEPAGE_VAR_STASH_HREF", compose)
                self.assertIn("${STASH_WEBUI_PORT}", environment)

        for selected in ({"homepage"}, {"stash"}):
            plan = self.catalog.resolve("custom", selected=selected)
            self.assertNotIn("HOMEPAGE_VAR_STASH_", render_compose(self.catalog, plan))
            self.assertNotIn("HOMEPAGE_VAR_STASH_", render_environment(self.catalog, plan, None))
            if "stash" not in selected:
                self.assertNotIn("- Stash:", render_homepage_services(self.catalog, plan))

        removed = self.catalog.resolve("boudoirr", add={"homepage"}, remove={"stash"})
        self.assertNotIn("- Stash:", render_homepage_services(self.catalog, removed))
        self.assertNotIn("HOMEPAGE_VAR_STASH_", render_compose(self.catalog, removed))

    def test_regeneration_and_deselection_preserve_settings_and_state(self) -> None:
        """Keep database, artwork, and settings intact through a remove/re-add cycle."""
        plan = self.catalog.resolve("boudoirr")

        with tempfile.TemporaryDirectory() as temporary_directory:
            output = Path(temporary_directory)

            # Stub only Compose invocation; exercise the real environment and config writers.
            with patch("maraudarr.render.validate_compose"):
                _, env_path, config_path = write_stack(self.catalog, plan, output)

            overrides = {
                "STASH_TAG": "v0.32.0",
                "STASH_WEBUI_PORT": "20999",
                "STASH_DATA_PATH": "/srv/shared/library",
                "STASH_CREATORS_PATH": "/srv/shared/library/scenes/creators",
                "STASH_RECYCLE_PATH": "/srv/shared/library/recycle/stash",
                "STASH_GENERATED_PATH": "/srv/stash/previews",
            }
            environment = env_path.read_text()

            for name, value in overrides.items():
                lines = environment.splitlines()
                environment = (
                    "\n".join(
                        f'{name}="{value}"' if line.startswith(f"{name}=") else line
                        for line in lines
                    )
                    + "\n"
                )

            env_path.write_text(environment)
            fixtures = {
                "config/config.yml": b"operator-owned settings\n",
                "config/stash-go.sqlite": b"operator-owned database",
                "blobs/cover.jpg": b"operator-owned artwork",
                "metadata/export.json": b"operator-owned export",
                "cache/cache-fixture": b"cache fixture",
                "generated/preview.mp4": b"preview fixture",
            }

            for relative, content in fixtures.items():
                path = config_path / "stash" / relative
                self.assertTrue(path.parent.is_dir())
                path.write_bytes(content)

            with patch("maraudarr.render.validate_compose"):
                write_stack(
                    self.catalog, self.catalog.resolve("boudoirr", remove={"stash"}), output
                )
                write_stack(self.catalog, plan, output)

            for name, value in overrides.items():
                self.assertIn(f'{name}="{value}"', env_path.read_text())

            for relative, content in fixtures.items():
                self.assertEqual((config_path / "stash" / relative).read_bytes(), content)

            reference = (output / "example.env").read_text()
            self.assertIn('STASH_TAG="${STASH_TAG:-latest}"', reference)
            self.assertNotIn("/srv/shared/library", reference)
            self.assertEqual(env_path.stat().st_mode & 0o777, 0o600)

    def test_unselected_service_creates_no_config_tree(self) -> None:
        """Only seed Stash directories for a selected service on a fresh deployment."""
        plan = self.catalog.resolve("boudoirr", remove={"stash"})

        with tempfile.TemporaryDirectory() as temporary_directory:
            output = Path(temporary_directory)

            with patch("maraudarr.render.validate_compose"):
                write_stack(self.catalog, plan, output)

            self.assertFalse((output / "config/stash").exists())
