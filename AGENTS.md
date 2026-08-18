<!--
  Copyright 2025-2026 Scott Gigawatt

  Licensed under the Apache License, Version 2.0.

  AGENTS.md: Contributor and AI-agent operating instructions for Plundarr.
  -->

# AGENTS.md

## Project Purpose

Plundarr is a generated, single-file Docker Compose media stack intended for
Docker Compose and Synology Container Manager. Maraudarr is the companion
generator image that assembles the selected services, environment variables,
and initial configuration directories.

Keep the names distinct:

- **Plundarr** is the generated stack in `dist/<preset>/docker-compose.yml`,
  `.env`, and `config/`.
- **Maraudarr** is the short-lived generator image and Python application under
  `docker/`.

## Repository Layout

- `docker/`: Complete Maraudarr image build context. Follow `docker/AGENTS.md`
  for changes in this directory.
- `docker-compose.maraudarr.yml`: Local Maraudarr image build and run chart.
- `example.maraudarr.env`: Maraudarr image build defaults.
- `dist/`: Ignored generated Plundarr preset projects, each with Compose,
  environment, and runtime state.
- `test/`: Plundarr runtime validation and Maraudarr generation matrix.
- `docs/`: Supporting setup, contribution, security, and community documents.
- `.github/`: Workflows, Renovate configuration, templates, and ownership.

## Documentation Voice

Public Markdown should be funny, lightly pirate-themed, readable, and useful.
Preserve centered badges, tables, GitHub callouts, emoji, and the established
visual style in the root README. Do not let jokes obscure commands, warnings,
paths, or troubleshooting instructions.

Use GitHub callouts where they improve scanning:

- `[!NOTE]`
- `[!TIP]`
- `[!IMPORTANT]`
- `[!WARNING]`
- `[!CAUTION]`

## Code Comment Style

Code comments use concise plain English rather than pirate language. Project-
owned scripts, Dockerfiles, Compose files, environment files, and configuration
files should begin with the established copyright, Apache-2.0, and filename
summary block.

Inline Compose comments use two spaces before `#`. Align the `#` characters for
logically grouped lines. Use four-space indentation in project-owned shell and
Python code.

## Shell And Make Rules

Prefer POSIX `#!/bin/sh` for host and simple container scripts. Bash is allowed
only when the script intentionally uses Bash features and its runtime installs
Bash.

Keep Makefile variables centralized near the top. User-facing targets may use
light pirate humor, but errors must identify the problem and corrective action.
Every target should have the established framed comment and dependency notes.

## Generated Files And Secrets

Maraudarr writes each normal deployment into `dist/<preset>/`. Do not resolve
`${VARIABLES}` inside the generated Compose file. The generated `.env` remains
the only file users need to edit after generation.

`--output` is reserved for isolated tests and explicit automation paths. Normal
user-facing Make targets use `--output-root` and must keep preset Compose,
environment, and config state together under `dist/<preset>/`.

Never commit real credentials, API keys, generated application databases, or
VPN state. Config seed files belong under `docker/services/*/config/`; generated
runtime state belongs under `dist/<preset>/config/` and remains ignored.

Do not remove or overwrite existing application state while regenerating a
stack. The explicit `make clean-config` target owns destructive config cleanup.

## Docker And Compose Rules

The generated Plundarr deployment must remain one complete, commented
`docker-compose.yml` file. Synology Container Manager compatibility is a core
constraint.

Maraudarr must remain:

- architecture-neutral
- unprivileged by default
- configurable through Docker build arguments
- read-only except for the mounted output repository and temporary filesystem
- isolated from the network while generating stacks
- published with OCI labels, SBOM, provenance, and vulnerability scanning

## GitHub Workflow Rules

Align workflow filenames and responsibilities with the related Privateerr
repository: `build-and-push.yml`, `codeql-actions.yml`, `scorecard.yml`, and
`validate-pr.yml`. Keep GitHub Actions pinned by digest. Renovate owns dependency
updates; do not add a second Dependabot configuration for the same dependencies.

## Validation Expectations

Run the smallest applicable set, broadening it for generator, image, or workflow
changes:

```sh
make help
make test-maraudarr
make build-maraudarr
make build-multiarch
pre-commit run --all-files
```

Validate generated output with:

```sh
docker compose --env-file dist/plundarr/.env -f dist/plundarr/docker-compose.yml config --quiet
```
