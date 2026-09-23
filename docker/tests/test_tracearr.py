#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# test_tracearr.py: Test monitoring selection and durable generated settings.
#

"""Cover Tracearr dependencies, storage, credentials, and Homepage integration."""

import re
import tempfile
import unittest
from dataclasses import replace
from pathlib import Path
from unittest.mock import patch

from maraudarr.catalog import Catalog, CatalogError
from maraudarr.render import (
    render_compose,
    render_environment,
    render_homepage_services,
    write_stack,
)
from maraudarr.text import extract_service


# Revalidate deliberately mutated models to exercise internal catalog invariants.
class TracearrTests(unittest.TestCase):
    """Verify monitoring behavior independently of external media servers."""

    def setUp(self) -> None:
        """Load an independent catalog for each selection or validation test."""
        self.catalog = Catalog(Path(__file__).resolve().parents[1])

    def test_monitoring_defaults_are_removable_and_portable(self) -> None:
        """Keep Tracearr preferred in Plundarr and both monitors opt-in elsewhere."""
        required = {"tracearr"}
        self.assertTrue(required.issubset(self.catalog.resolve("plundarr").service_ids))
        removed = self.catalog.resolve("plundarr", remove={"tracearr"})
        self.assertTrue(required.isdisjoint(removed.service_ids))
        self.assertNotIn("\nvolumes:\n", render_compose(self.catalog, removed))
        self.assertNotIn(
            "TRACEARR_", render_environment(self.catalog, removed, None, generate_secrets=False)
        )
        for preset in self.catalog.presets:
            if preset != "plundarr":
                with self.subTest(preset=preset):
                    default = self.catalog.resolve(preset, add={"homepage"})
                    self.assertTrue(required.isdisjoint(default.service_ids))
                    self.assertNotIn("tautulli", default.service_ids)
                    added = self.catalog.resolve(preset, add={"tracearr", "tautulli"})
                    self.assertTrue(required.issubset(added.service_ids))
                    self.assertIn("tautulli", added.service_ids)

    def test_named_volumes_follow_selection_without_global_names(self) -> None:
        """Render only selected volume declarations with Compose project scoping."""
        plan = self.catalog.resolve("custom", selected={"tracearr"})
        compose = render_compose(self.catalog, plan)
        footer = compose.split("\nvolumes:\n", 1)[1]
        self.assertEqual(
            re.findall(r"^  ([a-z-]+): \{\}  +#", footer, re.M),
            ["tracearr-db-data", "tracearr-redis-data", "tracearr-backups"],
        )
        self.assertIn(
            "# Tracearr PostgreSQL database containing application state and viewing history",
            footer,
        )
        self.assertIn(
            "# Tracearr Redis queue and cache data, persisted between container restarts", footer
        )
        self.assertIn("# Tracearr backup workspace mounted at /data/backup", footer)
        self.assertNotIn("name:", footer)
        self.assertNotIn("external:", footer)
        self.assertEqual(plan.service_ids, ("tracearr",))
        self.assertEqual(plan.auto_added, ())
        self.assertEqual(
            plan.services[0].compose_services,
            ("tracearr-db", "tracearr-redis", "tracearr"),
        )
        for service_id in plan.services[0].compose_services:
            service = extract_service(compose, service_id)
            if service_id == "tracearr":
                self.assertNotIn("disable-watchtower-updates", service)
            else:
                self.assertIn("labels: *disable-watchtower-updates", service)
            if service_id != "tracearr":
                self.assertNotIn("    ports:", service)
        for service_id in ("tracearr-db", "tracearr-redis"):
            self.assertNotIn(service_id, self.catalog.services)
            with self.assertRaises(CatalogError):
                self.catalog.resolve("custom", selected={service_id})
        self.assertIn("condition: service_healthy", compose)

    def test_catalog_rejects_invalid_and_duplicate_volume_declarations(self) -> None:
        """Catch unsafe volume keys and accidental ownership collisions early."""
        original = self.catalog.services["tracearr"]
        for volumes in (
            {"../outside": "Invalid path."},
            {"data": ""},
            {"data": "First line.\nSecond line."},
        ):
            with self.subTest(volumes=volumes):
                self.catalog.services["tracearr"] = replace(original, named_volumes=volumes)
                with self.assertRaises(CatalogError):
                    self.catalog._validate()  # pyright: ignore[reportPrivateUsage]

        self.catalog.services["tracearr"] = original
        self.catalog.services["homepage"] = replace(
            self.catalog.services["homepage"],
            named_volumes={"tracearr-db-data": "Duplicate storage ownership."},
        )
        with self.assertRaises(CatalogError):
            self.catalog._validate()  # pyright: ignore[reportPrivateUsage]

    def test_catalog_rejects_invalid_compose_groups(self) -> None:
        """Reject incomplete groups and conflicting Compose ownership."""
        original = self.catalog.services["tracearr"]
        groups = (
            (),
            ("tracearr-db",),
            ("tracearr", "missing-container"),
            ("tracearr", "tracearr"),
            ("tracearr", "homepage"),
        )
        for names in groups:
            with self.subTest(names=names):
                self.catalog.services["tracearr"] = replace(original, compose_services=names)
                with self.assertRaises(CatalogError):
                    self.catalog._validate()  # pyright: ignore[reportPrivateUsage]

    def test_secrets_and_existing_state_survive_regeneration(self) -> None:
        """Keep unique credentials private and stable when monitoring is toggled."""
        plan = self.catalog.resolve("custom", selected={"tracearr", "tautulli"})
        with tempfile.TemporaryDirectory() as temporary_directory:
            output = Path(temporary_directory)
            with patch("maraudarr.render.validate_compose"):
                _, env_path, config_path = write_stack(self.catalog, plan, output)
                first = env_path.read_text()
                secrets = dict(
                    re.findall(
                        r'^TRACEARR_(DB_PASSWORD|JWT_SECRET|COOKIE_SECRET|AUTH_SECRET)="([a-f0-9]{64})"$',
                        first,
                        re.M,
                    )
                )
                self.assertEqual(len(secrets), 4)
                self.assertEqual(len(set(secrets.values())), 4)
                example = (output / "example.env").read_text()
                self.assertTrue(all(value not in example for value in secrets.values()))
                self.assertEqual(env_path.stat().st_mode & 0o777, 0o600)
                state = config_path / "tautulli" / "example-state.txt"
                state.write_text("operator-owned application state")
                write_stack(
                    self.catalog, self.catalog.resolve("custom", selected={"homepage"}), output
                )
                write_stack(self.catalog, plan, output)
                regenerated = env_path.read_text()
                for key, value in secrets.items():
                    self.assertIn(f'TRACEARR_{key}="{value}"', regenerated)
                self.assertEqual(state.read_text(), "operator-owned application state")

    def test_homepage_monitor_combinations_and_internal_port(self) -> None:
        """Select each monitor independently and keep widget traffic internal."""
        for monitors in (set[str](), {"tracearr"}, {"tautulli"}, {"tracearr", "tautulli"}):
            with self.subTest(monitors=monitors):
                plan = self.catalog.resolve("custom", selected=monitors | {"homepage"})
                compose = render_compose(self.catalog, plan)
                environment = render_environment(self.catalog, plan, None, generate_secrets=False)
                homepage = render_homepage_services(self.catalog, plan)
                for monitor, label in (("tracearr", "Tracearr"), ("tautulli", "Tautulli")):
                    self.assertEqual(f"- {label}:" in homepage, monitor in monitors)
                    self.assertEqual(
                        f"HOMEPAGE_VAR_{monitor.upper()}_KEY" in compose, monitor in monitors
                    )
                    self.assertEqual(
                        f"HOMEPAGE_VAR_{monitor.upper()}_KEY" in environment, monitor in monitors
                    )
                if "tracearr" in monitors:
                    self.assertIn(
                        "HOMEPAGE_VAR_TRACEARR_URL:-http://tracearr:${TRACEARR_PORT}}", environment
                    )
                    self.assertNotIn("${HOMEPAGE_VAR_TRACEARR_URL}:${TRACEARR_WEBUI_PORT}", compose)
                    self.assertIn("view: summary", homepage)
