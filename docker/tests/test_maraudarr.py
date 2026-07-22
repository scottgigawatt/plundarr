#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# test_maraudarr.py: Test Maraudarr catalog resolution and generated artifacts.
#

"""Exercise stack selection, rendering, secrets, and config generation."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from maraudarr.catalog import Catalog, CatalogError
from maraudarr.render import (
    render_compose,
    render_environment,
    render_homepage_services,
    write_stack,
)
from maraudarr.text import extract_service


class MaraudarrTests(unittest.TestCase):
    """Exercise presets, dependencies, rendering, and value preservation."""

    @classmethod
    def setUpClass(cls) -> None:
        cls.catalog = Catalog(Path(__file__).resolve().parents[1])

    def test_plundarr_preset_matches_the_documented_default(self) -> None:
        plan = self.catalog.resolve("plundarr")

        self.assertEqual(
            plan.service_ids,
            (
                "privateerr",
                "gluetun",
                "flaresolverr",
                "prowlarr",
                "qbittorrent",
                "radarr",
                "sonarr",
                "bazarr",
                "seerr",
                "cleanuparr",
                "speedtest-tracker",
                "duplicati",
                "homepage",
            ),
        )

    def test_boudoirr_preset_reuses_the_shared_service_catalog(self) -> None:
        plan = self.catalog.resolve("boudoirr")
        compose = render_compose(self.catalog, plan)

        self.assertEqual(
            plan.service_ids,
            (
                "privateerr",
                "gluetun",
                "flaresolverr",
                "prowlarr",
                "qbittorrent",
                "sabnzbd",
                "whisparr",
                "cleanuparr",
                "watchtower",
            ),
        )
        self.assertNotIn("depends_on:", extract_service(compose, "cleanuparr"))
        self.assertNotIn("depends_on:", extract_service(compose, "whisparr"))

    def test_dependencies_are_added_before_the_requested_service(self) -> None:
        plan = self.catalog.resolve("custom", selected={"qbittorrent"})

        self.assertEqual(plan.service_ids, ("privateerr", "gluetun", "qbittorrent"))
        self.assertEqual(set(plan.auto_added), {"privateerr", "gluetun"})

    def test_explicit_addition_wins_over_preset_removal(self) -> None:
        plan = self.catalog.resolve(
            "plundarr",
            add={"qbittorrent", "cleanuparr"},
            remove={"qbittorrent", "cleanuparr"},
        )

        self.assertIn("qbittorrent", plan.service_ids)
        self.assertIn("cleanuparr", plan.service_ids)

    def test_empty_custom_stack_is_rejected(self) -> None:
        with self.assertRaisesRegex(CatalogError, "at least one service"):
            self.catalog.resolve("custom", selected=set())

    def test_compose_keeps_comments_variables_and_selected_services(self) -> None:
        plan = self.catalog.resolve(
            "plundarr",
            add={"apprise", "jellyfin", "sabnzbd", "sonarr-anime"},
        )

        compose = render_compose(self.catalog, plan)

        self.assertTrue(compose.startswith("#\n# Copyright 2025-2026 Scott Gigawatt"))
        self.assertIn("# Services included:", compose)
        self.assertIn("# Define the 'apprise' service", compose)
        self.assertIn("# Define the 'jellyfin' service", compose)
        self.assertIn("${APPRISE_API_ONLY}", compose)
        self.assertIn("${JELLYFIN_WEBUI_PORT}:8096", compose)
        self.assertIn("${SABNZBD_WEBUI_PORT}:8085", compose)
        self.assertIn("HOMEPAGE_VAR_SONARR_ANIME_KEY", compose)

    def test_environment_sections_follow_service_selection(self) -> None:
        plan = self.catalog.resolve("plundarr", add={"apprise"}, remove={"qbittorrent"})

        with tempfile.TemporaryDirectory() as temporary_directory:
            env_path = Path(temporary_directory) / ".env"
            environment = render_environment(self.catalog, plan, env_path)

        self.assertIn("# Apprise notification environment variables", environment)
        self.assertNotIn("# qBittorrent environment variables", environment)
        self.assertNotIn("HOMEPAGE_VAR_QBITTORRENT_HREF", environment)
        self.assertLess(environment.index("PROWLARR_TAG"), environment.index("RADARR_TAG"))
        self.assertLess(environment.index("SPEEDTEST_TRACKER_TAG"), environment.index("APPRISE_TAG"))

    def test_existing_environment_values_survive_a_rebuild(self) -> None:
        plan = self.catalog.resolve("plundarr")

        with tempfile.TemporaryDirectory() as temporary_directory:
            env_path = Path(temporary_directory) / ".env"
            env_path.write_text(
                'PIA_USER="captain"\n'
                'TZ="Pacific/Honolulu"\n'
                'SPEEDTEST_TRACKER_APP_KEY="base64:keep-this-key"\n'
                'DUPLICATI_WEBSERVICE_PASSWORD="keep-this-password"\n'  # pragma: allowlist secret
                'SONARR_CONFIG_PATH="${SONARR_CONFIG_PATH:-./config/sonarr}"\n'
            )
            environment = render_environment(self.catalog, plan, env_path)

        self.assertIn('PIA_USER="captain"', environment)
        self.assertIn('TZ="Pacific/Honolulu"', environment)
        self.assertIn(
            'SPEEDTEST_TRACKER_APP_KEY="base64:keep-this-key"', environment
        )
        self.assertIn(
            'DUPLICATI_WEBSERVICE_PASSWORD="keep-this-password"',  # pragma: allowlist secret
            environment,
        )
        self.assertIn(
            'SONARR_CONFIG_PATH="${SONARR_CONFIG_PATH:-./config/sonarr}"',
            environment,
        )

    def test_new_environment_receives_secure_application_secrets(self) -> None:
        plan = self.catalog.resolve("plundarr")

        with tempfile.TemporaryDirectory() as temporary_directory:
            environment = render_environment(
                self.catalog,
                plan,
                Path(temporary_directory) / ".env",
            )

        speedtest_key = next(
            line
            for line in environment.splitlines()
            if line.startswith("SPEEDTEST_TRACKER_APP_KEY=")
        )
        duplicati_key = next(
            line
            for line in environment.splitlines()
            if line.startswith("DUPLICATI_SETTINGS_ENCRYPTION_KEY=")
        )
        duplicati_password = next(
            line
            for line in environment.splitlines()
            if line.startswith("DUPLICATI_WEBSERVICE_PASSWORD=")
        )
        self.assertRegex(
            speedtest_key,
            r'^SPEEDTEST_TRACKER_APP_KEY="base64:[A-Za-z0-9+/]{43}="$'
        )
        self.assertNotIn("change-me", duplicati_key)
        self.assertNotIn("changeme", duplicati_password)

    def test_unselected_service_values_survive_preset_changes(self) -> None:
        plundarr = self.catalog.resolve("plundarr")
        boudoirr = self.catalog.resolve("boudoirr")
        expected_value = 'DUPLICATI_TAG="preserve-this-tag"'

        with tempfile.TemporaryDirectory() as temporary_directory:
            env_path = Path(temporary_directory) / ".env"
            env_path.write_text(expected_value + "\n")

            second_environment = render_environment(self.catalog, boudoirr, env_path)
            self.assertIn(
                "# Preserved values for services not selected in this stack",
                second_environment,
            )
            self.assertIn(expected_value, second_environment)
            env_path.write_text(second_environment)

            restored_environment = render_environment(self.catalog, plundarr, env_path)
            self.assertIn(expected_value, restored_environment)
            self.assertEqual(restored_environment.count(expected_value), 1)

    def test_homepage_fragments_join_the_correct_service_groups(self) -> None:
        plan = self.catalog.resolve(
            "plundarr",
            add={"jellyfin", "sonarr-anime"},
        )
        homepage = render_homepage_services(self.catalog, plan)

        media_group = homepage[: homepage.index("- Data:")]
        downloads_group = homepage[homepage.index("- Downloads:") :]
        self.assertIn("- Jellyfin:", media_group)
        self.assertIn("- Sonarr Anime:", media_group)
        self.assertIn("- qBittorrent:", downloads_group)
        self.assertNotIn("- Jellyfin:", downloads_group)

    def test_custom_homepage_omits_unselected_cards_and_variables(self) -> None:
        plan = self.catalog.resolve("custom", selected={"homepage"})

        compose = render_compose(self.catalog, plan)
        homepage = render_homepage_services(self.catalog, plan)
        with tempfile.TemporaryDirectory() as temporary_directory:
            environment = render_environment(
                self.catalog,
                plan,
                Path(temporary_directory) / ".env",
            )

        self.assertNotIn("HOMEPAGE_VAR_RADARR", compose)
        self.assertNotIn("HOMEPAGE_VAR_PLEX", compose)
        self.assertNotIn("HOMEPAGE_VAR_RADARR", environment)
        self.assertNotIn("HOMEPAGE_VAR_PLEX", environment)
        self.assertNotIn("- Radarr:", homepage)
        self.assertNotIn("- Plex:", homepage)
        self.assertTrue(homepage.endswith("[]\n"))

    def test_inline_comments_have_two_spaces_before_the_hash(self) -> None:
        compose = render_compose(
            self.catalog,
            self.catalog.resolve("custom", selected=set(self.catalog.services)),
        )

        for line_number, line in enumerate(compose.splitlines(), start=1):
            if "#" not in line or line.lstrip().startswith("#"):
                continue
            hash_index = line.find("#")
            self.assertGreaterEqual(
                len(line[:hash_index]) - len(line[:hash_index].rstrip(" ")),
                2,
                f"Inline comment spacing failed on generated line {line_number}: {line}",
            )

    def test_service_charts_reuse_shared_anchors(self) -> None:
        for service in self.catalog.services.values():
            compose = self.catalog.source_path(service.compose).read_text()

            with self.subTest(service=service.id):
                self.assertRegex(
                    compose,
                    r"<<: \*(?:arr-stack|default)-container",
                    f"Service '{service.id}' does not reuse a container anchor.",
                )
                if "healthcheck:" in compose:
                    self.assertIn(
                        "<<: *default-healthcheck-settings",
                        compose,
                        f"Service '{service.id}' does not reuse healthcheck settings.",
                    )

    def test_plex_and_jellyfin_are_independent_media_server_choices(self) -> None:
        plan = self.catalog.resolve(
            "custom",
            selected={"homepage", "jellyfin", "plex"},
        )

        compose = render_compose(self.catalog, plan)
        homepage = render_homepage_services(self.catalog, plan)

        self.assertIn("  plex:", compose)
        self.assertIn("  jellyfin:", compose)
        self.assertIn("network_mode: host", compose)
        self.assertIn("- Plex:", homepage)
        self.assertIn("- Jellyfin:", homepage)

    def test_write_stack_creates_only_selected_config_directories(self) -> None:
        plan = self.catalog.resolve(
            "custom",
            selected={"homepage", "jellyfin"},
        )

        with tempfile.TemporaryDirectory() as temporary_directory:
            output_path = Path(temporary_directory)
            compose_path, env_path, config_path = write_stack(
                self.catalog,
                plan,
                output_path,
            )

            self.assertTrue(compose_path.is_file())
            self.assertTrue(env_path.is_file())
            self.assertTrue((output_path / "example.env").is_file())
            self.assertTrue((config_path / "README.md").is_file())
            self.assertTrue((config_path / "homepage" / "README.md").is_file())
            self.assertTrue((config_path / "homepage" / "services.yaml").is_file())
            self.assertTrue((config_path / "jellyfin" / "README.md").is_file())
            self.assertFalse((config_path / "plex").exists())


if __name__ == "__main__":
    unittest.main()
