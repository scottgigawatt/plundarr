#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# test_vpn_recovery.py: Test generated VPN recovery settings and image-owned script handoff.
#

"""Verify recovery defaults, shared authentication, and existing deployment preservation."""

import re
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from maraudarr.catalog import Catalog
from maraudarr.render import render_compose, render_environment, write_config
from maraudarr.text import extract_service


class VpnRecoveryTests(unittest.TestCase):
    """Cover paired VPN selection without starting a tunnel or using PIA credentials."""

    def setUp(self) -> None:
        """Load the service catalog for generated VPN deployments."""

        self.root = Path(__file__).resolve().parents[1]
        self.catalog = Catalog(self.root)

    def test_defaults_follow_resolved_services_for_every_preset(self) -> None:
        """Enable paired recovery, including dependencies, but leave standalone generation off."""

        # Resolve explicit selections and their dependencies across every preset, including core services.
        for preset in self.catalog.presets:
            for added in ({"homepage"}, {"privateerr"}, {"gluetun"}, {"qbittorrent"}):
                with self.subTest(preset=preset, added=added):
                    plan = self.catalog.resolve(preset, add=added)
                    environment = render_environment(
                        self.catalog, plan, None, generate_secrets=False
                    )
                    compose = render_compose(self.catalog, plan)

                    # Stacks without Privateerr must not acquire unused recovery variables.
                    if "privateerr" not in plan.service_ids:
                        self.assertNotIn("PRIVATEERR_AUTO_RECOVER", environment)
                        self.assertNotIn("PRIVATEERR_GLUETUN_API_KEY", environment)
                        continue

                    enabled = "true" if "gluetun" in plan.service_ids else "false"
                    self.assertIn(
                        f'PRIVATEERR_AUTO_RECOVER="${{PRIVATEERR_AUTO_RECOVER:-{enabled}}}"',
                        environment,
                    )
                    self.assertIn(
                        'PRIVATEERR_GENERATION_TIMEOUT_SECONDS="${PRIVATEERR_GENERATION_TIMEOUT_SECONDS:-180}"',
                        environment,
                    )

                    # Check privilege removal and Docker-owned IPv6 policy independently of recovery mode.
                    privateerr = extract_service(compose, "privateerr")
                    self.assertNotIn("privileged:", privateerr)
                    self.assertIn("- *security-hardening", privateerr)
                    self.assertRegex(compose, r"(?m)^  cap_drop:.*\n    - ALL(?: +#.*)?$")
                    self.assertIn("no-new-privileges:true", compose)

                    for setting in ("all", "default"):
                        self.assertIn(
                            f"net.ipv6.conf.{setting}.disable_ipv6: ${{PRIVATEERR_IPV6_DISABLED}}",
                            privateerr,
                        )

                    self.assertIn(
                        'PRIVATEERR_IPV6_DISABLED="${PRIVATEERR_IPV6_DISABLED:-1}"', environment
                    )

                    for name in (
                        "PRIVATEERR_AUTO_RECOVER",
                        "PRIVATEERR_GLUETUN_API_KEY",
                        "PRIVATEERR_GENERATION_TIMEOUT_SECONDS",
                    ):
                        self.assertIn(f"{name}: ${{{name}}}", privateerr)

                    if "gluetun" not in plan.service_ids:
                        continue

                    # Paired services share authentication while control and health ports remain internal.
                    gluetun = extract_service(compose, "gluetun")
                    self.assertIn("PRIVATEERR_AUTO_RECOVER: ${PRIVATEERR_AUTO_RECOVER}", gluetun)
                    self.assertIn(
                        "PRIVATEERR_GLUETUN_API_KEY: ${PRIVATEERR_GLUETUN_API_KEY}", gluetun
                    )
                    self.assertIn("condition: service_healthy", gluetun)
                    self.assertIn(
                        'GLUETUN_ENTRYPOINT_WRAPPER="${GLUETUN_ENTRYPOINT_WRAPPER:-/gluetun/scripts/gluetun-entrypoint-wrapper.sh}"',
                        environment,
                    )
                    self.assertNotIn("GLUETUN_WRAPPER_SCRIPT_PATH", compose)
                    self.assertNotIn("GLUETUN_WRAPPER_SCRIPT_PATH", environment)
                    self.assertNotRegex(
                        gluetun, re.compile(r"^ {6}-[^\n]*:(8000|9999)(?:\s|$)", re.MULTILINE)
                    )

                    if "qbittorrent" in plan.service_ids:
                        application = extract_service(compose, "qbittorrent")
                        self.assertIn("network_mode: service:gluetun", application)
                        self.assertRegex(
                            application,
                            r"(?s)depends_on:\s+gluetun:.*condition: service_healthy.*restart: true",
                        )
                        self.assertIn("VPN_PORT_FORWARDING_UP_COMMAND:", gluetun)
                        self.assertIn("VPN_PORT_FORWARDING_DOWN_COMMAND:", gluetun)

                        # The listener, mapping, healthcheck, and API must follow a changed Web UI port.
                        self.assertIn("WEBUI_PORT: ${QBITTORRENT_WEBUI_PORT}", application)
                        self.assertIn("http://127.0.0.1:${QBITTORRENT_WEBUI_PORT}/", application)
                        self.assertIn(
                            "${QBITTORRENT_WEBUI_PORT}:${QBITTORRENT_WEBUI_PORT}", gluetun
                        )
                        self.assertIn("QBITTORRENT_API_URL: ${QBITTORRENT_API_URL}", gluetun)
                        self.assertIn("QBITTORRENT_PORT_SYNC: ${QBITTORRENT_PORT_SYNC}", gluetun)
                        self.assertIn(
                            "QBITTORRENT_API_WAIT_SECONDS: ${QBITTORRENT_API_WAIT_SECONDS}", gluetun
                        )
                        self.assertNotIn("QBITTORRENT_TCP_PORT", environment)
                        self.assertNotIn("QBITTORRENT_UDP_PORT", environment)
                    else:
                        self.assertNotIn("QBITTORRENT_API_URL", gluetun)
                        self.assertNotIn("QBITTORRENT_PORT_SYNC", gluetun)

    def test_key_is_generated_once_and_not_written_to_examples(self) -> None:
        """Give deployments distinct API keys without rotating a saved key or opt-out."""

        plan = self.catalog.resolve("custom", add={"gluetun"})
        first = render_environment(self.catalog, plan, None)

        # Two new deployments must not share a generated control API key.
        second = render_environment(self.catalog, plan, None)
        pattern = r'^PRIVATEERR_GLUETUN_API_KEY="([a-f0-9]{64})"$'
        first_match = re.search(pattern, first, re.MULTILINE)
        second_match = re.search(pattern, second, re.MULTILINE)
        assert first_match is not None
        assert second_match is not None
        self.assertNotEqual(first_match.group(1), second_match.group(1))

        # Public examples retain an empty placeholder instead of a usable credential.
        example = render_environment(self.catalog, plan, None, generate_secrets=False)
        self.assertIn('PRIVATEERR_GLUETUN_API_KEY="${PRIVATEERR_GLUETUN_API_KEY:-}"', example)
        self.assertNotIn(first_match.group(1), example)

        # Exercise secret preservation in memory instead of persisting generated credentials.
        existing = {
            line.split("=", 1)[0]: line
            for line in first.splitlines()
            if re.match(r"^[A-Z_]+=", line)
        }

        # Regeneration must preserve an existing key, explicit opt-out, timers, and image pin.
        overrides = {
            "PRIVATEERR_AUTO_RECOVER": 'PRIVATEERR_AUTO_RECOVER="false"',
            "PRIVATEERR_RECOVERY_INTERVAL_SECONDS": 'PRIVATEERR_RECOVERY_INTERVAL_SECONDS="45"',
            "PRIVATEERR_RECOVERY_FAILURE_SECONDS": 'PRIVATEERR_RECOVERY_FAILURE_SECONDS="180"',
            "PRIVATEERR_RECOVERY_COOLDOWN_SECONDS": 'PRIVATEERR_RECOVERY_COOLDOWN_SECONDS="600"',
            "PRIVATEERR_GENERATION_TIMEOUT_SECONDS": 'PRIVATEERR_GENERATION_TIMEOUT_SECONDS="240"',
            "PRIVATEERR_TAG": 'PRIVATEERR_TAG="operator-pinned"',
            "GLUETUN_ENTRYPOINT_WRAPPER": 'GLUETUN_ENTRYPOINT_WRAPPER="/gluetun/scripts/operator-wrapper.sh"',
        }
        existing.update(overrides)

        with patch("maraudarr.render._existing_values", return_value=existing):
            regenerated = render_environment(self.catalog, plan, Path("unused.env"))

        self.assertIn(first_match.group(0), regenerated)

        for assignment in overrides.values():
            self.assertIn(assignment, regenerated)

    def test_existing_environment_gains_recovery_without_changing_pia_settings(self) -> None:
        """Add new settings to an older deployment while keeping its selected region."""

        plan = self.catalog.resolve("plundarr")

        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / ".env"
            original = 'PIA_AUTOCONNECT="false"\nPIA_PREFERRED_REGION="ca_toronto"\nPIA_DISABLE_IPV6="yes"\n'
            path.write_text(original)
            environment = render_environment(self.catalog, plan, path)

        for assignment in original.splitlines():
            self.assertIn(assignment, environment)

        self.assertIn('PRIVATEERR_AUTO_RECOVER="${PRIVATEERR_AUTO_RECOVER:-true}"', environment)
        self.assertRegex(environment, r'(?m)^PRIVATEERR_GLUETUN_API_KEY="[a-f0-9]{64}"$')

    def test_config_generation_leaves_runtime_scripts_and_state_untouched(self) -> None:
        """Privateerr owns script publication; Maraudarr must preserve mounted runtime files."""

        plan = self.catalog.resolve("custom", add={"gluetun"})

        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary)
            write_config(self.catalog, plan, output)
            config = output / "config/gluetun"

            # A fresh project must wait for the selected Privateerr image to install its scripts.
            self.assertFalse((config / "scripts").exists())
            files = (
                "scripts/gluetun-entrypoint-wrapper.sh",
                "scripts/qbittorrent-port-forwarding.sh",
                "auth/config.toml",
                "wireguard/wg0.conf",
                "wireguard/.privateerr-pending/metadata",
                "wireguard/.privateerr-commit/metadata",
            )

            for name in files:
                path = config / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("# Existing runtime state.\n")

            write_config(self.catalog, plan, output)

            for name in files:
                self.assertEqual((config / name).read_text(), "# Existing runtime state.\n")

    def test_config_generation_preserves_linked_operator_files(self) -> None:
        """Seeding must not follow an existing script symlink and overwrite its target."""

        plan = self.catalog.resolve("custom", add={"gluetun"})

        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary)
            scripts = output / "config/gluetun/scripts"
            scripts.mkdir(parents=True)
            external = output / "operator-wrapper.sh"
            external.write_text("# Operator-owned script.\n")
            wrapper = scripts / "gluetun-entrypoint-wrapper.sh"
            wrapper.symlink_to(external)

            write_config(self.catalog, plan, output)

            self.assertTrue(wrapper.is_symlink())
            self.assertEqual(external.read_text(), "# Operator-owned script.\n")
