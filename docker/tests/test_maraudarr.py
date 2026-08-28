#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# test_maraudarr.py: Test Maraudarr catalog resolution and generated artifacts.
#

"""Exercise stack selection, rendering, secrets, and config generation."""

from __future__ import annotations

import re
import tempfile
import unittest
from ipaddress import ip_network
from itertools import combinations
from pathlib import Path
from subprocess import CompletedProcess
from unittest.mock import Mock, patch

from maraudarr.catalog import Catalog, CatalogError
from maraudarr.render import (
    RenderError,
    render_compose,
    render_environment,
    render_homepage_services,
    validate_compose,
    write_stack,
)
from maraudarr.text import extract_service


class MaraudarrTests(unittest.TestCase):
    """Exercise presets, dependencies, rendering, and value preservation."""

    @classmethod
    def setUpClass(cls) -> None:
        """Load the shared service catalog once for this test class."""

        cls.catalog = Catalog(Path(__file__).resolve().parents[1])

    #
    # Preset and dependency resolution behavior.
    #
    def test_plundarr_preset_matches_the_documented_default(self) -> None:
        """Keep the Plundarr preset service order stable and documented."""

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
        self.assertNotIn("sonarr-anime", plan.service_ids)

    def test_boudoirr_preset_reuses_the_shared_service_catalog(self) -> None:
        """Build Boudoirr from shared services without Plundarr-only edges."""

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
                "whisparr",
                "cleanuparr",
            ),
        )
        self.assertNotIn("depends_on:", extract_service(compose, "cleanuparr"))
        self.assertNotIn("depends_on:", extract_service(compose, "whisparr"))
        self.assertNotIn("  jellyfin:", compose)
        self.assertNotIn("  plex:", compose)

    def test_automation_presets_support_optional_downloader_modes(self) -> None:
        """Keep torrent-only, Usenet-only, and combined modes selectable."""

        for preset_id in ("plundarr", "boudoirr"):
            with self.subTest(preset=preset_id, mode="torrent"):
                default = set(self.catalog.resolve(preset_id).service_ids)
                self.assertIn("qbittorrent", default)
                self.assertNotIn("sabnzbd", default)
                self.assertNotIn("nzbget", default)

            with self.subTest(preset=preset_id, mode="usenet"):
                usenet = set(
                    self.catalog.resolve(
                        preset_id,
                        add={"sabnzbd"},
                        remove={"qbittorrent", "cleanuparr"},
                    ).service_ids
                )
                self.assertIn("sabnzbd", usenet)
                self.assertNotIn("qbittorrent", usenet)

            with self.subTest(preset=preset_id, mode="combined"):
                combined = set(
                    self.catalog.resolve(preset_id, add={"sabnzbd"}).service_ids
                )
                self.assertIn("qbittorrent", combined)
                self.assertIn("sabnzbd", combined)

    def test_watchtower_is_opt_in_for_automation_presets(self) -> None:
        """Leave Watchtower unchecked until a user explicitly selects it."""

        for preset_id in ("plundarr", "boudoirr"):
            with self.subTest(preset=preset_id):
                default = self.catalog.resolve(preset_id)
                selected = self.catalog.resolve(preset_id, add={"watchtower"})

                self.assertNotIn("watchtower", default.service_ids)
                self.assertIn("watchtower", selected.service_ids)

    def test_watchtower_preset_selects_only_the_updater(self) -> None:
        """Keep the standalone updater focused and available for one-shot runs."""

        plan = self.catalog.resolve("watchtower")
        compose = render_compose(self.catalog, plan)
        environment = render_environment(
            self.catalog,
            plan,
            None,
            generate_secrets=False,
        )

        self.assertEqual(plan.service_ids, ("watchtower",))
        self.assertIn("image: nickfedor/watchtower:${WATCHTOWER_TAG}", compose)
        self.assertNotIn("DOCKER_API_VERSION", compose)
        self.assertIn('WATCHTOWER_TAG="${WATCHTOWER_TAG:-latest}"', environment)
        self.assertIn(
            'WATCHTOWER_INCLUDE_STOPPED="${WATCHTOWER_INCLUDE_STOPPED:-true}"',
            environment,
        )
        self.assertIn(
            'WATCHTOWER_REVIVE_STOPPED="${WATCHTOWER_REVIVE_STOPPED:-false}"',
            environment,
        )
        self.assertIn(
            'WATCHTOWER_NOTIFICATIONS="${WATCHTOWER_NOTIFICATIONS:-shoutrrr}"',
            environment,
        )

    def test_standalone_media_server_presets_select_one_core_service(self) -> None:
        """Keep the standalone Jellyfin and Plex presets deliberately focused."""

        self.assertEqual(self.catalog.resolve("jellyfin").service_ids, ("jellyfin",))
        self.assertEqual(self.catalog.resolve("plex").service_ids, ("plex",))
        self.assertEqual(
            self.catalog.preset("jellyfin").media_libraries, ("movies", "tv")
        )
        self.assertEqual(
            self.catalog.preset("boudoirr").media_libraries, ("movies", "scenes")
        )

    def test_dependencies_are_added_before_the_requested_service(self) -> None:
        """Auto-add required services before their selected dependent."""

        plan = self.catalog.resolve("custom", selected={"qbittorrent"})

        self.assertEqual(plan.service_ids, ("privateerr", "gluetun", "qbittorrent"))
        self.assertEqual(set(plan.auto_added), {"privateerr", "gluetun"})

    def test_nzbget_adds_the_vpn_foundation(self) -> None:
        """Route a custom NZBGet selection through Privateerr and Gluetun."""

        plan = self.catalog.resolve("custom", selected={"nzbget"})

        self.assertEqual(plan.service_ids, ("privateerr", "gluetun", "nzbget"))
        self.assertEqual(set(plan.auto_added), {"privateerr", "gluetun"})

    def test_explicit_addition_wins_over_preset_removal(self) -> None:
        """Honor an explicit service addition when remove also names it."""

        plan = self.catalog.resolve(
            "plundarr",
            add={"qbittorrent", "cleanuparr"},
            remove={"qbittorrent", "cleanuparr"},
        )

        self.assertIn("qbittorrent", plan.service_ids)
        self.assertIn("cleanuparr", plan.service_ids)

    def test_empty_custom_stack_is_rejected(self) -> None:
        """Reject custom voyages that would produce no services."""

        with self.assertRaisesRegex(CatalogError, "at least one service"):
            self.catalog.resolve("custom", selected=set())

    #
    # Generated Compose and environment rendering behavior.
    #
    def test_compose_keeps_comments_variables_and_selected_services(self) -> None:
        """Preserve source comments and variables for selected services."""

        plan = self.catalog.resolve(
            "plundarr",
            add={"apprise", "jellyfin", "nzbget", "sabnzbd", "sonarr-anime"},
        )

        compose = render_compose(self.catalog, plan)
        jellyfin = extract_service(compose, "jellyfin")

        self.assertTrue(compose.startswith("#\n# Copyright 2025-2026 Scott Gigawatt"))
        self.assertIn("# Services included:", compose)
        self.assertIn("# Define the 'apprise' service", compose)
        self.assertIn("# Define the 'jellyfin' service", compose)
        self.assertIn("${APPRISE_API_ONLY}", compose)
        self.assertIn("image: jellyfin/jellyfin:${JELLYFIN_TAG}", compose)
        self.assertNotIn("lscr.io/linuxserver/jellyfin", compose)
        self.assertIn("${JELLYFIN_WEBUI_PORT}:8096", compose)
        self.assertIn("${JELLYFIN_DATA_PATH}:/data:rw", jellyfin)
        self.assertNotIn("${HOST_MOVIES_PATH}:/movies", jellyfin)
        self.assertNotIn("${HOST_TV_PATH}:/tv", jellyfin)
        self.assertNotIn("${HOST_ANIME_TV_PATH}:/anime", jellyfin)
        self.assertIn("${SABNZBD_WEBUI_PORT}:8085", compose)
        self.assertIn("${NZBGET_WEBUI_PORT}:6789", compose)
        self.assertIn("/app/nzbget/nzbget", compose)
        self.assertIn("HOMEPAGE_VAR_NZBGET_USER", compose)
        self.assertIn("HOMEPAGE_VAR_SONARR_ANIME_KEY", compose)
        self.assertEqual(3, compose.count("<<: *rootless-container"))
        self.assertIn("http://127.0.0.1:8000/status", compose)

    def test_environment_sections_follow_service_selection(self) -> None:
        """Render environment sections only for the resolved stack plan."""

        plan = self.catalog.resolve("plundarr", add={"apprise"}, remove={"qbittorrent"})

        with tempfile.TemporaryDirectory() as temporary_directory:
            env_path = Path(temporary_directory) / ".env"
            environment = render_environment(self.catalog, plan, env_path)

        self.assertIn("# Apprise notification environment variables", environment)
        self.assertNotIn("# qBittorrent environment variables", environment)
        self.assertNotIn("HOMEPAGE_VAR_QBITTORRENT_HREF", environment)
        self.assertNotIn("# NZBGet environment variables", environment)
        self.assertNotIn("HOMEPAGE_VAR_NZBGET_HREF", environment)
        self.assertLess(environment.index("PROWLARR_TAG"), environment.index("RADARR_TAG"))
        self.assertLess(environment.index("SPEEDTEST_TRACKER_TAG"), environment.index("APPRISE_TAG"))

    def test_environment_keeps_operator_edit_guidance(self) -> None:
        """Keep concise source guidance beside values novice operators change."""

        environment = render_environment(
            self.catalog,
            self.catalog.resolve("plundarr"),
            None,
            generate_secrets=False,
        )

        self.assertIn("# Edit for your host: shared download root", environment)
        self.assertIn("# Edit for your host: run `id -u`", environment)
        self.assertIn("# Edit before launch: PIA account username", environment)
        self.assertIn("# Change only for a host-port conflict", environment)

    def test_preset_environment_defaults_match_each_deployment(self) -> None:
        """Give fresh presets distinct identities, networks, and media roots."""

        cases = {
            "plundarr": (
                "plundarr",
                "172.28.0.0/16",
                "/volume1/plex",
            ),
            "boudoirr": (
                "boudoirr",
                "172.29.0.0/16",
                "/volume1/jellyfin",
            ),
            "jellyfin": (
                "jellyfin",
                "172.30.0.0/16",
                "/volume1/jellyfin",
            ),
            "plex": (
                "plex",
                "172.31.0.0/16",
                "/volume1/plex",
            ),
            "watchtower": (
                "watchtower",
                "172.25.0.0/16",
                "/volume1/plex",
            ),
        }

        for preset_id, (project, subnet, media_root) in cases.items():
            with self.subTest(preset=preset_id):
                plan = self.catalog.resolve(preset_id)
                environment = render_environment(
                    self.catalog,
                    plan,
                    None,
                    generate_secrets=False,
                )

                self.assertIn(
                    f'COMPOSE_PROJECT_NAME="${{COMPOSE_PROJECT_NAME:-{project}}}"',
                    environment,
                )
                self.assertIn(
                    f'COMPOSE_NETWORK_SUBNET="${{COMPOSE_NETWORK_SUBNET:-{subnet}}}"',
                    environment,
                )
                self.assertIn(
                    f'HOST_MOVIES_PATH="${{HOST_MOVIES_PATH:-{media_root}/movies}}"',
                    environment,
                )
                if "jellyfin" in plan.service_ids:
                    self.assertIn(
                        f'JELLYFIN_DATA_PATH="${{JELLYFIN_DATA_PATH:-{media_root}}}"',
                        environment,
                    )
                if "whisparr" in plan.service_ids:
                    self.assertIn(
                        f'WHISPARR_DATA_PATH="${{WHISPARR_DATA_PATH:-{media_root}}}"',
                        environment,
                    )

    def test_fresh_presets_can_share_one_docker_host(self) -> None:
        """Keep project names, networks, containers, and host ports distinct."""

        preset_ids = (
            "plundarr",
            "boudoirr",
            "jellyfin",
            "plex",
            "watchtower",
            "custom",
        )
        plans = {
            preset_id: self.catalog.resolve(
                preset_id,
                selected={"homepage"} if preset_id == "custom" else None,
            )
            for preset_id in preset_ids
        }
        project_names = [plan.preset.project_name for plan in plans.values()]
        networks = [
            ip_network(plan.preset.network_subnet) for plan in plans.values()
        ]

        self.assertEqual(len(project_names), len(set(project_names)))
        for first, second in combinations(networks, 2):
            self.assertFalse(first.overlaps(second), f"{first} overlaps {second}")

        container_names: dict[str, set[str]] = {}
        published_ports: dict[str, set[int]] = {}
        for preset_id, plan in plans.items():
            compose = render_compose(self.catalog, plan)
            environment = render_environment(
                self.catalog,
                plan,
                None,
                generate_secrets=False,
            )
            container_names[preset_id] = {
                name.replace("${COMPOSE_PROJECT_NAME}", plan.preset.project_name)
                for name in re.findall(
                    r"^\s*container_name:\s+([^\s#]+)", compose, re.MULTILINE
                )
            }
            port_variables = set(
                re.findall(
                    r"^\s*-\s+\$\{([A-Z][A-Z0-9_]*PORT)\}:",
                    compose,
                    re.MULTILINE,
                )
            )
            published_ports[preset_id] = {
                int(match.group(1))
                for variable in port_variables
                if (
                    match := re.search(
                    rf'^{re.escape(variable)}="\$\{{{re.escape(variable)}:-(\d+)\}}"(?:\s+#.*)?$',
                        environment,
                        re.MULTILINE,
                    )
                )
            }

        for first, second in combinations(preset_ids, 2):
            self.assertTrue(
                container_names[first].isdisjoint(container_names[second])
            )
            self.assertTrue(
                published_ports[first].isdisjoint(published_ports[second])
            )

        self.assertIn(8191, published_ports["plundarr"])
        self.assertIn(9696, published_ports["plundarr"])
        self.assertIn(8080, published_ports["plundarr"])
        self.assertIn(11011, published_ports["plundarr"])
        self.assertIn(18191, published_ports["boudoirr"])
        self.assertIn(19696, published_ports["boudoirr"])
        self.assertIn(18080, published_ports["boudoirr"])
        self.assertIn(21011, published_ports["boudoirr"])
        self.assertIn(28096, published_ports["jellyfin"])
        self.assertIn(33000, published_ports["custom"])

        boudoirr_homepage = render_environment(
            self.catalog,
            self.catalog.resolve("boudoirr", add={"homepage"}),
            None,
            generate_secrets=False,
        )
        self.assertIn(
            'HOMEPAGE_VAR_QBITTORRENT_HREF="${HOMEPAGE_VAR_QBITTORRENT_HREF:-http://host.or.ip:18080}"',
            boudoirr_homepage,
        )

    def test_existing_boudoirr_port_values_survive_a_rebuild(self) -> None:
        """Preserve operator-selected ports instead of applying a fresh offset."""

        with tempfile.TemporaryDirectory() as temporary_directory:
            env_path = Path(temporary_directory) / ".env"
            existing_port = (
                'QBITTORRENT_WEBUI_PORT="${QBITTORRENT_WEBUI_PORT:-28080}"'
            )
            env_path.write_text(existing_port + "\n")
            environment = render_environment(
                self.catalog,
                self.catalog.resolve("boudoirr"),
                env_path,
                generate_secrets=False,
            )

        self.assertIn(existing_port, environment)
        self.assertNotIn(
            'QBITTORRENT_WEBUI_PORT="${QBITTORRENT_WEBUI_PORT:-18080}"',
            environment,
        )

    def test_existing_environment_values_survive_a_rebuild(self) -> None:
        """Preserve user-managed environment values across regeneration."""

        plan = self.catalog.resolve("plundarr", add={"nzbget"})

        with tempfile.TemporaryDirectory() as temporary_directory:
            env_path = Path(temporary_directory) / ".env"
            env_path.write_text(
                'PIA_USER="captain"\n'
                'TZ="Pacific/Honolulu"\n'
                'SPEEDTEST_TRACKER_APP_KEY="base64:keep-this-key"\n'
                'DUPLICATI_WEBSERVICE_PASSWORD="keep-this-password"\n'  # pragma: allowlist secret
                'NZBGET_PASS="keep-this-nzbget-password"\n'  # pragma: allowlist secret
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
            'NZBGET_PASS="keep-this-nzbget-password"',  # pragma: allowlist secret
            environment,
        )
        self.assertIn(
            'SONARR_CONFIG_PATH="${SONARR_CONFIG_PATH:-./config/sonarr}"',
            environment,
        )

    def test_new_environment_receives_secure_application_secrets(self) -> None:
        """Generate non-placeholder secrets for a new environment file."""

        plan = self.catalog.resolve("plundarr", add={"nzbget"})

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
        nzbget_password = next(
            line
            for line in environment.splitlines()
            if line.startswith("NZBGET_PASS=")
        )
        self.assertRegex(
            speedtest_key,
            r'^SPEEDTEST_TRACKER_APP_KEY="base64:[A-Za-z0-9+/]{43}="$'
        )
        self.assertNotIn("change-me", duplicati_key)
        self.assertNotIn("changeme", duplicati_password)
        self.assertRegex(nzbget_password, r'^NZBGET_PASS="[A-Za-z0-9_-]{20,}"$')
        self.assertNotIn("changeme", nzbget_password)

    def test_unselected_service_values_survive_preset_changes(self) -> None:
        """Carry inactive service values through preset changes and back."""

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
            env_path.write_text(
                "#\n"
                "# Preserved values for services not selected in this stack\n"
                "#\n"
                f"{expected_value}\n"
            )

            restored_environment = render_environment(self.catalog, plundarr, env_path)
            self.assertIn(expected_value, restored_environment)
            self.assertEqual(restored_environment.count(expected_value), 1)

    #
    # Docker Compose validation behavior.
    #
    @patch("maraudarr.render.subprocess.run")
    def test_compose_validation_prefers_the_docker_plugin(self, run: Mock) -> None:
        """Prefer the common Docker CLI plugin when it is installed."""

        run.return_value = CompletedProcess([], 0, "", "")

        validate_compose(Path("/tmp/plundarr-output"))

        command = run.call_args.args[0]
        self.assertEqual(command[:2], ["docker", "compose"])
        self.assertEqual(command[-2:], ["config", "--quiet"])
        run.assert_called_once()

    @patch("maraudarr.render.subprocess.run")
    def test_compose_validation_falls_back_to_the_standalone_binary(
        self,
        run: Mock,
    ) -> None:
        """Use standalone Compose when the Docker CLI is not installed."""

        run.side_effect = [
            FileNotFoundError,
            CompletedProcess([], 0, "", ""),
        ]

        validate_compose(Path("/tmp/plundarr-output"))

        self.assertEqual(run.call_count, 2)
        plugin_command = run.call_args_list[0].args[0]
        standalone_command = run.call_args_list[1].args[0]
        self.assertEqual(plugin_command[:2], ["docker", "compose"])
        self.assertEqual(standalone_command[0], "docker-compose")
        self.assertEqual(plugin_command[2:], standalone_command[1:])

    @patch("maraudarr.render.subprocess.run")
    def test_compose_validation_tolerates_missing_executables(
        self,
        run: Mock,
    ) -> None:
        """Allow source-only rendering when neither Compose command exists."""

        run.side_effect = FileNotFoundError

        validate_compose(Path("/tmp/plundarr-output"))

        self.assertEqual(run.call_count, 2)

    @patch("maraudarr.render.subprocess.run")
    def test_compose_validation_rejects_invalid_output(self, run: Mock) -> None:
        """Treat a failure from an installed Compose command as authoritative."""

        run.return_value = CompletedProcess([], 1, "", "invalid stack")

        with self.assertRaisesRegex(RenderError, "invalid stack"):
            validate_compose(Path("/tmp/plundarr-output"))

        run.assert_called_once()

    #
    # Homepage card and variable selection behavior.
    #
    def test_homepage_fragments_join_the_correct_service_groups(self) -> None:
        """Place selected Homepage cards in their intended service groups."""

        plan = self.catalog.resolve(
            "plundarr",
            add={"jellyfin", "nzbget", "sonarr-anime"},
        )
        homepage = render_homepage_services(self.catalog, plan)

        media_group = homepage[: homepage.index("- Data:")]
        downloads_group = homepage[homepage.index("- Downloads:") :]
        self.assertIn("- Jellyfin:", media_group)
        self.assertIn("- Sonarr Anime:", media_group)
        self.assertIn("{{HOMEPAGE_VAR_SONARR_ANIME_CONTAINER}}", media_group)
        self.assertIn("- qBittorrent:", downloads_group)
        self.assertIn("- NZBGet:", downloads_group)
        self.assertIn("{{HOMEPAGE_VAR_QBITTORRENT_CONTAINER}}", downloads_group)
        self.assertNotIn("- Jellyfin:", downloads_group)

    def test_custom_homepage_omits_unselected_cards_and_variables(self) -> None:
        """Exclude cards and variables for services outside a custom plan."""

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
        self.assertNotIn("HOMEPAGE_VAR_NZBGET", compose)
        self.assertNotIn("HOMEPAGE_VAR_RADARR", environment)
        self.assertNotIn("HOMEPAGE_VAR_PLEX", environment)
        self.assertNotIn("HOMEPAGE_VAR_NZBGET", environment)
        self.assertNotIn("- Radarr:", homepage)
        self.assertNotIn("- Plex:", homepage)
        self.assertNotIn("- NZBGet:", homepage)
        self.assertTrue(homepage.endswith("[]\n"))

    #
    # Catalog source and generated style enforcement.
    #
    def test_container_names_include_project_service_and_image_tag(self) -> None:
        """Keep every explicit container name unique across projects and tags."""

        compose = render_compose(
            self.catalog,
            self.catalog.resolve("custom", selected=set(self.catalog.services)),
        )

        for service in self.catalog.services.values():
            block = extract_service(compose, service.service)
            tag_match = re.search(
                r"^\s*image:.*\$\{([A-Z][A-Z0-9_]*_TAG)\}",
                block,
                re.MULTILINE,
            )
            with self.subTest(service=service.id):
                self.assertIsNotNone(tag_match)
                tag_variable = tag_match.group(1)
                self.assertIn(
                    f"container_name: ${{COMPOSE_PROJECT_NAME}}-{service.id}-${{{tag_variable}}}",
                    block,
                )

    def test_service_identity_comments_are_aligned(self) -> None:
        """Align comments in every service image and container identity block."""

        identity_keys = (
            "<<:",
            "image:",
            "container_name:",
            "hostname:",
            "network_mode:",
        )
        for service in self.catalog.services.values():
            source = self.catalog.source_path(service.compose).read_text()
            block = source.split("# Docker image and container information", 1)[1]
            block = block.split("\n\n", 1)[0]
            comment_columns = {
                line.index("#")
                for line in block.splitlines()
                if line.strip().startswith(identity_keys) and "#" in line
            }
            with self.subTest(service=service.id):
                self.assertEqual(
                    len(comment_columns),
                    1,
                    f"Service '{service.id}' identity comments are not aligned.",
                )

    def test_inline_comments_have_two_spaces_before_the_hash(self) -> None:
        """Require two spaces before every generated inline comment."""

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
        """Require service charts to inherit shared container settings."""

        for service in self.catalog.services.values():
            compose = self.catalog.source_path(service.compose).read_text()

            with self.subTest(service=service.id):
                self.assertRegex(
                    compose,
                    r"<<: \*(?:arr-stack|default|rootless)-container",
                    f"Service '{service.id}' does not reuse a container anchor.",
                )
                if "healthcheck:" in compose:
                    self.assertIn(
                        "<<: *default-healthcheck-settings",
                        compose,
                        f"Service '{service.id}' does not reuse healthcheck settings.",
                    )

    def test_healthchecks_use_shell_only_when_required(self) -> None:
        """Execute probes directly unless shell expansion is required."""

        shell_healthchecks = set()

        for service in self.catalog.services.values():
            compose = self.catalog.source_path(service.compose).read_text()
            if "healthcheck:" not in compose:
                continue

            with self.subTest(service=service.id):
                self.assertNotIn("|| exit 1", compose)
                if "\n        - CMD-SHELL\n" in compose:
                    shell_healthchecks.add(service.id)
                else:
                    self.assertIn("\n        - CMD\n", compose)
                if service.id == "privateerr":
                    self.assertIn("\n        - privateerr-healthcheck\n", compose)
                if service.id == "nzbget":
                    self.assertIn("\n        - /app/nzbget/nzbget\n", compose)
                    self.assertIn("\n        - /config/nzbget.conf\n", compose)

        self.assertEqual(shell_healthchecks, set())

    #
    # Media-server selection and generated filesystem behavior.
    #
    def test_plex_and_jellyfin_are_independent_media_server_choices(self) -> None:
        """Allow Plex and Jellyfin to be selected independently or together."""

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

    def test_plex_library_mounts_follow_the_selected_preset(self) -> None:
        """Mount only the library set expected by each Plex deployment."""

        cases = {
            "plundarr": ({"movies", "tv", "anime"}, {"scenes"}),
            "boudoirr": ({"movies", "scenes"}, {"tv", "anime"}),
            "plex": ({"movies", "tv"}, {"anime", "scenes"}),
        }
        mounts = {
            "movies": "${HOST_MOVIES_PATH}:/movies:ro",
            "tv": "${HOST_TV_PATH}:/tv:ro",
            "anime": "${HOST_ANIME_TV_PATH}:/anime:ro",
            "scenes": "${HOST_SCENES_PATH}:/scenes:ro",
        }

        for preset_id, (included, excluded) in cases.items():
            with self.subTest(preset=preset_id):
                plan = self.catalog.resolve(preset_id, add={"plex"})
                plex = extract_service(render_compose(self.catalog, plan), "plex")
                for library in included:
                    self.assertIn(mounts[library], plex)
                for library in excluded:
                    self.assertNotIn(mounts[library], plex)

    def test_write_stack_creates_only_selected_config_directories(self) -> None:
        """Create configuration directories only for selected services."""

        plan = self.catalog.resolve(
            "custom",
            selected={"homepage", "jellyfin", "nzbget", "qbittorrent"},
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
            self.assertTrue((config_path / "jellyfin" / "config").is_dir())
            self.assertTrue((config_path / "jellyfin" / "cache").is_dir())
            self.assertTrue((config_path / "nzbget" / "README.md").is_file())
            self.assertTrue(
                (
                    config_path
                    / "qbittorrent"
                    / "qBittorrent"
                    / "qBittorrent.conf"
                ).is_file()
            )
            self.assertFalse((config_path / "plex").exists())


if __name__ == "__main__":
    unittest.main()
