<!--
  Copyright 2025-2026 Scott Gigawatt

  Licensed under the Apache License, Version 2.0.

  AGENTS.md: Scoped operating instructions for the Maraudarr image and source.
  -->

# Maraudarr Agent Instructions

These instructions extend the repository root `AGENTS.md` for every file under
`docker/`.

## Ownership Boundary

This directory is the complete Docker build context for Maraudarr. Do not make
the Dockerfile copy files from the repository root. Every source file, service
chart, environment fragment, config seed, dependency manifest, and license
required by the image must live here.

## Application Layout

- `Dockerfile`: Published Maraudarr image recipe.
- `maraudarr-entrypoint.sh`: Container entrypoint and signal handoff.
- `src/maraudarr/`: Python package. Never call this package `plundarr`.
- `tests/`: Unit tests for catalog, rendering, and config generation.
- `catalog/`: Preset and service metadata.
- `templates/`: Shared Compose and environment foundations.
- `services/<name>/compose.yml`: Exactly one selectable service definition.
- `services/<name>/environment.env`: Settings owned by that service.
- `services/<name>/config/`: Files copied into generated `config/<name>/`.
- `config/`: Files copied into the root of a generated preset's `config/`.

## Catalog Rules

Every selectable service lives in its own directory and has one catalog entry.
Do not create separate "extra" or "addon" aggregate files. Keep service order,
dependencies, source paths, and descriptions explicit and documented in
`catalog/catalog.toml`.

Keep the category comments and add a concise comment immediately above every
service and preset table so catalog readers can understand both the group and
the entry's role without reading the renderer.

## Rendering Rules

Maraudarr preserves source comments and `${VARIABLES}`. Normal generation writes:

- `/output/dist/<preset>/docker-compose.yml`
- `/output/dist/<preset>/.env`
- `/output/dist/<preset>/config/`

The explicit `--output` option remains available for an exact automation
directory such as a test fixture.

Normal user-facing commands use `--output-root` so a resolved preset owns its
own Compose file, `.env`, and `config/` tree under `dist/<preset>/`.

Writes to Compose and environment output must remain atomic. Config generation
may add missing seed files and refresh project-owned README files, but must not
delete databases or replace user-owned application configuration.

## Python Rules

Use four-space indentation, type hints, small focused functions, and standard
library facilities where practical. Each project-owned module and test file
starts with the repository copyright block followed by a concise module
docstring. Public classes and non-obvious helpers need useful docstrings.

Keep imports rooted at `maraudarr`. Tests must exercise generated comments,
environment preservation, selected config folders, Plex and Jellyfin choices,
and real Docker Compose validation in the matrix script.

## Image Rules

Keep the image small and deterministic. Pin the Alpine base image by digest and
Python packages by exact version plus hash. Runtime UID, GID, install paths, and
OCI release metadata must remain configurable through build arguments.

The entrypoint must use `exec` so Maraudarr receives signals directly. The image
is a short-lived tool and should not define a long-running healthcheck.
