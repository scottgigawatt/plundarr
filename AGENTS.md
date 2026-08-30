<!--
  Copyright 2025-2026 Scott Gigawatt

  Licensed under the Apache License, Version 2.0.

  AGENTS.md: Contributor and AI-agent operating instructions for Plundarr.
  -->

# AGENTS.md

## Project Purpose

Plundarr is a generated, single-file Docker Compose media stack intended for Docker Compose and Synology Container Manager. Maraudarr is the companion generator image that assembles the selected services, environment variables, and initial configuration directories.

Keep the names distinct:

- **Plundarr** is the generated stack in `dist/<preset>/docker-compose.yml`, `.env`, and `config/`.
- **Maraudarr** is the short-lived generator image and Python application under `docker/`.

The current catalog includes `plundarr`, `boudoirr`, `jellyfin`, `plex`, `duplex`, `watchtower`, and `custom` presets. Synology compatibility means DSM 7.4 with Container Manager; public documentation should not pin a DSM build number.

## Repository Layout

- `docker/`: Complete Maraudarr image build context. Follow `docker/AGENTS.md` for changes in this directory.
- `docker-compose.maraudarr.yml`: Local Maraudarr image build and run chart.
- `example.maraudarr.env`: Maraudarr image build defaults.
- `dist/`: Ignored generated Plundarr preset projects, each with Compose, environment, and runtime state.
- `scripts/compose/`: Host-side generated-project helpers used by Make.
- `scripts/linux/` and `scripts/synology/`: Documented host maintenance tools.
- `test/generator/`: Maraudarr image and preset-matrix validation.
- `test/helpers/`: Offline Make and workflow helper tests.
- `test/runtime/`: Live generated-stack and VPN validation.
- `test/stubs/`: Deterministic command stubs used by shell tests.
- `docs/`: Supporting setup, contribution, security, and community documents.
- `.github/`: Workflows, Renovate configuration, templates, and ownership.

## Documentation Voice

Public Markdown should be funny, lightly pirate-themed, readable, and useful. Put the operational meaning first and use pirate language mainly in short introductions, transitions, and sign-offs. Commands, paths, user-interface labels, warnings, security guidance, destructive actions, and troubleshooting instructions stay literal.

Follow `docs/documentation-style.md` for audience, structure, sentence-case headings, filenames, links, code blocks, alerts, advanced Markdown, and rendered review. Use searchable words before decorative emoji in headings. Emoji must not carry meaning by itself.

Reserve GitHub alerts for information readers must notice while scanning:

- `[!NOTE]`
- `[!TIP]`
- `[!IMPORTANT]`
- `[!WARNING]`
- `[!CAUTION]`

MkDocs converts this native GitHub syntax through `pymdownx.quotes`; do not maintain a second `!!!` admonition form for the published site.

Most pages should need no more than one or two alerts. Do not wrap routine commands in alerts or place alerts back to back. Keep prose-first alert source compact: put the first quoted content line immediately after `> [!TYPE]` without an empty `>` line between them. When an alert begins with a fenced code block or list, retain one empty quoted line because Markdown requires it to delimit that block. Use later blank quoted lines only to separate meaningful paragraphs or blocks inside one alert.

Write each ordinary Markdown prose paragraph on one physical source line and let editors apply visual word wrapping. Preserve semantic blank lines, lists, tables, code fences, deliberate hard breaks, and other structures that require their own lines. Configure Markdown editors to wrap visually rather than hard-wrapping prose at a fixed column.

Put routine copyable commands in ordinary `sh` fences. Use `[!IMPORTANT]` when information is required for success and `[!CAUTION]` when a command carries meaningful risk. Keep explanations outside the code fence and do not add prompt characters or prose comments inside those examples. Use `console` for terminal transcripts and `text` for non-executable output.

Keep `README.md`, `AGENTS.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, and `SUPPORT.md` in their established form. Name ordinary documentation pages with lowercase kebab-case.

## Code Comment Style

Code comments use concise plain English rather than pirate language. Project-owned scripts, Dockerfiles, Compose files, environment files, and configuration files should begin with the established copyright, Apache-2.0, and filename summary block.

Put a blank line before a standalone explanatory comment that introduces the next logical code block. Keep a short explanatory sentence on one comment line; split comments only when their structure or length genuinely requires it.

Inline Compose comments use two spaces before `#`. Align the `#` characters for logically grouped lines. Use four-space indentation in project-owned shell and Python code, two-space indentation in YAML and TOML, and four-space indentation in JSON and JSON-with-comments files. Every TOML table needs a concise purpose comment; keep multi-line arrays indented two spaces.

VS Code workspace JSON files use JSON with Comments so settings and extension choices can carry the same copyright, license, filename summary, and section comments as other project configuration.

## Shell And Make Rules

Prefer POSIX `#!/bin/sh` for host and simple container scripts. Bash is allowed only when the script intentionally uses Bash features and its runtime installs Bash.

Keep Makefile variables centralized near the top. User-facing targets may use light pirate humor, but errors must identify the problem and corrective action. Every target should have the established framed comment and dependency notes. Keep `requirements-docs.txt` exact and SHA-256 hash-verified, and require pip's hash-checking mode whenever Make installs the documentation toolchain.

## Generated Files And Secrets

Maraudarr writes each normal deployment into `dist/<preset>/`. Do not resolve `${VARIABLES}` inside the generated Compose file. The generated `.env` remains the only file users need to edit after generation.

`--output` is reserved for isolated tests and explicit automation paths. Normal user-facing Make targets use `--output-root` and must keep preset Compose, environment, and config state together under `dist/<preset>/`.

Never commit real credentials, API keys, generated application databases, or VPN state. Config seed files belong under `docker/services/*/config/`; generated runtime state belongs under `dist/<preset>/config/` and remains ignored. Services such as Kometa may intentionally mount operator-managed external state instead of receiving a generated config directory; document that boundary in the service chart and generated environment guidance.

Do not remove or overwrite existing application state while regenerating a stack. The explicit `make delete-config` target owns destructive config cleanup. `make nuke` intentionally removes the selected stack's Docker resources. Both targets must remain clearly marked as destructive in `make help` and public documentation; `make clean` must never touch deployments, `.env` files, configuration, backups, containers, volumes, or images. `make down` preserves volumes and images. `make nuke` also removes the separate `maraudarr` Compose project and repository-owned Buildx cache while preserving the selected deployment's `.env`, config, and backups; it must never invoke `delete-config`.

## Shell, Documentation, And Automation Style

Every project-owned shell script begins with its interpreter, copyright block, filename summary, purpose, and usage. Document each shell function immediately above its declaration with its purpose, parameters, and return behavior. Put one parameter on each comment line, align continuation descriptions beneath the first parameter, use `Parameters: None.` when appropriate, and use one space after `Returns:`. Follow this exact shape:

```sh
#
# function_name: Describe the function's purpose.
#
# Parameters: $1 - Describe the first parameter.
#             $2 - Describe the second parameter.
#
# Returns: Describe the return value or exit behavior.
#
```

Use POSIX function syntax in `sh` scripts and Bash syntax only when Bash is needed.

Keep host helpers grouped under `scripts/compose/`, `scripts/linux/`, or `scripts/synology/`. Keep shell tests grouped under `test/generator/`, `test/helpers/`, `test/runtime/`, or `test/stubs/`; update Make, workflows, documentation, and usage headers whenever a script moves.

Markdown command snippets are copyable: use `sh` fences without prompt characters. Reserve `bash` for Bash-only syntax and `console` for real terminal transcripts. Generated environment fragments should give short, aligned end-of-line guidance for values novice operators need to change.

All project-owned YAML, including GitHub Actions workflows, uses two-space indentation. Keep comments for non-obvious security, lifecycle, and integration decisions. Reusable workflow shell logic belongs in documented `.github` helpers instead of duplicated `run` blocks.

Treat `.editorconfig` as the portable source of truth for indentation, line endings, final newlines, and trailing whitespace. Workspace settings may repeat language indentation to disable VS Code auto-detection and may add schemas or extension-specific validation that EditorConfig cannot express. Keep those overlapping values identical.

Comment every Dockerfile build stage and each non-obvious instruction group. Stage comments must explain both the artifact produced and why the stage is separate.

## Docker And Compose Rules

The generated Plundarr deployment must remain one complete, commented `docker-compose.yml` file. Synology Container Manager compatibility is a core constraint.

Profile-gated maintenance utilities must stay out of ordinary `make up` runs. Kometa Overlay Reset uses the `tools` profile and the explicit `make kometa-overlay-reset PRESET=duplex` one-shot target.

Maraudarr must remain:

- architecture-neutral
- unprivileged by default
- configurable through Docker build arguments
- read-only except for the mounted output repository and temporary filesystem
- isolated from the network while generating stacks
- published with OCI labels, SBOM, provenance, and vulnerability scanning

## GitHub Workflow Rules

Align workflow filenames and responsibilities with the related Privateerr repository: `build-and-push.yml`, `codeql-actions.yml`, `scorecard.yml`, and `validate-pr.yml`. Keep GitHub Actions pinned by digest. Renovate owns dependency updates; do not add a second Dependabot configuration for the same dependencies.

Use the same published image-tag contract as Privateerr:

- Stable releases publish exact, minor, major, and `latest` aliases from one build.
- Prereleases publish only their exact version and `sha-*` tag, never movable aliases.
- Successful `main` builds publish `edge` and `sha-*` tags.
- Major version zero publishes its exact and minor aliases but not a `0` alias.

## Validation Expectations

Run the smallest applicable set, broadening it for generator, image, or workflow changes:

```sh
make help
make test-workflows
make test
make build
make test-image
make build-platforms
pre-commit run --all-files
```

Validate generated output with:

```sh
docker compose --env-file dist/plundarr/.env -f dist/plundarr/docker-compose.yml config --quiet
```
