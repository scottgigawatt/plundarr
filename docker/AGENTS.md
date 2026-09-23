<!--
  Copyright 2025-2026 Scott Gigawatt

  Licensed under the Apache License, Version 2.0.

  AGENTS.md: Scoped operating instructions for the Maraudarr image and source.
  -->

# Maraudarr Agent Instructions

These instructions extend the repository root `AGENTS.md` for every file under `docker/`.

## Ownership Boundary

This directory is the complete Docker build context for Maraudarr. Do not make the Dockerfile copy files from the repository root. Every source file, service chart, environment fragment, config seed, dependency manifest, and license required by the image must live here.

## Application Layout

- `Dockerfile`: Published Maraudarr image recipe.
- `maraudarr-entrypoint.sh`: Container entrypoint and signal handoff.
- `src/maraudarr/`: Python package. Never call this package `plundarr`.
- `tests/`: Unit tests for catalog, rendering, and config generation.
- `catalog/`: Preset and service metadata.
- `templates/`: Shared Compose and environment foundations.
- `services/<name>/compose.yml`: One logical selectable service, containing one or more Compose service definitions.
- `services/<name>/environment.env`: Settings owned by that service.
- `services/<name>/config/`: Optional files copied into generated `config/<name>/`; omit this directory for intentionally external state such as the Kometa checkout.
- `config/`: Files copied into the root of a generated preset's `config/`.

## Catalog Rules

Every selectable service lives in its own directory and has one catalog entry. A logical group such as Tracearr keeps its application and dedicated dependencies in that directory with one `compose.yml`, one `environment.env`, and one README. Declare its ordered container keys in `compose_services`; internal containers are not separate catalog choices. Do not create separate "extra" or "addon" aggregate files. Keep service order, dependencies, source paths, and descriptions explicit and documented in `catalog/catalog.toml`.

Services using named Docker volumes declare their unique keys in catalog `named_volumes`. The renderer emits only selected declarations without global names, so Compose scopes storage to the project. Deployment cleanup must preserve these volumes. Document backup exports and host-config deletion separately; omit empty config seed directories for volume-only dependencies.

Keep the category comments and add a concise comment immediately above every service and preset table so catalog readers can understand both the group and the entry's role without reading the renderer.

All TOML in this build context uses two-space indentation for multi-line arrays. Comment every table and any dependency or metadata choice whose purpose is not obvious from its key.

## Rendering Rules

Follow the root environment and Compose comment rules in every service fragment: keep only operator editing prompts inline in `environment.env`, and place behavior, units, accepted values, and limits beside the corresponding Compose settings. Generated `.env` and `example.env` files inherit this convention from the source fragments. Preserve existing operator values and comments when regenerating deployments.

Maraudarr preserves source comments and `${VARIABLES}`. Normal generation writes:

- `/output/dist/<preset>/docker-compose.yml`
- `/output/dist/<preset>/.env`
- `/output/dist/<preset>/config/`

The explicit `--output` option remains available for an exact automation directory such as a test fixture.

Normal user-facing commands use `--output-root` so a resolved preset owns its own Compose file, `.env`, and `config/` tree under `dist/<preset>/`.

Writes to Compose and environment output must remain atomic. Config generation may add missing seed files and refresh project-owned README files, but must not delete databases or replace user-owned application configuration.

Profile-gated utilities remain selectable services but must not appear in ordinary Compose startup. Overlay Reset uses the `tools` profile and is invoked through the repository's `make kometa-overlay-reset PRESET=duplex` target.

## Python Rules

Follow the shared shell and Python style in the root `AGENTS.md`. Root `ruff.toml` and `pyrightconfig.json` are authoritative for source and tests. Run `make test-types` for strict checking, including the optional fuzz harness. The pull-request pre-commit gate enforces types, lint, and formatting. Formatting changes must preserve generated comments and environment values.

Use four-space indentation, type hints, small focused functions, and standard library facilities where practical. Each project-owned module and test file starts with the repository copyright block followed by a concise module docstring. Public classes and non-obvious helpers need useful docstrings.

Separate a standalone explanatory comment from the preceding statement with a blank line. Prefer one concise comment line over hard-wrapping one sentence into multiple comment lines.

Keep imports rooted at `maraudarr`. Tests must exercise generated comments, environment preservation, selected config folders, Plex, Jellyfin, and Calibre-Web Automated choices, and real Docker Compose validation in the matrix script.

## Image Rules

Keep the image small and deterministic. Pin the Alpine base image by digest and Python packages by exact version plus hash. Runtime UID, GID, install paths, and OCI release metadata must remain configurable through build arguments.

Runtime service images follow their supported upstream floating channels. Whisparr must default to hotio's `v3` channel because hotio's `latest` channel still tracks Whisparr v2; do not document or test a pre-v3 Whisparr deployment.

The entrypoint must use `exec` so Maraudarr receives signals directly. The image is a short-lived tool and should not define a long-running healthcheck.

Label every Dockerfile stage in order and comment each instruction group so the artifact, security boundary, and reason for the stage remain clear during review.
