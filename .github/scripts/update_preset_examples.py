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

# Bound artifact uploads to public pairs that fit in one Git tree request.
REFERENCE = re.compile(r"[a-z][a-z0-9-]*/(?:docker-compose\.yml|example\.env)")
PREFIX = "examples/presets/"
MAX_REFERENCE_BYTES = 1_000_000
MAX_ARTIFACT_BYTES = 10_000_000
MAX_REFERENCE_FILES = 200


def fields(value: object) -> Mapping[str, object]:
    """Validate API object shapes before consuming dynamic response fields."""

    if not isinstance(value, dict):
        raise ValueError("Expected a GitHub API object.")

    # JSON object keys are strings; reject malformed injected values at the same boundary.
    mapping = cast(Mapping[object, object], value)

    if any(not isinstance(key, str) for key in mapping):
        raise ValueError("Expected string keys in a GitHub API object.")

    return cast(Mapping[str, object], mapping)


def api_string(value: object) -> str:
    """Require a nonempty API string without converting malformed values to text."""

    if not isinstance(value, str) or not value:
        raise ValueError("Expected a nonempty GitHub API string.")

    return value


def items(value: object) -> Sequence[object]:
    """Validate API arrays without hiding their element types."""

    if not isinstance(value, list):
        raise ValueError("Expected a GitHub API array.")

    return cast(Sequence[object], value)


class GitHub:
    """Use the job-scoped token without placing credentials in commands or logs."""

    def __init__(self, repository: str) -> None:
        """Bind API calls to the repository supplied by trusted workflow metadata."""

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

    if directory.is_symlink() or not directory.is_dir():
        raise ValueError("The reference artifact root must be a real directory, not a symlink.")

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

        if REFERENCE.fullmatch(relative) is None or not 0 < size <= MAX_REFERENCE_BYTES:
            raise ValueError("Artifact contains an unexpected reference file.")

        if total_size > MAX_ARTIFACT_BYTES or len(result) >= MAX_REFERENCE_FILES:
            raise ValueError("Reference artifact exceeds its size limit.")

        result[PREFIX + relative] = path.read_bytes().decode("utf-8")

    if not result:
        raise ValueError("Reference artifact is empty.")

    for path in result:
        sibling = path.rsplit("/", 1)[0]

        if any(f"{sibling}/{name}" not in result for name in ("docker-compose.yml", "example.env")):
            raise ValueError("Reference artifact contains an incomplete preset pair.")

    return result


def current_pr_branch(api: GitHub, number: int, expected: str) -> str | None:
    """Return the unchanged eligible PR branch, or None when an update must be skipped.

    Closed PRs and deleted fork repositories are ordinary skip conditions. Only an
    open same-repository PR targeting main may receive a reference commit.
    """

    pull_request = fields(api.request(f"pulls/{number}"))

    if pull_request["state"] != "open":
        return None

    head = fields(pull_request["head"])
    base = fields(pull_request["base"])
    repository = head["repo"]

    if repository is None or fields(repository)["full_name"] != api.repository:
        return None

    branch = api_string(head["ref"])

    if api_string(base["ref"]) != "main" or branch == "main" or api_string(head["sha"]) != expected:
        return None

    return branch


def update(api: GitHub, number: int, expected: str, directory: Path) -> None:
    """Commit public reference pairs to the unchanged PR branch and start validation.

    The second head check and non-forced ref update prevent overwriting concurrent
    contributor changes. Validation is dispatched only after the branch update succeeds.

    Args:
        api: Repository-bound API client carrying the job-scoped token.
        number: Pull request supplied by trusted workflow metadata.
        expected: PR head commit that produced the validated artifact.
        directory: Downloaded artifact containing only public reference pairs.
    """

    content = references(directory)
    branch = current_pr_branch(api, number, expected)

    if branch is None:
        print("PR is no longer eligible for a reference update; skipping.")
        return

    commit = fields(api.request(f"git/commits/{expected}"))
    base_tree = api_string(fields(commit["tree"])["sha"])
    tree = fields(api.request(f"git/trees/{base_tree}?recursive=1"))

    if tree.get("truncated"):
        raise ValueError("Cannot safely update a truncated repository tree.")

    changes: list[dict[str, object]] = [
        {"path": path, "mode": "100644", "type": "blob", "content": text}
        for path, text in sorted(content.items())
    ]

    for value in items(tree["tree"]):
        entry = fields(value)
        path = api_string(entry["path"])

        if (
            path.startswith(PREFIX)
            and REFERENCE.fullmatch(path[len(PREFIX) :])
            and path not in content
        ):
            changes.append({"path": path, "mode": "100644", "type": "blob", "sha": None})

    new_tree = fields(api.request("git/trees", {"base_tree": base_tree, "tree": changes}, "POST"))

    new_tree_sha = api_string(new_tree["sha"])

    if new_tree_sha == base_tree:
        print("Preset references are already current.")
        return

    new_commit = fields(
        api.request(
            "git/commits",
            {
                "message": "🗺️ Teach the example fleet its new choreography",
                "tree": new_tree_sha,
                "parents": [expected],
            },
            "POST",
        )
    )
    new_sha = api_string(new_commit["sha"])

    # Recheck after object creation; a non-fast-forward update also rejects a later race.
    if current_pr_branch(api, number, expected) != branch:
        print("PR changed during reference preparation; skipping.")
        return

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
