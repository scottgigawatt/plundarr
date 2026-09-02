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
        environment = render_environment(
            self.catalog,
            plan,
            None,
            generate_secrets=False,
        )

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
                "calibre-web-automated",
                "cleanuparr",
                "speedtest-tracker",
                "duplicati",
                "homepage",
                "watchtower",
            ),
        )
        self.assertNotIn("sonarr-anime", plan.service_ids)
        self.assertNotIn("lidarr", plan.service_ids)
        self.assertNotIn("recyclarr", plan.service_ids)
        self.assertNotIn("HOST_MUSIC_PATH", environment)

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
                "watchtower",
            ),
        )
        self.assertNotIn("depends_on:", extract_service(compose, "cleanuparr"))
        self.assertNotIn("depends_on:", extract_service(compose, "whisparr"))
        self.assertNotIn("  jellyfin:", compose)
        self.assertNotIn("  plex:", compose)

    def test_whisparr_defaults_to_the_v3_release_channel(self) -> None:
        """Keep Boudoirr on Whisparr v3 instead of hotio's v2 latest tag."""

        environment = render_environment(
            self.catalog,
            self.catalog.resolve("boudoirr"),
            None,
            generate_secrets=False,
        )

        self.assertIn('WHISPARR_TAG="${WHISPARR_TAG:-v3}"', environment)
        self.assertNotIn('WHISPARR_TAG="${WHISPARR_TAG:-latest}"', environment)

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

    def test_watchtower_is_a_removable_automation_preset_default(self) -> None:
        """Default Watchtower in automation presets without making it core."""

        for preset_id in ("plundarr", "boudoirr"):
            with self.subTest(preset=preset_id):
                default = self.catalog.resolve(preset_id)
                removed = self.catalog.resolve(preset_id, remove={"watchtower"})

                self.assertIn("watchtower", default.service_ids)
                self.assertNotIn("watchtower", removed.service_ids)

    def test_calibre_web_automated_is_a_removable_plundarr_default(self) -> None:
        """Default CWA in Plundarr without making the ebook service core."""

        default = self.catalog.resolve("plundarr")
        removed = self.catalog.resolve(
            "plundarr",
            remove={"calibre-web-automated"},
        )

        self.assertIn("calibre-web-automated", default.service_ids)
        self.assertNotIn("calibre-web-automated", removed.service_ids)

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

    def test_duplex_preset_matches_the_live_service_shape(self) -> None:
        """Keep Plex utilities faithful while leaving companions removable."""

        plan = self.catalog.resolve("duplex")
        compose = render_compose(self.catalog, plan)
        environment = render_environment(
            self.catalog,
            plan,
            None,
            generate_secrets=False,
        )

        self.assertEqual(
            plan.service_ids,
            (
                "kometa",
                "imagemaid",
                "pattrmm",
                "tautulli",
                "notifiarr",
                "overlay-reset",
            ),
        )
        self.assertIn("image: kometateam/kometa:${KOMETA_TAG}", compose)
        self.assertIn("image: kometateam/imagemaid:${IMAGE_MAID_TAG}", compose)
        self.assertIn("image: ghcr.io/tautulli/tautulli:${TAUTULLI_TAG}", compose)
        self.assertIn("${KOMETA_CONFIG_PATH}:/config:rw", compose)
        self.assertIn("${IMAGEMAID_PLEX_PATH}:/plex:rw", compose)
        self.assertIn("profiles:\n      - tools", extract_service(compose, "overlay-reset"))
        self.assertNotIn("WATCHTOWER_DOCKER_CONFIG", compose)
        self.assertIn('KOMETA_TAG="${KOMETA_TAG:-latest}"', environment)
        self.assertIn('OVERLAY_RESET_DRY_RUN="${OVERLAY_RESET_DRY_RUN:-True}"', environment)
        self.assertNotIn("  watchtower:", compose)

    def test_duplex_companions_are_removable_but_core_utilities_are_not(self) -> None:
        """Preserve the requested core and default boundary for Duplex."""

        plan = self.catalog.resolve(
            "duplex",
            remove={
                "kometa",
                "imagemaid",
                "pattrmm",
                "tautulli",
                "notifiarr",
                "watchtower",
                "overlay-reset",
            },
        )

        self.assertEqual(plan.service_ids, ("kometa", "imagemaid", "tautulli"))

    def test_standalone_media_server_presets_select_one_core_service(self) -> None:
        """Keep standalone media-server presets deliberately focused."""

        self.assertEqual(self.catalog.resolve("jellyfin").service_ids, ("jellyfin",))
        self.assertEqual(self.catalog.resolve("plex").service_ids, ("plex",))
        self.assertEqual(
            self.catalog.resolve("calibre-web-automated").service_ids,
            ("calibre-web-automated",),
        )
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

    def test_lidarr_and_recyclarr_add_their_integrated_service_chain(
        self,
    ) -> None:
        """Resolve both opt-in services with their integrated dependency edges."""

        plan = self.catalog.resolve(
            "custom",
            selected={"lidarr", "recyclarr"},
        )

        self.assertEqual(
            plan.service_ids,
            (
                "flaresolverr",
                "prowlarr",
                "radarr",
                "sonarr",
                "lidarr",
                "recyclarr",
            ),
        )
        self.assertEqual(
            set(plan.auto_added),
            {"flaresolverr", "prowlarr", "radarr", "sonarr"},
        )

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
        self.assertIn("HOMEPAGE_VAR_CWA_USER", compose)
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

    def test_lidarr_and_recyclarr_render_their_upstream_contracts(self) -> None:
        """Keep music automation and explicit synchronization integration-safe."""

        plan = self.catalog.resolve("plundarr", add={"lidarr", "recyclarr"})
        compose = render_compose(self.catalog, plan)
        environment = render_environment(
            self.catalog,
            plan,
            None,
            generate_secrets=False,
        )
        lidarr = extract_service(compose, "lidarr")
        recyclarr = extract_service(compose, "recyclarr")

        self.assertIn("lscr.io/linuxserver/lidarr:${LIDARR_TAG}", lidarr)
        self.assertIn("${HOST_MUSIC_PATH}:/music:rw", lidarr)
        self.assertIn("http://127.0.0.1:8686/ping", lidarr)
        self.assertIn("prowlarr:\n        condition: service_healthy", lidarr)
        self.assertIn("ghcr.io/recyclarr/recyclarr:${RECYCLARR_TAG}", recyclarr)
        self.assertIn("profiles:\n      - tools", recyclarr)
        self.assertIn("${RECYCLARR_CONFIG_PATH}:/config:rw", recyclarr)
        self.assertNotIn("ports:", recyclarr)
        self.assertIn('RECYCLARR_TAG="${RECYCLARR_TAG:-8}"', environment)
        self.assertIn(
            'HOST_MUSIC_PATH="${HOST_MUSIC_PATH:-/volume1/music/Music/Media/Music}"',
            environment,
        )

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
                "172.20.0.0/16",
                "/volume1/plex",
            ),
            "boudoirr": (
                "boudoirr",
                "172.21.0.0/16",
                "/volume1/jellyfin",
            ),
            "jellyfin": (
                "jellyfin",
                "172.22.0.0/16",
                "/volume1/jellyfin",
            ),
            "plex": (
                "plex",
                "172.23.0.0/16",
                "/volume1/plex",
            ),
            "calibre-web-automated": (
                "calibre-web-automated",
                "172.24.0.0/16",
                "/volume1/books/calibre",
            ),
            "duplex": (
                "duplex",
                "172.25.0.0/16",
                "/volume1/plex",
            ),
            "watchtower": (
                "watchtower",
                "172.27.0.0/16",
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
            "calibre-web-automated",
            "duplex",
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
        self.assertTrue(all(network.is_private for network in networks))
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
        self.assertIn(48213, published_ports["calibre-web-automated"])
        self.assertIn(8213, published_ports["plundarr"])
        self.assertIn(8181, published_ports["duplex"])
        self.assertIn(5454, published_ports["duplex"])
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

    def test_preset_networks_follow_the_documented_private_sequence(self) -> None:
        """Keep preset subnet, pool, and gateway allocations predictable."""

        expected_octets = {
            "plundarr": 20,
            "boudoirr": 21,
            "jellyfin": 22,
            "plex": 23,
            "calibre-web-automated": 24,
            "duplex": 25,
            "watchtower": 27,
            "custom": 28,
        }

        for preset_id, octet in expected_octets.items():
            preset = self.catalog.preset(preset_id)
            with self.subTest(preset=preset_id):
                self.assertEqual(preset.network_subnet, f"172.{octet}.0.0/16")
                self.assertEqual(preset.network_ip_range, f"172.{octet}.5.0/24")
                self.assertEqual(preset.network_gateway, f"172.{octet}.5.254")

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
            add={"jellyfin", "nzbget", "sonarr-anime", "tautulli"},
        )
        homepage = render_homepage_services(self.catalog, plan)

        media_group = homepage[: homepage.index("- Data:")]
        downloads_group = homepage[homepage.index("- Downloads:") :]
        self.assertIn("- Jellyfin:", media_group)
        self.assertIn("- Calibre-Web Automated:", media_group)
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
        self.assertNotIn("HOMEPAGE_VAR_TAUTULLI", compose)
        self.assertNotIn("HOMEPAGE_VAR_CWA", compose)
        self.assertNotIn("HOMEPAGE_VAR_LIDARR", compose)
        self.assertNotIn("HOMEPAGE_VAR_RADARR", environment)
        self.assertNotIn("HOMEPAGE_VAR_PLEX", environment)
        self.assertNotIn("HOMEPAGE_VAR_NZBGET", environment)
        self.assertNotIn("HOMEPAGE_VAR_TAUTULLI", environment)
        self.assertNotIn("HOMEPAGE_VAR_CWA", environment)
        self.assertNotIn("HOMEPAGE_VAR_LIDARR", environment)
        self.assertNotIn("- Radarr:", homepage)
        self.assertNotIn("- Plex:", homepage)
        self.assertNotIn("- NZBGet:", homepage)
        self.assertNotIn("- Tautulli:", homepage)
        self.assertNotIn("- Calibre-Web Automated:", homepage)
        self.assertNotIn("- Lidarr:", homepage)
        self.assertTrue(homepage.endswith("[]\n"))

    def test_homepage_tautulli_card_requires_the_tautulli_service(self) -> None:
        """Do not render a phantom Tautulli card for Plex-only stacks."""

        plex_only = self.catalog.resolve(
            "custom",
            selected={"homepage", "plex"},
        )
        with_tautulli = self.catalog.resolve(
            "custom",
            selected={"homepage", "plex", "tautulli"},
        )

        self.assertNotIn(
            "- Tautulli:",
            render_homepage_services(self.catalog, plex_only),
        )
        tautulli_homepage = render_homepage_services(self.catalog, with_tautulli)
        self.assertIn("- Tautulli:", tautulli_homepage)
        self.assertNotIn("container: tautulli-latest", tautulli_homepage)

    def test_lidarr_homepage_card_and_calendar_follow_selection(self) -> None:
        """Render Lidarr variables, widget, and calendar only with Lidarr."""

        plan = self.catalog.resolve(
            "custom",
            selected={"homepage", "lidarr"},
        )
        compose = render_compose(self.catalog, plan)
        environment = render_environment(
            self.catalog,
            plan,
            None,
            generate_secrets=False,
        )
        homepage_service = extract_service(compose, "homepage")
        homepage = render_homepage_services(self.catalog, plan)

        self.assertIn(
            "HOMEPAGE_VAR_LIDARR_URL: ${HOMEPAGE_VAR_LIDARR_URL}:8686",
            homepage_service,
        )
        self.assertNotIn(
            "HOMEPAGE_VAR_LIDARR_URL: ${HOMEPAGE_VAR_LIDARR_URL}:${LIDARR_WEBUI_PORT}",
            homepage_service,
        )
        self.assertIn(
            'LIDARR_WEBUI_PORT="${LIDARR_WEBUI_PORT:-38686}"',
            environment,
        )
        self.assertIn(
            'HOMEPAGE_VAR_LIDARR_HREF="${HOMEPAGE_VAR_LIDARR_HREF:-http://host.or.ip:38686}"',
            environment,
        )
        self.assertIn("HOMEPAGE_VAR_LIDARR_CONTAINER", compose)
        self.assertIn("HOMEPAGE_VAR_LIDARR_KEY", environment)
        self.assertIn("- Lidarr:", homepage)
        self.assertIn("type: lidarr", homepage)
        self.assertIn("service_name: Lidarr", homepage)
        self.assertNotIn("service_name: Radarr", homepage)
        self.assertNotIn("service_name: Sonarr", homepage)

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
                if service.id == "calibre-web-automated":
                    self.assertIn("\n        - nc\n", compose)
                    self.assertIn("\n        - \"8083\"\n", compose)

        self.assertEqual(shell_healthchecks, set())

    #
    # Media-server selection and generated filesystem behavior.
    #
    def test_calibre_web_automated_keeps_state_mounts_and_updates_explicit(
        self,
    ) -> None:
        """Preserve the upstream CWA storage and internal-port contract."""

        compose = render_compose(
            self.catalog,
            self.catalog.resolve("calibre-web-automated"),
        )
        service = extract_service(compose, "calibre-web-automated")

        self.assertIn("CWA_PORT_OVERRIDE: \"8083\"", service)
        self.assertIn("NETWORK_SHARE_MODE: ${CWA_NETWORK_SHARE_MODE}", service)
        self.assertIn("${CWA_CONFIG_PATH}:/config:rw", service)
        self.assertIn("${CWA_INGEST_PATH}:/cwa-book-ingest:rw", service)
        self.assertIn("${CWA_LIBRARY_PATH}:/calibre-library:rw", service)
        self.assertIn("labels: *disable-watchtower-updates", service)
        self.assertNotIn("\n    user:", service)

    def test_media_servers_are_independent_choices(self) -> None:
        """Allow Plex, Jellyfin, and CWA to be selected together."""

        plan = self.catalog.resolve(
            "custom",
            selected={
                "homepage",
                "jellyfin",
                "plex",
                "calibre-web-automated",
            },
        )

        compose = render_compose(self.catalog, plan)
        homepage = render_homepage_services(self.catalog, plan)

        self.assertIn("  plex:", compose)
        self.assertIn("  jellyfin:", compose)
        self.assertIn("  calibre-web-automated:", compose)
        self.assertIn("network_mode: host", compose)
        self.assertIn("- Plex:", homepage)
        self.assertIn("- Jellyfin:", homepage)
        self.assertIn("- Calibre-Web Automated:", homepage)

    def test_plex_library_mounts_follow_the_selected_preset(self) -> None:
        """Mount only the library set expected by each Plex deployment."""

        cases = {
            "plundarr": ({"movies", "tv", "anime"}, {"scenes", "music"}),
            "boudoirr": ({"movies", "scenes"}, {"tv", "anime", "music"}),
            "plex": ({"movies", "tv"}, {"anime", "scenes", "music"}),
        }
        mounts = {
            "movies": "${HOST_MOVIES_PATH}:/movies:ro",
            "tv": "${HOST_TV_PATH}:/tv:ro",
            "anime": "${HOST_ANIME_TV_PATH}:/anime:ro",
            "scenes": "${HOST_SCENES_PATH}:/scenes:ro",
            "music": "${HOST_MUSIC_PATH}:/music:ro",
        }

        for preset_id, (included, excluded) in cases.items():
            with self.subTest(preset=preset_id):
                plan = self.catalog.resolve(preset_id, add={"plex"})
                plex = extract_service(render_compose(self.catalog, plan), "plex")
                for library in included:
                    self.assertIn(mounts[library], plex)
                for library in excluded:
                    self.assertNotIn(mounts[library], plex)

        plan = self.catalog.resolve("plex", add={"lidarr"})
        plex = extract_service(render_compose(self.catalog, plan), "plex")
        self.assertIn(mounts["music"], plex)

    def test_write_stack_creates_only_selected_config_directories(self) -> None:
        """Create configuration directories only for selected services."""

        plan = self.catalog.resolve(
            "custom",
            selected={
                "homepage",
                "jellyfin",
                "nzbget",
                "qbittorrent",
                "calibre-web-automated",
                "recyclarr",
            },
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
            self.assertTrue(
                (config_path / "calibre-web-automated" / "config").is_dir()
            )
            self.assertTrue(
                (config_path / "calibre-web-automated" / "ingest").is_dir()
            )
            self.assertTrue((config_path / "nzbget" / "README.md").is_file())
            self.assertTrue(
                (config_path / "recyclarr" / "recyclarr.yml").is_file()
            )
            self.assertTrue(
                (
                    config_path
                    / "qbittorrent"
                    / "qBittorrent"
                    / "qBittorrent.conf"
                ).is_file()
            )
            self.assertFalse((config_path / "plex").exists())

    def test_recyclarr_seed_survives_stack_regeneration(self) -> None:
        """Preserve operator-managed Recyclarr rules after their first seed."""

        plan = self.catalog.resolve("custom", selected={"recyclarr"})

        with tempfile.TemporaryDirectory() as temporary_directory:
            output_path = Path(temporary_directory)
            _, _, config_path = write_stack(self.catalog, plan, output_path)
            recyclarr_path = config_path / "recyclarr" / "recyclarr.yml"
            operator_config = "# operator-owned\nradarr: {}\n"
            recyclarr_path.write_text(operator_config)

            write_stack(self.catalog, plan, output_path)

            self.assertEqual(recyclarr_path.read_text(), operator_config)

    def test_duplex_keeps_kometa_external_and_seeds_local_state_only(self) -> None:
        """Leave Kometa external while preparing the other Duplex state roots."""

        plan = self.catalog.resolve("duplex")

        with tempfile.TemporaryDirectory() as temporary_directory:
            _, _, config_path = write_stack(
                self.catalog,
                plan,
                Path(temporary_directory),
            )

            self.assertFalse((config_path / "kometa").exists())
            for service_id in (
                "imagemaid",
                "pattrmm",
                "tautulli",
                "notifiarr",
                "overlay-reset",
            ):
                with self.subTest(service=service_id):
                    self.assertTrue((config_path / service_id / "README.md").is_file())


if __name__ == "__main__":
    unittest.main()
