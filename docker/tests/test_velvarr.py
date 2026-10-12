#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# test_velvarr.py: Verify optional adult-media requests and durable generated settings.
#

"""Cover Velvarr selection, secrets, host defaults, and conditional integrations."""

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


class VelvarrTests(unittest.TestCase):
    """Keep Velvarr removable while preserving application state and recovery keys."""

    def setUp(self) -> None:
        """Load the real catalog independently for each integration scenario."""
        self.catalog = Catalog(Path(__file__).resolve().parents[1])

    def test_boudoirr_default_is_removable_and_other_presets_remain_independent(self) -> None:
        """Select Velvarr for Boudoirr without forcing it or local integration servers."""
        whisparr = self.catalog.services["whisparr"]
        velvarr = self.catalog.services["velvarr"]

        self.assertIn("velvarr", whisparr.recommended)
        self.assertEqual(velvarr.recommended, ("whisparr", "jellyfin"))
        self.assertEqual(velvarr.requires, ())
        self.assertIn("velvarr", self.catalog.preset("boudoirr").defaults)
        self.assertNotIn("velvarr", self.catalog.preset("boudoirr").core)
        self.assertIn("jellyfin", self.catalog.preset("boudoirr").defaults)
        self.assertNotIn("jellyfin", self.catalog.preset("boudoirr").core)
        self.assertIn("velvarr", self.catalog.resolve("boudoirr").service_ids)
        self.assertEqual(velvarr.named_volumes, {})

        for preset_id in self.catalog.presets:
            if preset_id in {"boudoirr", "custom"}:
                continue

            with self.subTest(preset=preset_id):
                plan = self.catalog.resolve(preset_id)
                self.assertNotIn("velvarr", plan.service_ids)
                self.assertNotIn("VELVARR_", render_environment(self.catalog, plan, None))

        selected = self.catalog.resolve("custom", selected={"velvarr"})
        self.assertEqual(selected.service_ids, ("velvarr",))
        self.assertEqual(selected.auto_added, ())
        removed = self.catalog.resolve("boudoirr", remove={"velvarr"})
        self.assertNotIn("velvarr", removed.service_ids)
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

        self.assertIn("velvarr", plan.service_ids)
        self.assertNotIn("jellyfin", plan.service_ids)
        self.assertNotIn("  jellyfin:", compose)
        self.assertNotIn("JELLYFIN_", environment)
        self.assertNotIn("- Jellyfin:", homepage)
        self.assertIn("- Velvarr:", homepage)

    def test_chart_uses_shared_identity_and_independent_internal_networking(self) -> None:
        """Keep writable data owned by the host user without assuming image tools."""
        plan = self.catalog.resolve("boudoirr", add={"velvarr"})
        compose = render_compose(self.catalog, plan)
        service = extract_service(compose, "velvarr")

        self.assertIn("user: ${DEFAULT_PUID}:${DEFAULT_PGID}", compose)
        self.assertIn("<<: *rootless-container", service)
        self.assertIn("image: ${VELVARR_IMAGE}:${VELVARR_TAG}", service)
        self.assertIn("${VELVARR_CONFIG_PATH}:/data:rw", service)
        self.assertIn("${VELVARR_WEBUI_PORT}:6699", service)
        self.assertNotIn("labels: *disable-watchtower-updates", service)
        self.assertIn("read_only: true", service)
        self.assertIn("- ALL", service)
        self.assertIn("no-new-privileges:true", service)
        self.assertIn("- CMD\n        - node\n        - -e", service)
        self.assertIn("http://127.0.0.1:6699/api/health", service)
        self.assertNotIn("wget", service)
        self.assertNotIn("depends_on:", service)
        self.assertNotIn("network_mode:", service)
        self.assertNotIn("/downloads", service)
        self.assertNotIn("VELVARR_IMAGE:-", service)
        self.assertNotIn("VELVARR_TAG:-", service)

    def test_fresh_host_defaults_follow_each_presets_port_offset(self) -> None:
        """Offset published ports while keeping paths and private HTTP usable."""
        for preset_id, expected_port in (
            ("plundarr", 6699),
            ("boudoirr", 16699),
            ("custom", 36699),
        ):
            with self.subTest(preset=preset_id):
                plan = self.catalog.resolve(preset_id, add={"velvarr"})
                environment = render_environment(self.catalog, plan, None, generate_secrets=False)

                self.assertIn(
                    f'VELVARR_WEBUI_PORT="${{VELVARR_WEBUI_PORT:-{expected_port}}}"',
                    environment,
                )
                self.assertIn(
                    'VELVARR_CONFIG_PATH="${VELVARR_CONFIG_PATH:-./config/velvarr}"',
                    environment,
                )
                self.assertIn(
                    'VELVARR_IMAGE="${VELVARR_IMAGE:-ghcr.io/skare69/velvarr}"', environment
                )
                self.assertIn('VELVARR_TAG="${VELVARR_TAG:-latest}"', environment)
                self.assertIn('VELVARR_ALLOW_HTTP="${VELVARR_ALLOW_HTTP:-1}"', environment)
                self.assertIn('VELVARR_ORIGIN="${VELVARR_ORIGIN:-}"', environment)
                self.assertIn('VELVARR_DISCORD_DETAIL="${VELVARR_DISCORD_DETAIL:-0}"', environment)
                self.assertIn("1 permits private-network HTTP", render_compose(self.catalog, plan))

    def test_generation_keeps_recovery_keys_and_operator_state(self) -> None:
        """Keep generated secrets private and stable across removal and reselection."""
        plan = self.catalog.resolve("boudoirr", add={"velvarr", "homepage"})

        with tempfile.TemporaryDirectory() as temporary_directory:
            output = Path(temporary_directory)

            # Compose validation is covered by the real matrix; this fixture exercises atomic writes.
            with patch("maraudarr.render.validate_compose"):
                _, env_path, config_path = write_stack(self.catalog, plan, output)

            first_environment = env_path.read_text()
            secrets = re.findall(
                r'^VELVARR_(?:SECRET_KEY|SETUP_SECRET)="([^"\n]+)"$',
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

            # Fresh deployments and the reference template use the official stable image.
            for environment in (first_environment, example):
                self.assertIn(
                    'VELVARR_IMAGE="${VELVARR_IMAGE:-ghcr.io/skare69/velvarr}"', environment
                )
                self.assertIn('VELVARR_TAG="${VELVARR_TAG:-latest}"', environment)

            self.assertIn('VELVARR_SECRET_KEY="${VELVARR_SECRET_KEY:-}"', example)
            self.assertIn('VELVARR_SETUP_SECRET="${VELVARR_SETUP_SECRET:-}"', example)

            # Use distinct operator values to catch accidental normalization or preset re-offsets.
            overrides = {
                'VELVARR_IMAGE="${VELVARR_IMAGE:-ghcr.io/skare69/velvarr}"': 'VELVARR_IMAGE="ghcr.io/example/velvarr"',
                'VELVARR_TAG="${VELVARR_TAG:-latest}"': 'VELVARR_TAG="edge"',
                'VELVARR_WEBUI_PORT="${VELVARR_WEBUI_PORT:-16699}"': 'VELVARR_WEBUI_PORT="17699"',
                'VELVARR_ORIGIN="${VELVARR_ORIGIN:-}"': 'VELVARR_ORIGIN="https://velvarr.example.com"',
                'VELVARR_ALLOW_HTTP="${VELVARR_ALLOW_HTTP:-1}"': 'VELVARR_ALLOW_HTTP="0"',
                'HOMEPAGE_VAR_VELVARR_HREF="${HOMEPAGE_VAR_VELVARR_HREF:-http://host.or.ip:${VELVARR_WEBUI_PORT}}"': 'HOMEPAGE_VAR_VELVARR_HREF="https://requests.example.com"',
            }
            edited = first_environment

            for original, replacement in overrides.items():
                self.assertIn(original, edited)
                edited = edited.replace(original, replacement)

            env_path.write_text(edited)
            database = config_path / "velvarr/velvarr.sqlite"
            database.write_bytes(b"operator-owned database fixture")
            dashboard = config_path / "homepage/settings.yaml"
            dashboard.write_text("title: Operator dashboard\n")

            # Temporarily deselecting a service must not discard the key needed for its database.
            with patch("maraudarr.render.validate_compose"):
                write_stack(
                    self.catalog, self.catalog.resolve("boudoirr", remove={"velvarr"}), output
                )
                write_stack(self.catalog, plan, output)

            regenerated = env_path.read_text()

            for secret in secrets:
                self.assertIn(secret, regenerated)

            for replacement in overrides.values():
                self.assertIn(replacement, regenerated)

            # The reference template stays official even when the deployment uses a fork.
            regenerated_example = (output / "example.env").read_text()
            self.assertIn(
                'VELVARR_IMAGE="${VELVARR_IMAGE:-ghcr.io/skare69/velvarr}"', regenerated_example
            )
            self.assertIn('VELVARR_TAG="${VELVARR_TAG:-latest}"', regenerated_example)

            self.assertEqual(database.read_bytes(), b"operator-owned database fixture")
            self.assertEqual(dashboard.read_text(), "title: Operator dashboard\n")
            self.assertTrue((config_path / "velvarr/README.md").is_file())
            self.assertEqual(env_path.stat().st_mode & 0o777, 0o600)

    def test_existing_tag_gains_official_repository_without_changing_channel(self) -> None:
        """Add the image setting to an older deployment while retaining its chosen version."""
        plan = self.catalog.resolve("boudoirr")

        with tempfile.TemporaryDirectory() as temporary_directory:
            env_path = Path(temporary_directory) / ".env"
            env_path.write_text('VELVARR_TAG="v0.36.0"\n')
            environment = render_environment(self.catalog, plan, env_path, generate_secrets=False)

        self.assertIn('VELVARR_IMAGE="${VELVARR_IMAGE:-ghcr.io/skare69/velvarr}"', environment)
        self.assertIn('VELVARR_TAG="v0.36.0"', environment)

    def test_existing_empty_secrets_are_preserved_without_silent_rotation(self) -> None:
        """Respect existing assignments even when an operator cleared a value."""
        plan = self.catalog.resolve("custom", selected={"velvarr"})

        with tempfile.TemporaryDirectory() as temporary_directory:
            env_path = Path(temporary_directory) / ".env"
            existing = 'VELVARR_SECRET_KEY=""\nVELVARR_SETUP_SECRET=""\n'
            env_path.write_text(existing)
            generated = render_environment(self.catalog, plan, env_path)

        for assignment in existing.splitlines():
            self.assertIn(assignment, generated)

    def test_homepage_link_and_variables_follow_service_selection(self) -> None:
        """Keep browser links tied to host ports without inventing a widget API."""
        for selected in ({"homepage"}, {"velvarr"}, {"homepage", "velvarr"}):
            with self.subTest(selected=selected):
                plan = self.catalog.resolve("custom", selected=selected)
                compose = render_compose(self.catalog, plan)
                environment = render_environment(self.catalog, plan, None)
                has_link = selected == {"homepage", "velvarr"}

                self.assertEqual("HOMEPAGE_VAR_VELVARR_HREF" in compose, has_link)
                self.assertEqual("HOMEPAGE_VAR_VELVARR_HREF" in environment, has_link)

                if "homepage" in selected:
                    homepage = render_homepage_services(self.catalog, plan)
                    self.assertEqual("- Velvarr:" in homepage, has_link)

                    if has_link:
                        self.assertIn("{{HOMEPAGE_VAR_VELVARR_HREF}}", homepage)
                        self.assertNotIn("widget:", homepage)

        plan = self.catalog.resolve("boudoirr", add={"velvarr", "homepage"})
        environment = render_environment(self.catalog, plan, None, generate_secrets=False)
        self.assertIn(
            'HOMEPAGE_VAR_VELVARR_HREF="${HOMEPAGE_VAR_VELVARR_HREF:-http://host.or.ip:${VELVARR_WEBUI_PORT}}"',
            environment,
        )

    def test_ui_explains_optional_recommendations_and_selected_setup(self) -> None:
        """Show the recommended companion without revealing generated credentials."""
        output = io.StringIO()

        with redirect_stdout(output):
            UI(plain=True).show_plan(self.catalog.resolve("boudoirr", remove={"velvarr"}))

        self.assertIn("Recommended integrations (optional): velvarr", output.getvalue())
        output = io.StringIO()
        plan = self.catalog.resolve("boudoirr", remove={"jellyfin"})

        with redirect_stdout(output):
            ui = UI(plain=True)
            ui.show_plan(plan)
            ui.success(plan, "compose", "environment", "config")

        listing = output.getvalue()
        self.assertIn("Recommended integrations (optional): jellyfin", listing)
        self.assertIn("read VELVARR_SETUP_SECRET locally", listing)
        self.assertIn("Complete Velvarr setup with Jellyfin", listing)

    @unittest.skipUnless(RICH_AVAILABLE, "Questionary and Rich are not installed")
    def test_interactive_companion_checkboxes_start_checked_and_accept_deselection(self) -> None:
        """Verify the actual checkbox choice is checked but remains removable."""
        from questionary import Choice

        ui = UI()
        ui.plain = False

        for service_id in ("velvarr", "jellyfin"):
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
        ui.show_plan(self.catalog.resolve("boudoirr", remove={"velvarr"}))

        self.assertIn("Recommended integrations (optional): velvarr", output.getvalue())


if __name__ == "__main__":
    unittest.main()
