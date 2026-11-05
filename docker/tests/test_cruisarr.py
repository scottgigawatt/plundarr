#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# test_cruisarr.py: Verify optional adult-media requests and durable generated settings.
#

"""Cover Cruisarr selection, secrets, host defaults, and conditional integrations."""

import io
import re
import tempfile
import unittest
from contextlib import redirect_stdout
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
from maraudarr.ui import RICH_AVAILABLE, UI


class CruisarrTests(unittest.TestCase):
    """Keep Cruisarr removable while preserving application state and recovery keys."""

    def setUp(self) -> None:
        """Load the real catalog independently for each integration scenario."""
        self.catalog = Catalog(Path(__file__).resolve().parents[1])

    def test_boudoirr_default_is_removable_and_other_presets_remain_independent(self) -> None:
        """Select Cruisarr for Boudoirr without forcing it or local integration servers."""
        whisparr = self.catalog.services["whisparr"]
        cruisarr = self.catalog.services["cruisarr"]

        self.assertIn("cruisarr", whisparr.recommended)
        self.assertEqual(cruisarr.recommended, ("whisparr", "jellyfin"))
        self.assertEqual(cruisarr.requires, ())
        self.assertIn("cruisarr", self.catalog.preset("boudoirr").defaults)
        self.assertNotIn("cruisarr", self.catalog.preset("boudoirr").core)
        self.assertIn("jellyfin", self.catalog.preset("boudoirr").defaults)
        self.assertNotIn("jellyfin", self.catalog.preset("boudoirr").core)
        self.assertIn("cruisarr", self.catalog.resolve("boudoirr").service_ids)
        self.assertEqual(cruisarr.named_volumes, {})

        for preset_id in self.catalog.presets:
            if preset_id in {"boudoirr", "custom"}:
                continue

            with self.subTest(preset=preset_id):
                plan = self.catalog.resolve(preset_id)
                self.assertNotIn("cruisarr", plan.service_ids)
                self.assertNotIn("CRUISARR_", render_environment(self.catalog, plan, None))

        selected = self.catalog.resolve("custom", selected={"cruisarr"})
        self.assertEqual(selected.service_ids, ("cruisarr",))
        self.assertEqual(selected.auto_added, ())
        removed = self.catalog.resolve("boudoirr", remove={"cruisarr"})
        self.assertNotIn("cruisarr", removed.service_ids)
        self.assertIn("jellyfin", removed.service_ids)

    def test_jellyfin_homepage_uses_internal_port_independently_of_host_offsets(self) -> None:
        """Keep widget requests inside Docker while browser links follow published ports."""
        for preset_id, host_port in (("boudoirr", 18096), ("jellyfin", 28096), ("custom", 38096)):
            with self.subTest(preset=preset_id):
                plan = self.catalog.resolve(preset_id, add={"jellyfin", "homepage"})
                compose = render_compose(self.catalog, plan)
                environment = render_environment(self.catalog, plan, None, generate_secrets=False)

                self.assertIn(
                    "HOMEPAGE_VAR_JELLYFIN_URL: ${HOMEPAGE_VAR_JELLYFIN_URL}:8096",
                    compose,
                )
                self.assertNotIn(
                    "${HOMEPAGE_VAR_JELLYFIN_URL}:${JELLYFIN_WEBUI_PORT}",
                    compose,
                )
                self.assertIn(
                    f'HOMEPAGE_VAR_JELLYFIN_HREF="${{HOMEPAGE_VAR_JELLYFIN_HREF:-http://host.or.ip:{host_port}}}"',
                    environment,
                )

    def test_jellyfin_removal_keeps_requests_and_omits_local_dashboard_settings(self) -> None:
        """Support an external Jellyfin server without leaving a stale local card."""
        plan = self.catalog.resolve("boudoirr", add={"homepage"}, remove={"jellyfin"})
        compose = render_compose(self.catalog, plan)
        environment = render_environment(self.catalog, plan, None, generate_secrets=False)
        homepage = render_homepage_services(self.catalog, plan)

        self.assertIn("cruisarr", plan.service_ids)
        self.assertNotIn("jellyfin", plan.service_ids)
        self.assertNotIn("  jellyfin:", compose)
        self.assertNotIn("JELLYFIN_", environment)
        self.assertNotIn("- Jellyfin:", homepage)
        self.assertIn("- Cruisarr:", homepage)

    def test_chart_uses_shared_identity_and_independent_internal_networking(self) -> None:
        """Keep writable data owned by the host user without assuming image tools."""
        plan = self.catalog.resolve("boudoirr", add={"cruisarr"})
        compose = render_compose(self.catalog, plan)
        service = extract_service(compose, "cruisarr")

        self.assertIn("user: ${DEFAULT_PUID}:${DEFAULT_PGID}", compose)
        self.assertIn("- *rootless-container", service)
        self.assertIn("image: ${CRUISARR_IMAGE}:${CRUISARR_TAG}", service)
        self.assertIn("${CRUISARR_CONFIG_PATH}:/data:rw", service)
        self.assertIn("CRUISARR_DATA_DIR: /data", service)
        self.assertIn("${CRUISARR_WEBUI_PORT}:6699", service)
        self.assertIn("- *exclude-from-watchtower-updates", service)
        self.assertIn("read_only: true", service)
        self.assertIn("- *security-hardening", service)
        self.assertIn("- ALL", compose)
        self.assertIn("no-new-privileges:true", compose)
        self.assertIn("- CMD\n        - node\n        - -e", service)
        self.assertIn("http://127.0.0.1:6699/api/status", service)
        self.assertNotIn("/api/health", service)
        self.assertNotIn("wget", service)
        self.assertNotIn("depends_on:", service)
        self.assertNotIn("network_mode:", service)
        self.assertNotIn("/downloads", service)
        self.assertNotIn("CRUISARR_IMAGE:-", service)
        self.assertNotIn("CRUISARR_TAG:-", service)

    def test_fresh_host_defaults_follow_each_presets_port_offset(self) -> None:
        """Offset published ports while keeping paths and private HTTP usable."""
        for preset_id, expected_port in (
            ("plundarr", 6699),
            ("boudoirr", 16699),
            ("custom", 36699),
        ):
            with self.subTest(preset=preset_id):
                plan = self.catalog.resolve(preset_id, add={"cruisarr"})
                environment = render_environment(self.catalog, plan, None, generate_secrets=False)

                self.assertIn(
                    f'CRUISARR_WEBUI_PORT="${{CRUISARR_WEBUI_PORT:-{expected_port}}}"',
                    environment,
                )
                self.assertIn(
                    'CRUISARR_CONFIG_PATH="${CRUISARR_CONFIG_PATH:-./config/cruisarr}"',
                    environment,
                )
                self.assertIn(
                    'CRUISARR_IMAGE="${CRUISARR_IMAGE:-ghcr.io/scottgigawatt/cruisarr}"',
                    environment,
                )
                self.assertIn('CRUISARR_TAG="${CRUISARR_TAG:-latest}"', environment)
                self.assertIn('CRUISARR_ALLOW_HTTP="${CRUISARR_ALLOW_HTTP:-1}"', environment)
                self.assertIn('CRUISARR_UPDATE_CHECK="${CRUISARR_UPDATE_CHECK:-0}"', environment)
                self.assertIn(
                    'CRUISARR_WHISPARR_LIBRARY_LIMIT_MIB="${CRUISARR_WHISPARR_LIBRARY_LIMIT_MIB:-64}"',
                    environment,
                )
                self.assertIn('CRUISARR_ORIGIN="${CRUISARR_ORIGIN:-}"', environment)
                self.assertIn(
                    'CRUISARR_DISCORD_DETAIL="${CRUISARR_DISCORD_DETAIL:-0}"', environment
                )
                self.assertIn("1 permits private-network HTTP", render_compose(self.catalog, plan))

    def test_generation_keeps_recovery_keys_and_operator_state(self) -> None:
        """Keep generated secrets private and stable across removal and reselection."""
        plan = self.catalog.resolve("boudoirr", add={"cruisarr", "homepage"})

        with tempfile.TemporaryDirectory() as temporary_directory:
            output = Path(temporary_directory)

            # Compose validation is covered by the real matrix; this fixture exercises atomic writes.
            with patch("maraudarr.render.validate_compose"):
                _, env_path, config_path = write_stack(self.catalog, plan, output)

            first_environment = env_path.read_text()
            secrets = re.findall(
                r'^CRUISARR_(?:SECRET_KEY|SETUP_SECRET)="([^"\n]+)"$',
                first_environment,
                re.MULTILINE,
            )
            self.assertEqual(len(secrets), 2)
            self.assertRegex(secrets[0], r"^[0-9a-f]{64}$")
            self.assertGreaterEqual(len(secrets[1]), 32)
            self.assertNotEqual(secrets[0], secrets[1])
            self.assertEqual(env_path.stat().st_mode & 0o777, 0o600)
            example = (output / "example.env").read_text()

            for secret in secrets:
                self.assertNotIn(secret, example)

            # Fresh deployments and the reference template use the private published image.
            for environment in (first_environment, example):
                self.assertIn(
                    'CRUISARR_IMAGE="${CRUISARR_IMAGE:-ghcr.io/scottgigawatt/cruisarr}"',
                    environment,
                )
                self.assertIn('CRUISARR_TAG="${CRUISARR_TAG:-latest}"', environment)

            self.assertIn('CRUISARR_SECRET_KEY="${CRUISARR_SECRET_KEY:-}"', example)
            self.assertIn('CRUISARR_SETUP_SECRET="${CRUISARR_SETUP_SECRET:-}"', example)

            # Use distinct operator values to catch accidental normalization or preset re-offsets.
            overrides = {
                'CRUISARR_IMAGE="${CRUISARR_IMAGE:-ghcr.io/scottgigawatt/cruisarr}"': 'CRUISARR_IMAGE="ghcr.io/example/cruisarr"',
                'CRUISARR_TAG="${CRUISARR_TAG:-latest}"': 'CRUISARR_TAG="edge"',
                'CRUISARR_WEBUI_PORT="${CRUISARR_WEBUI_PORT:-16699}"': 'CRUISARR_WEBUI_PORT="17699"',
                'CRUISARR_ORIGIN="${CRUISARR_ORIGIN:-}"': 'CRUISARR_ORIGIN="https://cruisarr.example.com"',
                'CRUISARR_ALLOW_HTTP="${CRUISARR_ALLOW_HTTP:-1}"': 'CRUISARR_ALLOW_HTTP="0"',
                'HOMEPAGE_VAR_CRUISARR_HREF="${HOMEPAGE_VAR_CRUISARR_HREF:-http://host.or.ip:${CRUISARR_WEBUI_PORT}}"': 'HOMEPAGE_VAR_CRUISARR_HREF="https://requests.example.com"',
            }
            edited = first_environment

            for original, replacement in overrides.items():
                self.assertIn(original, edited)
                edited = edited.replace(original, replacement)

            env_path.write_text(edited)
            database = config_path / "cruisarr/cruisarr.sqlite"
            database.write_bytes(b"operator-owned database fixture")
            dashboard = config_path / "homepage/settings.yaml"
            dashboard.write_text("title: Operator dashboard\n")

            # Temporarily deselecting a service must not discard the key needed for its database.
            with patch("maraudarr.render.validate_compose"):
                write_stack(
                    self.catalog, self.catalog.resolve("boudoirr", remove={"cruisarr"}), output
                )
                write_stack(self.catalog, plan, output)

            regenerated = env_path.read_text()

            for secret in secrets:
                self.assertIn(secret, regenerated)

            for replacement in overrides.values():
                self.assertIn(replacement, regenerated)

            # The reference template stays source-defined even when the deployment uses an override.
            regenerated_example = (output / "example.env").read_text()
            self.assertIn(
                'CRUISARR_IMAGE="${CRUISARR_IMAGE:-ghcr.io/scottgigawatt/cruisarr}"',
                regenerated_example,
            )
            self.assertIn('CRUISARR_TAG="${CRUISARR_TAG:-latest}"', regenerated_example)

            self.assertEqual(database.read_bytes(), b"operator-owned database fixture")
            self.assertEqual(dashboard.read_text(), "title: Operator dashboard\n")
            self.assertTrue((config_path / "cruisarr/README.md").is_file())
            self.assertEqual(env_path.stat().st_mode & 0o777, 0o600)

    def test_existing_tag_is_preserved_with_repository_defaults(self) -> None:
        """Preserve a selected immutable image tag when rendering repository defaults."""
        plan = self.catalog.resolve("boudoirr")

        with tempfile.TemporaryDirectory() as temporary_directory:
            env_path = Path(temporary_directory) / ".env"
            env_path.write_text('CRUISARR_TAG="sha-0123456789abcdef0123456789abcdef01234567"\n')
            environment = render_environment(self.catalog, plan, env_path, generate_secrets=False)

        self.assertIn(
            'CRUISARR_IMAGE="${CRUISARR_IMAGE:-ghcr.io/scottgigawatt/cruisarr}"', environment
        )
        self.assertIn('CRUISARR_TAG="sha-0123456789abcdef0123456789abcdef01234567"', environment)

    def test_existing_empty_secrets_are_preserved_without_silent_rotation(self) -> None:
        """Respect existing assignments even when an operator cleared a value."""
        plan = self.catalog.resolve("custom", selected={"cruisarr"})

        with tempfile.TemporaryDirectory() as temporary_directory:
            env_path = Path(temporary_directory) / ".env"
            existing = 'CRUISARR_SECRET_KEY=""\nCRUISARR_SETUP_SECRET=""\n'
            env_path.write_text(existing)
            generated = render_environment(self.catalog, plan, env_path)

        for assignment in existing.splitlines():
            self.assertIn(assignment, generated)

    def test_homepage_link_and_variables_follow_service_selection(self) -> None:
        """Keep browser links tied to host ports without inventing a widget API."""
        for selected in ({"homepage"}, {"cruisarr"}, {"homepage", "cruisarr"}):
            with self.subTest(selected=selected):
                plan = self.catalog.resolve("custom", selected=selected)
                compose = render_compose(self.catalog, plan)
                environment = render_environment(self.catalog, plan, None)
                has_link = selected == {"homepage", "cruisarr"}

                self.assertEqual("HOMEPAGE_VAR_CRUISARR_HREF" in compose, has_link)
                self.assertEqual("HOMEPAGE_VAR_CRUISARR_HREF" in environment, has_link)

                if "homepage" in selected:
                    homepage = render_homepage_services(self.catalog, plan)
                    self.assertEqual("- Cruisarr:" in homepage, has_link)

                    if has_link:
                        self.assertIn("{{HOMEPAGE_VAR_CRUISARR_HREF}}", homepage)
                        self.assertNotIn("widget:", homepage)

        plan = self.catalog.resolve("boudoirr", add={"cruisarr", "homepage"})
        environment = render_environment(self.catalog, plan, None, generate_secrets=False)
        self.assertIn(
            'HOMEPAGE_VAR_CRUISARR_HREF="${HOMEPAGE_VAR_CRUISARR_HREF:-http://host.or.ip:${CRUISARR_WEBUI_PORT}}"',
            environment,
        )

    def test_ui_explains_optional_recommendations_and_selected_setup(self) -> None:
        """Show the recommended companion without revealing generated credentials."""
        output = io.StringIO()

        with redirect_stdout(output):
            UI(plain=True).show_plan(self.catalog.resolve("boudoirr", remove={"cruisarr"}))

        self.assertIn("Recommended integrations (optional): cruisarr", output.getvalue())
        output = io.StringIO()
        plan = self.catalog.resolve("boudoirr", remove={"jellyfin"})

        with redirect_stdout(output):
            ui = UI(plain=True)
            ui.show_plan(plan)
            ui.success(plan, "compose", "environment", "config")

        listing = output.getvalue()
        self.assertIn("Recommended integrations (optional): jellyfin", listing)
        self.assertIn("Authenticate the deployment host to ghcr.io", listing)
        self.assertIn("read CRUISARR_SETUP_SECRET locally", listing)
        self.assertIn("Complete Cruisarr setup with Jellyfin", listing)

    @unittest.skipUnless(RICH_AVAILABLE, "Questionary and Rich are not installed")
    def test_interactive_companion_checkboxes_start_checked_and_accept_deselection(self) -> None:
        """Verify the actual checkbox choice is checked but remains removable."""
        from questionary import Choice

        ui = UI()
        ui.plain = False

        for service_id in ("cruisarr", "jellyfin"):
            with (
                self.subTest(service=service_id),
                patch("maraudarr.ui.sys.stdin.isatty", return_value=True),
                patch("maraudarr.ui.prompts.Choice", wraps=Choice) as choice_factory,
                patch("maraudarr.ui.prompts.checkbox") as checkbox,
            ):
                checkbox.return_value.ask.return_value = []
                service = self.catalog.services[service_id]
                selected = ui.choose_services(
                    [service],
                    set(self.catalog.preset("boudoirr").defaults),
                )

            choice_factory.assert_called_once_with(service.title, service_id, checked=True)
            self.assertEqual(selected, set())

    @unittest.skipUnless(RICH_AVAILABLE, "Rich is not installed")
    def test_styled_ui_also_shows_optional_recommendations(self) -> None:
        """Keep optional integration guidance visible in the container's rich UI."""
        from rich.console import Console

        output = io.StringIO()
        ui = UI()
        ui.console = Console(file=output, color_system=None, width=120)
        ui.show_plan(self.catalog.resolve("boudoirr", remove={"cruisarr"}))

        self.assertIn("Recommended integrations (optional): cruisarr", output.getvalue())


if __name__ == "__main__":
    unittest.main()
