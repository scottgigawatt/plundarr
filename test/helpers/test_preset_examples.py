#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# test_preset_examples.py: Verify snapshot safety and restricted PR update behavior.
#

"""Exercise reference publication and GitHub writes without contacting external services."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import update_preset_examples as updater
from scripts.compose import preset_examples as generator


class FakeGitHub(updater.GitHub):
    """Record API requests and simulate a PR advancing during preparation."""

    def __init__(self, *, fork: bool = False, stale: bool = False, unchanged: bool = False) -> None:
        super().__init__("owner/plundarr")
        self.calls: list[tuple[str, object, str]] = []
        self.fork = fork
        self.stale = stale
        self.unchanged = unchanged
        self.pr_reads = 0

    def request(self, endpoint: str, data: object = None, method: str = "GET") -> object:
        self.calls.append((endpoint, data, method))

        if endpoint == "pulls/42":
            self.pr_reads += 1
            return {
                "state": "open",
                "base": {"ref": "main"},
                "head": {
                    "sha": "later" if self.stale and self.pr_reads > 1 else "original",
                    "ref": "wee/example",
                    "repo": {"full_name": "fork/plundarr" if self.fork else self.repository},
                },
            }

        if endpoint == "git/commits/original":
            return {"tree": {"sha": "base-tree"}}

        if endpoint == "git/trees/base-tree?recursive=1":
            return {
                "truncated": False,
                "tree": [
                    {"path": "examples/presets/retired/docker-compose.yml"},
                    {"path": "examples/presets/retired/example.env"},
                    {"path": "examples/presets/README.md"},
                    {"path": "dist/plundarr/.env"},
                ],
            }

        if endpoint == "git/trees":
            return {"sha": "base-tree" if self.unchanged else "new-tree"}

        if endpoint == "git/commits":
            return {"sha": "new-commit"}

        return None


class PresetReferenceTests(unittest.TestCase):
    """Keep private state and failed generations out of public references."""

    def test_publish_preserves_unmanaged_files_and_removes_retired_pairs(self) -> None:
        """Only the managed pair is replaced or removed, including for retired presets."""
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            generator.publish(
                directory, {"retired/docker-compose.yml": b"old", "retired/example.env": b"old"}
            )
            private = directory / "retired/.env"
            private.write_text("private")
            (directory / "README.md").write_text("reference index")
            expected = {"custom/docker-compose.yml": b"new", "custom/example.env": b"safe"}

            generator.publish(directory, expected)

            self.assertEqual(generator.read_references(directory), expected)
            self.assertEqual(private.read_text(), "private")
            self.assertEqual((directory / "README.md").read_text(), "reference index")

    def test_generation_failure_does_not_replace_existing_references(self) -> None:
        """A failing container leaves the last validated reference unchanged."""
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            original = {"custom/docker-compose.yml": b"original", "custom/example.env": b"original"}
            generator.publish(directory, original)

            with (
                patch.object(generator, "generate", side_effect=ValueError("container failure")),
                patch(
                    "sys.argv",
                    ["preset_examples.py", "--image", "test", "--output-root", str(directory)],
                ),
                self.assertRaisesRegex(ValueError, "container failure"),
            ):
                generator.main()

            self.assertEqual(generator.read_references(directory), original)

    def test_custom_selection_and_determinism(self) -> None:
        """The custom example stays minimal and differing fresh output is rejected."""
        calls: list[list[str]] = []

        def container(image: str, arguments: list[str], output: Path | None = None) -> str:
            del image

            if output is None:
                return "custom\n"

            calls.append(arguments)
            project = output / "custom"
            project.mkdir()
            (project / "docker-compose.yml").write_text("services: {}\n")
            (project / "example.env").write_text(f"CHANGED={len(calls)}\n")
            return ""

        with (
            tempfile.TemporaryDirectory() as temporary,
            patch.object(generator, "container", side_effect=container),
            patch.object(generator, "run"),
            self.assertRaisesRegex(ValueError, "not deterministic"),
        ):
            generator.generate("test", Path(temporary))

        self.assertEqual(len(calls), 2)
        self.assertIn(generator.CUSTOM_SERVICES, calls[0])
        self.assertEqual(
            set(generator.CUSTOM_SERVICES.split(",")),
            {
                "privateerr",
                "gluetun",
                "qbittorrent",
                "prowlarr",
                "radarr",
                "sonarr",
                "sonarr-anime",
            },
        )

    def test_publish_rejects_symlinked_destination(self) -> None:
        """A reference directory cannot redirect publication into a deployment."""
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            (directory / "custom").symlink_to(directory, target_is_directory=True)

            with self.assertRaisesRegex(ValueError, "symlinks"):
                generator.publish(directory, {"custom/example.env": b"safe"})


class ReferenceUpdaterTests(unittest.TestCase):
    """Restrict bot commits to public pairs on the unchanged PR branch."""

    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        generator.publish(
            self.directory,
            {
                "custom/docker-compose.yml": b"services: {}\n",
                "custom/example.env": b"EXAMPLE=true\n",
            },
        )

    def test_rejects_private_files_and_incomplete_pairs(self) -> None:
        """Artifacts cannot smuggle deployment state or partial reference sets into Git."""
        private = self.directory / "custom/.env"
        private.write_text("private")

        with self.assertRaisesRegex(ValueError, "unexpected"):
            updater.references(self.directory)

        private.unlink()
        (self.directory / "custom/example.env").unlink()

        with self.assertRaisesRegex(ValueError, "incomplete"):
            updater.references(self.directory)

    def test_update_restricts_paths_and_dispatches_both_required_workflows(self) -> None:
        """One non-forced commit updates the exact head and receives both validation suites."""
        api = FakeGitHub()
        updater.update(api, 42, "original", self.directory)
        tree_request = next(data for endpoint, data, _ in api.calls if endpoint == "git/trees")
        changes = updater.items(updater.fields(tree_request)["tree"])
        paths = {str(updater.fields(change)["path"]) for change in changes}
        self.assertEqual(
            paths,
            {
                "examples/presets/custom/docker-compose.yml",
                "examples/presets/custom/example.env",
                "examples/presets/retired/docker-compose.yml",
                "examples/presets/retired/example.env",
            },
        )
        self.assertIn(
            ("git/refs/heads/wee/example", {"sha": "new-commit", "force": False}, "PATCH"),
            api.calls,
        )
        self.assertIn(
            (
                "actions/workflows/validate-pr.yml/dispatches",
                {
                    "ref": "wee/example",
                    "inputs": {"expected_head_sha": "new-commit"},
                },
                "POST",
            ),
            api.calls,
        )
        self.assertIn(
            ("actions/workflows/codeql-actions.yml/dispatches", {"ref": "wee/example"}, "POST"),
            api.calls,
        )

    def test_fork_and_concurrent_changes_never_update_branch(self) -> None:
        """Forked or superseded PRs must not receive a bot branch update."""
        for api in (FakeGitHub(fork=True), FakeGitHub(stale=True)):
            with self.subTest(fork=api.fork, stale=api.stale):
                updater.update(api, 42, "original", self.directory)
                self.assertFalse(any(method == "PATCH" for _, _, method in api.calls))
                self.assertFalse(any("dispatches" in endpoint for endpoint, _, _ in api.calls))

    def test_identical_tree_never_commits_or_dispatches(self) -> None:
        """A no-op refresh cannot create a recursive commit loop."""
        api = FakeGitHub(unchanged=True)
        updater.update(api, 42, "original", self.directory)
        self.assertFalse(any(endpoint == "git/commits" for endpoint, _, _ in api.calls))
        self.assertFalse(any("dispatches" in endpoint for endpoint, _, _ in api.calls))


if __name__ == "__main__":
    unittest.main()
