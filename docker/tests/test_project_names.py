#
# Copyright 2025-2026 Scott Gigawatt
#
# SPDX-License-Identifier: Apache-2.0
#
# test_project_names.py: Preserve explicit Compose project identity across generation.
#

"""Keep source charts, preset output, and operator project names consistent."""

from __future__ import annotations

import re
import tempfile
import unittest
from pathlib import Path

from maraudarr.catalog import Catalog
from maraudarr.render import render_compose, render_environment

PROJECT_NAME_BLOCK = (
    "#\n# Define the project name for this stack.\n#\nname: ${COMPOSE_PROJECT_NAME}\n"
)
SERVICES_BLOCK = "#\n# Define the services section.\n#\nservices:\n"


class ProjectNameTests(unittest.TestCase):
    """Prevent source assembly from dropping or duplicating Compose project names."""

    @classmethod
    def setUpClass(cls) -> None:
        """Use the maintained catalog and source charts for every identity check."""

        cls.catalog = Catalog(Path(__file__).resolve().parents[1])
        cls.repository_root = cls.catalog.root.parent

    def assert_project_name_block(
        self, compose: str, *, require_services_heading: bool = True
    ) -> None:
        """Require one unresolved root name immediately before the services section."""

        self.assertEqual(
            re.findall(r"^name:.*$", compose, flags=re.MULTILINE),
            ["name: ${COMPOSE_PROJECT_NAME}"],
        )
        self.assertEqual(compose.count(PROJECT_NAME_BLOCK), 1)
        services_blocks = (
            (SERVICES_BLOCK,)
            if require_services_heading
            else (
                SERVICES_BLOCK,
                "services:\n",
            )
        )
        self.assertTrue(
            any(f"\n\n{PROJECT_NAME_BLOCK}\n{services}" in compose for services in services_blocks),
            "Project name block must directly precede the services section with blank lines.",
        )

    def test_every_preset_renders_one_explicit_project_name(self) -> None:
        """Combine many source fragments without duplicating their root name keys."""

        for preset_id in self.catalog.presets:
            with self.subTest(preset=preset_id):
                plan = self.catalog.resolve(
                    preset_id,
                    add={"homepage"} if preset_id == "custom" else None,
                )
                self.assert_project_name_block(render_compose(self.catalog, plan))

        # Selecting every logical service also exercises charts absent from preset defaults.
        all_services = self.catalog.resolve("custom", selected=set(self.catalog.services))
        self.assert_project_name_block(render_compose(self.catalog, all_services))

    def test_maintained_compose_sources_keep_the_project_name_block(self) -> None:
        """Keep standalone source charts and public references consistent with output."""

        reference_root = self.repository_root / "examples/presets"
        references = sorted(reference_root.glob("*/docker-compose.yml"))
        self.assertEqual(
            {path.parent.name for path in references},
            set(self.catalog.presets),
        )
        sources = [
            self.catalog.root / "templates/compose.yml",
            self.repository_root / "docker-compose.maraudarr.yml",
            self.repository_root / "docs/demo/docker-compose.demo.yml",
            *sorted((self.catalog.root / "services").glob("*/compose.yml")),
            *references,
        ]

        for source in sources:
            with self.subTest(source=source.relative_to(self.repository_root)):
                self.assert_project_name_block(source.read_text(), require_services_heading=False)

    def test_operator_project_name_survives_preset_environment_rendering(self) -> None:
        """Keep operator identity authoritative while Compose defers interpolation."""

        with tempfile.TemporaryDirectory() as temporary:
            environment_path = Path(temporary) / ".env"

            for preset_id in self.catalog.presets:
                with self.subTest(preset=preset_id):
                    plan = self.catalog.resolve(
                        preset_id,
                        add={"homepage"} if preset_id == "custom" else None,
                    )
                    assignment = f'COMPOSE_PROJECT_NAME="operator-{preset_id}"'
                    environment_path.write_text(f"{assignment}\n")

                    environment = render_environment(
                        self.catalog,
                        plan,
                        environment_path,
                        generate_secrets=False,
                    )
                    compose = render_compose(self.catalog, plan)

                    self.assertEqual(
                        re.findall(r"^COMPOSE_PROJECT_NAME=.*$", environment, flags=re.MULTILINE),
                        [assignment],
                    )
                    self.assert_project_name_block(compose)
                    self.assertNotIn(f"name: {plan.preset.project_name}\n", compose)
                    self.assertNotIn(f"name: operator-{preset_id}\n", compose)


if __name__ == "__main__":
    unittest.main()
