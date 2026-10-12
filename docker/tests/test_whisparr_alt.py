#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# test_whisparr_alt.py: Verify an opt-in second Whisparr with independent state.
#

"""Exercise selection, provider-neutral defaults, dashboard links, and safe regeneration."""

import io
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

from maraudarr.catalog import Catalog
from maraudarr.cli import main
from maraudarr.render import (
    render_compose,
    render_environment,
    render_homepage_services,
    write_stack,
)
from maraudarr.text import extract_service
from maraudarr.ui import RICH_AVAILABLE, UI


class WhisparrAltTests(unittest.TestCase):
    """Keep the second instance optional and isolated from primary application state."""

    def setUp(self) -> None:
        """Load the real service catalog for each generated-stack scenario."""
        self.catalog = Catalog(Path(__file__).resolve().parents[1])

    def test_every_preset_starts_without_alt(self) -> None:
        """Avoid adding a second automation database through defaults or dependencies."""
        for preset_id in self.catalog.presets:
            with self.subTest(preset=preset_id):
                plan = self.catalog.resolve(
                    preset_id, add={"homepage"} if preset_id == "custom" else set()
                )

                self.assertNotIn("whisparr-alt", plan.service_ids)
                self.assertNotIn("WHISPARR_ALT_", render_compose(self.catalog, plan))
                self.assertNotIn(
                    "WHISPARR_ALT_",
                    render_environment(self.catalog, plan, None, generate_secrets=False),
                )

        # Custom selection must not introduce the primary instance or a local media server.
        plan = self.catalog.resolve("custom", selected={"whisparr-alt"})
        self.assertEqual(plan.service_ids, ("flaresolverr", "prowlarr", "whisparr-alt"))
        self.assertEqual(self.catalog.services["whisparr-alt"].named_volumes, {})

    def test_chart_keeps_identity_mounts_and_health_independent(self) -> None:
        """Reuse arr hardening while keeping two database and port identities separate."""
        default = self.catalog.resolve("boudoirr")
        plan = self.catalog.resolve("boudoirr", add={"whisparr-alt"})
        compose = render_compose(self.catalog, plan)
        alt = extract_service(compose, "whisparr-alt")

        self.assertEqual(
            extract_service(compose, "whisparr"),
            extract_service(render_compose(self.catalog, default), "whisparr"),
        )
        self.assertIn("<<: *arr-stack-container", alt)
        self.assertIn("image: ghcr.io/hotio/whisparr:${WHISPARR_ALT_TAG}", alt)
        self.assertIn("${COMPOSE_PROJECT_NAME}-whisparr-alt-${WHISPARR_ALT_TAG}", alt)
        self.assertIn("hostname: whisparr-alt", alt)
        self.assertIn("${WHISPARR_ALT_WEBUI_PORT}:6969", alt)
        self.assertIn("${WHISPARR_ALT_CONFIG_PATH}:/config:rw", alt)
        self.assertIn("${WHISPARR_ALT_DATA_PATH}:/data:rw", alt)
        self.assertIn("${HOST_DOWNLOADS_PATH}:/downloads:rw", alt)
        self.assertIn("http://127.0.0.1:6969/ping", alt)
        self.assertNotIn("depends_on:", alt)
        self.assertNotIn("WHISPARR_TAG", alt)
        self.assertNotIn("WHISPARR_ALT_TAG:-", alt)

    def test_environment_follows_preset_ports_and_media_roots(self) -> None:
        """Offset the published port without changing the internal port or choosing a provider."""
        for preset_id, port, media_root in (
            ("plundarr", 6970, "/volume1/plex"),
            ("boudoirr", 16970, "/volume1/jellyfin"),
            ("custom", 36970, "/volume1/plex"),
        ):
            with self.subTest(preset=preset_id):
                plan = self.catalog.resolve(preset_id, add={"whisparr-alt"})
                environment = render_environment(self.catalog, plan, None, generate_secrets=False)

                self.assertIn('WHISPARR_ALT_TAG="${WHISPARR_ALT_TAG:-v3}"', environment)
                self.assertIn(
                    f'WHISPARR_ALT_WEBUI_PORT="${{WHISPARR_ALT_WEBUI_PORT:-{port}}}"',
                    environment,
                )
                self.assertIn(
                    'WHISPARR_ALT_CONFIG_PATH="${WHISPARR_ALT_CONFIG_PATH:-./config/whisparr-alt}"',
                    environment,
                )
                self.assertIn(
                    f'WHISPARR_ALT_DATA_PATH="${{WHISPARR_ALT_DATA_PATH:-{media_root}/movies-alt}}"',
                    environment,
                )
                self.assertNotIn("METADATA_SOURCE", environment)

    def test_homepage_card_and_environment_are_conditional(self) -> None:
        """Show Alt only when selected and use its published port for the browser link."""
        for services in ({"homepage"}, {"whisparr-alt"}, {"homepage", "whisparr-alt"}):
            with self.subTest(services=services):
                plan = self.catalog.resolve("custom", selected=services)
                compose = render_compose(self.catalog, plan)
                environment = render_environment(self.catalog, plan, None, generate_secrets=False)
                has_card = services == {"homepage", "whisparr-alt"}

                self.assertEqual("HOMEPAGE_VAR_WHISPARR_ALT_HREF" in compose, has_card)
                self.assertEqual("HOMEPAGE_VAR_WHISPARR_ALT_HREF" in environment, has_card)

                if "homepage" in services:
                    homepage = render_homepage_services(self.catalog, plan)
                    self.assertEqual("- Whisparr Alt:" in homepage, has_card)

                    if has_card:
                        self.assertIn("{{HOMEPAGE_VAR_WHISPARR_ALT_CONTAINER}}", homepage)
                        self.assertIn(
                            "HOMEPAGE_VAR_WHISPARR_ALT_CONTAINER: ${COMPOSE_PROJECT_NAME}-whisparr-alt-${WHISPARR_ALT_TAG}",
                            compose,
                        )
                        self.assertIn(
                            'HOMEPAGE_VAR_WHISPARR_ALT_HREF="${HOMEPAGE_VAR_WHISPARR_ALT_HREF:-http://host.or.ip:${WHISPARR_ALT_WEBUI_PORT}}"',
                            environment,
                        )

    def test_regeneration_preserves_overrides_and_both_databases(self) -> None:
        """Survive removal and reselection without losing either application's configuration."""
        plan = self.catalog.resolve("boudoirr", add={"whisparr-alt", "homepage"})

        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary)

            # Compose matrix tests cover real validation; this fixture isolates state preservation.
            with patch("maraudarr.render.validate_compose"):
                _, env_path, config_path = write_stack(self.catalog, plan, output)

            for environment in (env_path.read_text(), (output / "example.env").read_text()):
                self.assertIn(
                    'WHISPARR_ALT_WEBUI_PORT="${WHISPARR_ALT_WEBUI_PORT:-16970}"', environment
                )
                self.assertIn('WHISPARR_ALT_TAG="${WHISPARR_ALT_TAG:-v3}"', environment)

            # Synthetic operator values differ from defaults to catch accidental path or port resets.
            overrides = (
                'WHISPARR_ALT_TAG="v3-test"',
                'WHISPARR_ALT_WEBUI_PORT="17970"',
                'WHISPARR_ALT_CONFIG_PATH="./config/alternate"',
                'WHISPARR_ALT_DATA_PATH="/srv/library/alternate"',
                'HOMEPAGE_VAR_WHISPARR_ALT_HREF="https://alternate.example.com"',
            )
            env_path.write_text("\n".join(overrides) + '\nWHISPARR_WEBUI_PORT="17969"\n')
            primary_database = config_path / "whisparr/whisparr.db"
            alternate_database = config_path / "whisparr-alt/whisparr.db"
            alternate_config = config_path / "whisparr-alt/config.xml"
            primary_database.write_bytes(b"primary operator database fixture")
            alternate_database.write_bytes(b"alternate operator database fixture")
            alternate_config.write_text("<Config><ApiKey>synthetic-fixture</ApiKey></Config>\n")

            with patch("maraudarr.render.validate_compose"):
                removed = self.catalog.resolve("boudoirr", add={"homepage"})
                write_stack(self.catalog, removed, output)
                self.assertNotIn("  whisparr-alt:", (output / "docker-compose.yml").read_text())
                self.assertNotIn(
                    "- Whisparr Alt:", (config_path / "homepage/services.yaml").read_text()
                )
                write_stack(self.catalog, plan, output)

            # Existing assignments and application-owned files survive both regeneration operations.
            regenerated = env_path.read_text()

            for assignment in overrides:
                self.assertIn(assignment, regenerated)

            self.assertIn('WHISPARR_WEBUI_PORT="17969"', regenerated)
            self.assertEqual(primary_database.read_bytes(), b"primary operator database fixture")
            self.assertEqual(
                alternate_database.read_bytes(), b"alternate operator database fixture"
            )
            self.assertIn("synthetic-fixture", alternate_config.read_text())
            self.assertIn("- Whisparr Alt:", (config_path / "homepage/services.yaml").read_text())
            self.assertIn(
                'WHISPARR_ALT_WEBUI_PORT="${WHISPARR_ALT_WEBUI_PORT:-16970}"',
                (output / "example.env").read_text(),
            )

    def test_cli_add_selects_alt_and_reports_setup_boundaries(self) -> None:
        """Exercise build flags through the public CLI and report instance-specific setup."""
        with tempfile.TemporaryDirectory() as temporary:
            output = io.StringIO()

            with redirect_stdout(output), patch("maraudarr.render.validate_compose"):
                status = main(
                    [
                        "--plain",
                        "build",
                        "--preset",
                        "boudoirr",
                        "--add",
                        "whisparr-alt",
                        "--output",
                        temporary,
                    ]
                )

            self.assertEqual(status, 0)
            self.assertIn("  whisparr-alt:", (Path(temporary) / "docker-compose.yml").read_text())
            self.assertIn(
                "Keep Whisparr Alt's config and managed root folders separate.", output.getvalue()
            )
            self.assertIn("distinct download category", output.getvalue())

    @unittest.skipUnless(RICH_AVAILABLE, "Questionary and Rich are not installed")
    def test_interactive_choice_starts_unchecked_and_can_be_selected(self) -> None:
        """Exercise the actual picker choice without quietly making Alt a preset default."""
        from questionary import Choice

        ui = UI()
        ui.plain = False
        service = self.catalog.services["whisparr-alt"]
        preset = self.catalog.preset("boudoirr")

        with (
            patch("maraudarr.ui.sys.stdin.isatty", return_value=True),
            patch("maraudarr.ui.prompts.Choice", wraps=Choice) as choice_factory,
            patch("maraudarr.ui.prompts.checkbox") as checkbox,
        ):
            checkbox.return_value.ask.return_value = ["whisparr-alt"]
            chosen = ui.choose_services([service], set(preset.core + preset.defaults))

        choice_factory.assert_called_once_with(service.title, service.id, checked=False)
        self.assertEqual(chosen, {"whisparr-alt"})


if __name__ == "__main__":
    unittest.main()
