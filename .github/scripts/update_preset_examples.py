#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# update_preset_examples.py: Refresh only validated preset files on a PR branch.
#

"""Commit validated reference artifacts to a current same-repository PR."""

from __future__ import annotations

import argparse
import json
import os
import re
import urllib.parse
import urllib.request
from collections.abc import Mapping, Sequence
from pathlib import Path
from typing import cast

REFERENCE = re.compile(r"[a-z][a-z0-9-]*/(?:docker-compose\.yml|example\.env)")
PREFIX = "examples/presets/"


def fields(value: object) -> Mapping[str, object]:
    """Validate API object shapes before consuming dynamic response fields."""
    if not isinstance(value, dict):
        raise ValueError("Expected a GitHub API object.")
    return cast(Mapping[str, object], value)


def items(value: object) -> Sequence[object]:
    """Validate API arrays without hiding their element types."""
    if not isinstance(value, list):
        raise ValueError("Expected a GitHub API array.")
    return cast(Sequence[object], value)


class GitHub:
    """Use the job-scoped token without placing credentials in commands or logs."""

    def __init__(self, repository: str) -> None:
        self.repository = repository

    def request(self, endpoint: str, data: object = None, method: str = "GET") -> object:
        """Send one bounded request to the repository's GitHub API."""
        request = urllib.request.Request(
            f"https://api.github.com/repos/{self.repository}/{endpoint}",
            data=None if data is None else json.dumps(data).encode(),
            headers={
                "Authorization": f"Bearer {os.environ['GH_TOKEN']}",
                "Accept": "application/vnd.github+json",
                "Content-Type": "application/json",
                "X-GitHub-Api-Version": "2022-11-28",
            },
            method=method,
        )

        with urllib.request.urlopen(request, timeout=60) as response:
            content = response.read()
            return cast(object, json.loads(content)) if content else None


def references(directory: Path) -> dict[str, str]:
    """Accept only bounded UTF-8 Compose/example pairs from the downloaded artifact."""
    result: dict[str, str] = {}
    total_size = 0

    for path in directory.rglob("*"):
        if path.is_symlink():
            raise ValueError("Reference artifacts must not contain symlinks.")

        if path.is_dir():
            continue

        relative = path.relative_to(directory).as_posix()
        size = path.stat().st_size
        total_size += size

        if REFERENCE.fullmatch(relative) is None or not 0 < size <= 1_000_000:
            raise ValueError("Artifact contains an unexpected reference file.")

        if total_size > 10_000_000 or len(result) >= 200:
            raise ValueError("Reference artifact exceeds its size limit.")

        result[PREFIX + relative] = path.read_text(encoding="utf-8")

    if not result:
        raise ValueError("Reference artifact is empty.")

    for path in result:
        sibling = path.rsplit("/", 1)[0]

        if any(f"{sibling}/{name}" not in result for name in ("docker-compose.yml", "example.env")):
            raise ValueError("Reference artifact contains an incomplete preset pair.")

    return result


def current_pr(api: GitHub, number: int, expected: str) -> Mapping[str, object] | None:
    """Skip closed, forked, redirected, or superseded PRs without writing anything."""
    pull_request = fields(api.request(f"pulls/{number}"))
    head = fields(pull_request["head"])
    base = fields(pull_request["base"])

    if (
        pull_request["state"] != "open"
        or fields(head["repo"])["full_name"] != api.repository
        or base["ref"] != "main"
        or head["ref"] == "main"
        or head["sha"] != expected
    ):
        return None

    return head


def update(api: GitHub, number: int, expected: str, directory: Path) -> None:
    """Create an allowlisted commit and dispatch all required checks on its exact SHA."""
    content = references(directory)
    head = current_pr(api, number, expected)

    if head is None:
        print("PR is no longer eligible for a reference update; skipping.")
        return

    commit = fields(api.request(f"git/commits/{expected}"))
    base_tree = str(fields(commit["tree"])["sha"])
    tree = fields(api.request(f"git/trees/{base_tree}?recursive=1"))

    if tree.get("truncated"):
        raise ValueError("Cannot safely update a truncated repository tree.")

    changes: list[dict[str, object]] = [
        {"path": path, "mode": "100644", "type": "blob", "content": text}
        for path, text in sorted(content.items())
    ]

    for value in items(tree["tree"]):
        entry = fields(value)
        path = str(entry["path"])

        if (
            path.startswith(PREFIX)
            and REFERENCE.fullmatch(path[len(PREFIX) :])
            and path not in content
        ):
            changes.append({"path": path, "mode": "100644", "type": "blob", "sha": None})

    new_tree = fields(api.request("git/trees", {"base_tree": base_tree, "tree": changes}, "POST"))

    if new_tree["sha"] == base_tree:
        print("Preset references are already current.")
        return

    new_commit = fields(
        api.request(
            "git/commits",
            {
                "message": "🗺️ Teach the example fleet its new choreography",
                "tree": new_tree["sha"],
                "parents": [expected],
            },
            "POST",
        )
    )
    new_sha = str(new_commit["sha"])

    # Recheck after object creation; a non-fast-forward update also rejects a later race.
    if current_pr(api, number, expected) is None:
        print("PR changed during reference preparation; skipping.")
        return

    branch = str(head["ref"])
    api.request(
        f"git/refs/heads/{urllib.parse.quote(branch, safe='/')}",
        {"sha": new_sha, "force": False},
        "PATCH",
    )

    # Repository-token pushes do not reliably start all required workflows by themselves.
    # Dispatch both validators explicitly so the final commit receives fresh checks.
    api.request(
        "actions/workflows/validate-pr.yml/dispatches",
        {
            "ref": branch,
            "inputs": {"expected_head_sha": new_sha},
        },
        "POST",
    )
    api.request("actions/workflows/codeql-actions.yml/dispatches", {"ref": branch}, "POST")
    print(f"Updated PR #{number} with validated preset references and dispatched validation.")


def main() -> None:
    """Read trusted workflow metadata and update only the requested PR branch."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repository", required=True)
    parser.add_argument("--pull-request", required=True, type=int)
    parser.add_argument("--expected-head-sha", required=True)
    parser.add_argument("--artifact", required=True, type=Path)
    arguments = parser.parse_args()
    update(
        GitHub(arguments.repository),
        arguments.pull_request,
        arguments.expected_head_sha,
        arguments.artifact,
    )


if __name__ == "__main__":
    main()
