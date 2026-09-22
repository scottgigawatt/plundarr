#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# test_vpn_recovery.py: Test generated VPN recovery settings and safe wrapper upgrades.
#

"""Verify recovery defaults, shared authentication, and existing deployment preservation."""

from pathlib import Path
import re
import tempfile
import unittest
from unittest.mock import patch

from maraudarr.catalog import Catalog
from maraudarr.render import render_compose, render_environment, write_config
from maraudarr.text import extract_service


class VpnRecoveryTests(unittest.TestCase):
    """Cover paired VPN selection without starting a tunnel or using PIA credentials."""

    def setUp(self) -> None:
        """Load the service catalog and bundled wrapper paths."""
        self.root = Path(__file__).resolve().parents[1]
        self.catalog = Catalog(self.root)
        self.wrapper_path = Path("gluetun/scripts/gluetun-entrypoint-wrapper.sh")
        self.current_wrapper = self.root / "services/gluetun/config/scripts/gluetun-entrypoint-wrapper.sh"
        self.previous_wrapper = self.root / "tests/fixtures/gluetun-legacy/gluetun-entrypoint-wrapper.sh"

    def test_defaults_follow_resolved_services_for_every_preset(self) -> None:
        """Enable paired recovery, including dependencies, but leave standalone generation off."""
        for preset in self.catalog.presets:
            for added in ({"homepage"}, {"privateerr"}, {"gluetun"}, {"qbittorrent"}):
                with self.subTest(preset=preset, added=added):
                    plan = self.catalog.resolve(preset, add=added)
                    environment = render_environment(self.catalog, plan, None, generate_secrets=False)
                    compose = render_compose(self.catalog, plan)
                    if "privateerr" not in plan.service_ids:
                        self.assertNotIn("PRIVATEERR_AUTO_RECOVER", environment)
                        self.assertNotIn("PRIVATEERR_GLUETUN_API_KEY", environment)
                        continue

                    enabled = "true" if "gluetun" in plan.service_ids else "false"
                    self.assertIn(f'PRIVATEERR_AUTO_RECOVER="${{PRIVATEERR_AUTO_RECOVER:-{enabled}}}"', environment)
                    self.assertIn('PRIVATEERR_GENERATION_TIMEOUT_SECONDS="${PRIVATEERR_GENERATION_TIMEOUT_SECONDS:-180}"', environment)
                    privateerr = extract_service(compose, "privateerr")
                    for name in ("PRIVATEERR_AUTO_RECOVER", "PRIVATEERR_GLUETUN_API_KEY", "PRIVATEERR_GENERATION_TIMEOUT_SECONDS"):
                        self.assertIn(f"{name}: ${{{name}}}", privateerr)
                    if "gluetun" not in plan.service_ids:
                        continue

                    gluetun = extract_service(compose, "gluetun")
                    self.assertIn("PRIVATEERR_AUTO_RECOVER: ${PRIVATEERR_AUTO_RECOVER}", gluetun)
                    self.assertIn("PRIVATEERR_GLUETUN_API_KEY: ${PRIVATEERR_GLUETUN_API_KEY}", gluetun)
                    self.assertIn("condition: service_healthy", gluetun)
                    self.assertNotRegex(gluetun, re.compile(r"^ {6}-[^\n]*:(8000|9999)(?:\s|$)", re.MULTILINE))
                    if "qbittorrent" in plan.service_ids:
                        self.assertIn("VPN_PORT_FORWARDING_UP_COMMAND:", gluetun)
                        self.assertIn("VPN_PORT_FORWARDING_DOWN_COMMAND:", gluetun)

    def test_key_is_generated_once_and_not_written_to_examples(self) -> None:
        """Give deployments distinct API keys without rotating a saved key or opt-out."""
        plan = self.catalog.resolve("custom", add={"gluetun"})
        first = render_environment(self.catalog, plan, None)
        second = render_environment(self.catalog, plan, None)
        pattern = r'^PRIVATEERR_GLUETUN_API_KEY="([a-f0-9]{64})"$'
        first_match = re.search(pattern, first, re.MULTILINE)
        second_match = re.search(pattern, second, re.MULTILINE)
        self.assertIsNotNone(first_match)
        self.assertIsNotNone(second_match)
        self.assertNotEqual(first_match.group(1), second_match.group(1))

        example = render_environment(self.catalog, plan, None, generate_secrets=False)
        self.assertIn('PRIVATEERR_GLUETUN_API_KEY="${PRIVATEERR_GLUETUN_API_KEY:-}"', example)
        self.assertNotIn(first_match.group(1), example)

        # Exercise secret preservation in memory instead of persisting generated credentials.
        existing = {line.split("=", 1)[0]: line for line in first.splitlines() if re.match(r"^[A-Z_]+=", line)}
        overrides = {
            "PRIVATEERR_AUTO_RECOVER": 'PRIVATEERR_AUTO_RECOVER="false"',
            "PRIVATEERR_RECOVERY_INTERVAL_SECONDS": 'PRIVATEERR_RECOVERY_INTERVAL_SECONDS="45"',
            "PRIVATEERR_RECOVERY_FAILURE_SECONDS": 'PRIVATEERR_RECOVERY_FAILURE_SECONDS="180"',
            "PRIVATEERR_RECOVERY_COOLDOWN_SECONDS": 'PRIVATEERR_RECOVERY_COOLDOWN_SECONDS="600"',
            "PRIVATEERR_GENERATION_TIMEOUT_SECONDS": 'PRIVATEERR_GENERATION_TIMEOUT_SECONDS="240"',
            "PRIVATEERR_TAG": 'PRIVATEERR_TAG="operator-pinned"',
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
            original = 'PIA_AUTOCONNECT="false"\nPIA_PREFERRED_REGION="ca_toronto"\n'
            path.write_text(original)
            environment = render_environment(self.catalog, plan, path)
        for assignment in original.splitlines():
            self.assertIn(assignment, environment)
        self.assertIn('PRIVATEERR_AUTO_RECOVER="${PRIVATEERR_AUTO_RECOVER:-true}"', environment)
        self.assertRegex(environment, r'(?m)^PRIVATEERR_GLUETUN_API_KEY="[a-f0-9]{64}"$')

    def test_wrapper_upgrade_preserves_customizations_and_runtime_state(self) -> None:
        """Upgrade the exact legacy seed and leave custom wrappers, auth, and VPN state alone."""
        plan = self.catalog.resolve("custom", add={"gluetun"})
        for customized in (False, True):
            with self.subTest(customized=customized), tempfile.TemporaryDirectory() as temporary:
                output = Path(temporary)
                wrapper = output / "config" / self.wrapper_path
                wrapper.parent.mkdir(parents=True)
                previous = self.previous_wrapper.read_text()
                if customized:
                    previous += "\n# Operator customization.\n"
                wrapper.write_text(previous)
                auth = output / "config/gluetun/auth/config.toml"
                auth.parent.mkdir()
                auth.write_text("# Operator-managed authentication.\n")
                state = output / "config/gluetun/wireguard/wg0.conf"
                state.parent.mkdir()
                state.write_text("# Operator-managed WireGuard state.\n")

                write_config(self.catalog, plan, output)
                expected = previous if customized else self.current_wrapper.read_text()
                self.assertEqual(wrapper.read_text(), expected)
                self.assertEqual(auth.read_text(), "# Operator-managed authentication.\n")
                self.assertEqual(state.read_text(), "# Operator-managed WireGuard state.\n")
                write_config(self.catalog, plan, output)
                self.assertEqual(wrapper.read_text(), expected)

    def test_fresh_wrapper_is_seeded_and_symlink_is_preserved(self) -> None:
        """Install the new wrapper on first generation without replacing linked operator files."""
        plan = self.catalog.resolve("custom", add={"gluetun"})
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary)
            write_config(self.catalog, plan, output)
            wrapper = output / "config" / self.wrapper_path
            self.assertEqual(wrapper.read_text(), self.current_wrapper.read_text())
            self.assertTrue(wrapper.stat().st_mode & 0o100)
            wrapper.unlink()
            external = output / "operator-wrapper.sh"
            external.write_text(self.previous_wrapper.read_text())
            wrapper.symlink_to(external)
            write_config(self.catalog, plan, output)
            self.assertTrue(wrapper.is_symlink())
            self.assertEqual(external.read_text(), self.previous_wrapper.read_text())
