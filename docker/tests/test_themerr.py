#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# test_themerr.py: Verify shared media-server themes and durable credential encryption.
#

"""Cover required Duplex selection, external connections, and private key preservation."""

import base64
import tempfile
import unittest
from pathlib import Path

from maraudarr.catalog import Catalog
from maraudarr.render import (
    RenderError,
    render_compose,
    render_environment,
    render_homepage_services,
    write_stack,
)


class ThemerrTests(unittest.TestCase):
    """Keep one instance independent of local media servers and existing state."""

    def setUp(self) -> None:
        """Load the actual service catalog for every scenario."""
        self.catalog = Catalog(Path(__file__).resolve().parents[1])

    def test_duplex_core_and_external_servers(self) -> None:
        """Required theme management must not force local Plex or Jellyfin deployments."""
        plan = self.catalog.resolve("duplex", remove={"themerr"})
        self.assertIn("themerr", plan.service_ids)
        self.assertIn("themerr", plan.preset.core)
        self.assertEqual(self.catalog.services["themerr"].requires, ())
        custom = self.catalog.resolve("custom", selected={"themerr"})
        self.assertEqual(custom.service_ids, ("themerr",))
        self.assertNotIn("themerr", self.catalog.resolve("jellyfin").service_ids)

    def test_ports_and_conditional_homepage(self) -> None:
        """Publish both purposes with preset offsets and only show selected links."""
        for preset, port in (("duplex", 9494), ("jellyfin", 29494), ("custom", 39494)):
            with self.subTest(preset=preset):
                plan = self.catalog.resolve(preset, add={"themerr", "homepage"})
                environment = render_environment(self.catalog, plan, None)
                self.assertIn(f'THEMERR_WEBUI_PORT="${{THEMERR_WEBUI_PORT:-{port}}}"', environment)
                self.assertIn(
                    f'THEMERR_CONNECTOR_PORT="${{THEMERR_CONNECTOR_PORT:-{port + 1}}}"', environment
                )
                self.assertIn("https://host.or.ip:", environment)
                cards = render_homepage_services(self.catalog, plan)
                self.assertIn("- Themerr:", cards)
                self.assertNotIn("widget:", cards.split("- Themerr:", 1)[1].split("\n    - ", 1)[0])
        absent = self.catalog.resolve("custom", selected={"homepage"})
        self.assertNotIn("THEMERR", render_environment(self.catalog, absent, None))
        self.assertNotIn("- Themerr:", render_homepage_services(self.catalog, absent))

    def test_runtime_boundary(self) -> None:
        """Use direct host identity and read-only key without privileged integration mounts."""
        compose = render_compose(self.catalog, self.catalog.resolve("custom", selected={"themerr"}))
        self.assertIn("<<: *rootless-container", compose)
        self.assertIn("HOME: /tmp", compose)
        self.assertIn("THEMERR_TOKEN_KEY_FILE: /run/secrets/themerr_token_key", compose)
        self.assertIn("source: ${THEMERR_TOKEN_KEY_PATH}", compose)
        self.assertIn("read_only: true", compose)
        self.assertIn("create_host_path: false", compose)
        self.assertNotIn("docker.sock", compose)
        self.assertNotIn("depends_on:", compose)

    def test_key_and_settings_survive_regeneration_and_reselection(self) -> None:
        """Preserve exactly the key encrypting credentials and the operator's runtime settings."""
        plan = self.catalog.resolve("custom", selected={"themerr"})
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary)
            write_stack(self.catalog, plan, output)
            key = output / "config/secrets/themerr-tokens.key"
            original = key.read_bytes()
            self.assertEqual(len(base64.urlsafe_b64decode(original.strip())), 32)
            self.assertEqual(key.stat().st_mode & 0o777, 0o600)
            settings = output / "config/themerr/config.ini"
            self.assertIn("[Themerr]", settings.read_text())
            self.assertIn("BOOL_REMOVE_UNUSED_THEMES = False", settings.read_text())
            settings.write_text("[Themerr]\nBOOL_REMOVE_UNUSED_THEMES = True\n")
            write_stack(self.catalog, self.catalog.resolve("custom", selected={"homepage"}), output)
            write_stack(self.catalog, plan, output)
            self.assertEqual(key.read_bytes(), original)
            self.assertEqual(settings.read_text(), "[Themerr]\nBOOL_REMOVE_UNUSED_THEMES = True\n")

    def test_missing_key_refuses_silent_rekey(self) -> None:
        """Recover the original key instead of stranding stored encrypted credentials."""
        plan = self.catalog.resolve("custom", selected={"themerr"})
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary)
            write_stack(self.catalog, plan, output)
            key = output / "config/secrets/themerr-tokens.key"
            key.unlink()
            before = (output / "docker-compose.yml").read_bytes()
            with self.assertRaisesRegex(RenderError, "Restore"):
                write_stack(self.catalog, plan, output)
            self.assertFalse(key.exists())
            self.assertEqual((output / "docker-compose.yml").read_bytes(), before)

    def test_external_paths_stay_operator_owned(self) -> None:
        """Do not evaluate external assignments or require an unused managed key."""
        plan = self.catalog.resolve("custom", selected={"themerr"})
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary)
            output.joinpath(".env").write_text(
                'THEMERR_CONFIG_PATH="/operator/themerr"\nTHEMERR_TOKEN_KEY_PATH="/operator/key"\n'
            )
            write_stack(self.catalog, plan, output)
            self.assertFalse((output / "config/secrets/themerr-tokens.key").exists())
            self.assertIn(
                'THEMERR_TOKEN_KEY_PATH="/operator/key"', output.joinpath(".env").read_text()
            )

    def test_key_generation_does_not_follow_an_external_directory_link(self) -> None:
        """An operator directory link must not turn generation into an external secret write."""
        plan = self.catalog.resolve("custom", selected={"themerr"})
        with tempfile.TemporaryDirectory() as temporary, tempfile.TemporaryDirectory() as external:
            output = Path(temporary)
            output.joinpath("config").mkdir()
            output.joinpath("config/secrets").symlink_to(external, target_is_directory=True)
            with self.assertRaisesRegex(RenderError, "escapes"):
                write_stack(self.catalog, plan, output)
            self.assertEqual(list(Path(external).iterdir()), [])

    def test_invalid_managed_key_is_preserved_and_reported(self) -> None:
        """A broken key cannot be silently replaced with unrelated encryption material."""
        plan = self.catalog.resolve("custom", selected={"themerr"})
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary)
            write_stack(self.catalog, plan, output)
            key = output / "config/secrets/themerr-tokens.key"
            key.write_bytes(b"invalid-existing-key")
            with self.assertRaisesRegex(RenderError, "invalid"):
                write_stack(self.catalog, plan, output)
            self.assertEqual(key.read_bytes(), b"invalid-existing-key")
