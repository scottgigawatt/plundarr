<!--
  Copyright 2025-2026 Scott Gigawatt

  Licensed under the Apache License, Version 2.0.

  AGENTS.md: Scoped operating instructions for the Maraudarr image and source.
  -->

# Maraudarr Agent Instructions

These instructions extend [root guidance](../AGENTS.md) for every file under `docker/`. Read both before editing this complete build context; the root rules cover change scope, secrets, documentation, code quality, automation, validation, and handoff.

## Purpose and scope

This directory is the complete Docker build context for Maraudarr. Do not make the Dockerfile copy files from the repository root. Every source file, service chart, environment fragment, config seed, dependency manifest, and license required by the image must live here.

## Repository map

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

## Catalog ownership

Every selectable service lives in its own directory and has one catalog entry. A logical group such as Tracearr keeps its application and dedicated dependencies in that directory with one `compose.yml`, one `environment.env`, and one README. Declare its ordered container keys in `compose_services`; internal containers are not separate catalog choices. Do not create separate "extra" or "addon" aggregate files. Keep service order, dependencies, source paths, and descriptions explicit and documented in `catalog/catalog.toml`.

Services using named Docker volumes declare their unique keys in catalog `named_volumes`. The renderer emits only selected declarations without global names, so Compose scopes storage to the project. Deployment cleanup must preserve these volumes. Document backup exports and host-config deletion separately; omit empty config seed directories for volume-only dependencies.

Keep the category comments and add a concise comment immediately above every service and preset table so catalog readers can understand both the group and the entry's role without reading the renderer.

All TOML in this build context uses two-space indentation for multi-line arrays. Comment every table and any dependency or metadata choice whose purpose is not obvious from its key.

## Source, generated state, and secrets

Follow the root environment and Compose comment rules in every service fragment: keep only operator editing prompts inline in `environment.env`, and place behavior, units, accepted values, and limits beside the corresponding Compose settings. Generated `.env` and `example.env` files inherit this convention from the source fragments. Preserve existing operator values and comments when regenerating deployments.

Maraudarr preserves source comments and `${VARIABLES}`. Normal generation writes:

- `/output/dist/<preset>/docker-compose.yml`
- `/output/dist/<preset>/.env`
- `/output/dist/<preset>/config/`

The explicit `--output` option remains available for an exact automation directory such as a test fixture.

Normal user-facing commands use `--output-root` so a resolved preset owns its own Compose file, `.env`, and `config/` tree under `dist/<preset>/`.

Writes to Compose and environment output must remain atomic. Config generation may add missing seed files and refresh project-owned README files, but must not delete databases or replace user-owned application configuration.

Profile-gated utilities remain selectable services but must not appear in ordinary Compose startup. Overlay Reset uses the `tools` profile and is invoked through the repository's `make kometa-overlay-reset PRESET=duplex` target.

## Python practices

Follow the root code, shell, Python, and documentation practices; the explicit requirements below apply throughout this build context. Root `ruff.toml` and `pyrightconfig.json` are authoritative for source and tests. Formatting must preserve generated comments, literal interpolation placeholders, and operator environment values. Keep lint, test, type-checker, and documentation dependencies out of the production image.

Use four-space indentation, type hints, small focused functions, and standard library facilities where practical. Each project-owned module and test file starts with the repository copyright block followed by a concise module docstring. Public classes and non-obvious helpers need useful docstrings.

Separate a standalone explanatory comment from the preceding statement with a blank line. Prefer one concise comment line over hard-wrapping one sentence into multiple comment lines.

Keep imports rooted at `maraudarr`. Tests must exercise generated comments, environment preservation, selected config folders, Plex, Jellyfin, and Calibre-Web Automated choices, and real Docker Compose validation in the matrix script.

## Docker and dependency boundaries

Keep the image small and deterministic. Pin the Alpine base image by digest and Python packages by exact version plus hash. Runtime UID, GID, install paths, and OCI release metadata must remain configurable through build arguments.

Runtime service images follow their supported upstream floating channels. Whisparr must default to hotio's `v3` channel because hotio's `latest` channel still tracks Whisparr v2; do not document or test a pre-v3 Whisparr deployment.

The entrypoint must use `exec` so Maraudarr receives signals directly. The image is a short-lived tool and should not define a long-running healthcheck.

Label every Dockerfile stage in order and comment each instruction group so the artifact, security boundary, and reason for the stage remain clear during review.

## Validation and handoff

Run commands from the repository root. Use `make test-unit` for focused host-side tests and report optional-dependency skips. Run Ruff lint and format checks with the root configuration, and `make test-types` for strict checking, including the optional fuzz harness. The pre-commit gate includes types, lint, and formatting; it needs Docker for types and may need network access to prepare hooks.

Use `make test` for the real generation matrix and helper contracts, `make build` and `make test-image` for image/runtime changes, `make build-platforms` for build-stage or architecture changes, and `make test-examples` for public-reference consistency. These are Docker-dependent checks and may pull/build images; they do not establish live service health. Use disposable output rather than existing deployments. Include regeneration tests for preserved operator values, databases, named volumes, config seeds, atomic output failures, and excluded maintenance profiles when relevant.

For documentation changes, apply the root GitHub/ISO reader-outcome requirements to service notes, copied config READMEs, and source-derived API reference. Remove repeated application introductions; retain local first-run, storage, and recovery instructions needed in a generated deployment. Run `make docs`, Markdown/pre-commit checks, relative-link/anchor checks, and rendered review appropriate to GitHub and the Material site. Keep generated API documentation derived from source and preserve the catalog/build-context ownership descriptions. Do not use live VPN, Plex, operator data, or production access to validate guidance. Follow the root handoff requirements and report failures, skips, and unavailable prerequisites truthfully.
