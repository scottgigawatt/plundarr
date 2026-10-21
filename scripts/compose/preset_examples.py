#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# preset_examples.py: Generate and validate secret-free preset reference files.
#

"""Generate public preset references through the production Maraudarr image."""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import tempfile
from pathlib import Path

FILENAMES = ("docker-compose.yml", "example.env")
CUSTOM_SERVICES = "privateerr,gluetun,qbittorrent,prowlarr,radarr,sonarr,sonarr-anime"
PRESET_ID = re.compile(r"[a-z][a-z0-9-]*")


def run(arguments: list[str], *, capture: bool = False) -> str:
    """Run Docker without inheriting operator-specific Compose overrides."""

    environment = {
        key: value
        for key, value in os.environ.items()
        if key
        in {
            "PATH",
            "HOME",
            "TMPDIR",
            "DOCKER_HOST",
            "DOCKER_CONTEXT",
            "DOCKER_CONFIG",
            "DOCKER_TLS_VERIFY",
            "DOCKER_CERT_PATH",
            "SSH_AUTH_SOCK",
        }
    }

    try:
        result = subprocess.run(
            arguments, check=True, text=True, capture_output=capture, env=environment
        )
    except subprocess.CalledProcessError as error:
        if capture and error.stderr:
            print(error.stderr)

        raise

    return result.stdout if capture else ""


def container(image: str, arguments: list[str], output: Path | None = None) -> str:
    """Use the same isolated, unprivileged runtime contract as normal generation."""

    command = [
        "docker",
        "run",
        "--rm",
        "--network",
        "none",
        "--read-only",
        "--cap-drop",
        "ALL",
        "--security-opt",
        "no-new-privileges:true",
        "--user",
        f"{os.getuid()}:{os.getgid()}",
        "--tmpfs",
        "/tmp:rw,noexec,nosuid,size=64m",
    ]

    if output is not None:
        command.extend(["--volume", f"{output}:/output:rw"])

    # Python is already in the production image; no host catalog parser is needed.
    command.extend(["--entrypoint", "python3", image, *arguments])
    return run(command, capture=True)


def validate_project(project: Path) -> None:
    """Inspect a real generated project without following container-created symlinks."""

    if project.is_symlink() or not project.is_dir():
        raise ValueError("Generated preset directories must be real directories.")

    # The container can create links whose targets become host paths after it exits.
    for filename in (".env", *FILENAMES):
        path = project / filename

        if path.is_symlink() or not path.is_file():
            raise ValueError("Generated preset inputs must be regular files, not symlinks.")

    # Inspect both the deployment environment and the exact public example.
    for environment_file in (".env", "example.env"):
        run(
            [
                "docker",
                "compose",
                "--env-file",
                str(project / environment_file),
                "--file",
                str(project / "docker-compose.yml"),
                "--profile",
                "*",
                "config",
                "--quiet",
            ]
        )


def generate(image: str, temporary: Path) -> dict[str, bytes]:
    """Validate every preset and require reproducible public output.

    Args:
        image: Production Maraudarr image built from the source under review.
        temporary: Empty disposable directory for both independent generation runs.

    Returns:
        Public reference bytes keyed by preset-relative filename.

    Raises:
        ValueError: If preset IDs, generated files, or reproducibility checks fail.
        subprocess.CalledProcessError: If generation or Docker Compose validation fails.
    """

    listing = container(
        image,
        ["-c", "from maraudarr.catalog import Catalog; print(*Catalog().presets, sep=chr(10))"],
    )
    presets = listing.splitlines()

    if (
        not presets
        or len(presets) != len(set(presets))
        or any(PRESET_ID.fullmatch(preset) is None for preset in presets)
    ):
        raise ValueError("Maraudarr returned an invalid preset inventory.")

    snapshots: dict[str, bytes] = {}

    for repetition in range(2):
        output = temporary / str(repetition)
        output.mkdir()

        for preset in presets:
            arguments = [
                "-m",
                "maraudarr",
                "--plain",
                "build",
                "--preset",
                preset,
                "--output-root",
                "/output",
            ]

            if preset == "custom":
                arguments.extend(["--add", CUSTOM_SERVICES])

            container(image, arguments, output)
            project = output / preset

            validate_project(project)

            for filename in FILENAMES:
                relative = f"{preset}/{filename}"
                content = (project / filename).read_bytes()

                if not content:
                    raise ValueError(f"Maraudarr produced an empty reference: {relative}")

                if repetition and snapshots[relative] != content:
                    raise ValueError(f"Preset reference is not deterministic: {relative}")

                snapshots[relative] = content

    return snapshots


def read_references(directory: Path) -> dict[str, bytes]:
    """Read only public reference pairs and reject symlinks before any replacement."""

    if directory.is_symlink():
        raise ValueError("The preset reference root must not be a symlink.")

    references: dict[str, bytes] = {}

    for preset in directory.iterdir() if directory.exists() else ():
        if preset.is_symlink():
            raise ValueError("Preset reference directories must not be symlinks.")

        if not preset.is_dir():
            continue

        for filename in FILENAMES:
            path = preset / filename

            if path.is_symlink():
                raise ValueError("Preset reference files must not be symlinks.")

            if path.exists():
                references[f"{preset.name}/{filename}"] = path.read_bytes()

    return references


def publish(directory: Path, snapshots: dict[str, bytes]) -> None:
    """Publish validated public references without changing unmanaged files.

    Each file is replaced atomically after all generation checks pass. Filesystem
    errors propagate to the caller; an incomplete replacement leaves no temporary file.

    Args:
        directory: Reference root, kept separate from private deployment output.
        snapshots: Complete public pairs returned by successful generation.
    """

    existing = read_references(directory)

    for relative, content in snapshots.items():
        path = directory / relative
        path.parent.mkdir(parents=True, exist_ok=True)

        # Keep replacement on the same filesystem and clean up even if writing fails.
        with tempfile.TemporaryDirectory(
            prefix=".maraudarr-reference-", dir=path.parent
        ) as temporary:
            pending_path = Path(temporary) / path.name
            pending_path.write_bytes(content)
            pending_path.chmod(0o644)
            pending_path.replace(path)

    # A removed preset loses only its managed pair; other files are never deleted.
    for relative in existing.keys() - snapshots.keys():
        (directory / relative).unlink()


def main() -> int:
    """Refresh references or fail when freshly generated output differs."""

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", required=True)
    parser.add_argument("--output-root", type=Path, required=True)
    parser.add_argument("--check", action="store_true")
    arguments = parser.parse_args()

    with tempfile.TemporaryDirectory(prefix="maraudarr-examples-") as temporary:
        snapshots = generate(arguments.image, Path(temporary))

    if arguments.check:
        if read_references(arguments.output_root) != snapshots:
            print(
                "Preset examples are stale. Run make build examples with a local Maraudarr image."
            )
            return 1
    else:
        publish(arguments.output_root, snapshots)

    print(f"Validated {len(snapshots) // len(FILENAMES)} reproducible preset examples.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
