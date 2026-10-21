<!--
  Copyright 2025-2026 Scott Gigawatt

  Licensed under the Apache License, Version 2.0.

  AGENTS.md: Contributor and AI-agent operating instructions for Plundarr.
  -->

# AGENTS.md

## Purpose and scope

Plundarr is a generated, single-file Docker Compose media stack intended for Docker Compose and Synology Container Manager. Maraudarr is the companion Docker Compose project generator image that assembles the selected services, environment variables, and initial configuration directories.

Keep the names distinct:

- **Plundarr** is the generated stack in `dist/<preset>/docker-compose.yml`, `.env`, and `config/`.
- **Maraudarr** is the short-lived Docker Compose project generator image and Python application under `docker/`.

The current catalog includes `plundarr`, `boudoirr`, `jellyfin`, `plex`, `calibre-web-automated`, `duplex`, `watchtower`, `portainer`, and `custom` presets. Synology compatibility means DSM 7.4 with Container Manager; public documentation should not pin a DSM build number.

## Repository map

- `docker/`: Complete Maraudarr image build context. Follow [Docker guidance](docker/AGENTS.md) for changes in this directory.
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

## Change discipline

Read this file and applicable nested `AGENTS.md` files before editing; nested guidance adds directory-specific rules. Inspect any relevant local `.agents/skills` guidance when present. Keep these instructions self-contained within this repository. If linked local guidance contradicts the requested standard, report the conflict rather than silently changing unrelated files.

Keep changes scoped to the task. Inspect Git status and the full diff, preserve unrelated edits and operator state, and use an isolated checkout or worktree when needed. Do not reset, overwrite, or stage another contributor's work. Prefer source changes over editing generated artifacts; update related consumers only when within scope. Preserve existing copyright, license, and legitimate upstream attribution; attribution does not import external operating policy.

Code or guidance edits do not authorize running production mutations, destructive cleanup, deployments, secret access, privileged workflow changes, or publishing. Obtain the task's explicit authorization before those actions.

## Source, generated state, and secrets

Keep maintained templates separate from generated deployments and operator-owned runtime state.

### Environment and Compose comments

Keep `.env`, `example.env`, named environment examples, and service `environment.env` fragments focused on values. Reserve their end-of-line comments for settings operators must review or commonly customize: credentials, host paths, user/group IDs, time zones, and host-port conflicts. Use short action-oriented prompts such as `Edit before launch:`, `Edit for your host:`, or `Change only for a host-port conflict`. A generated secret that needs no manual action does not need an inline environment comment.

Put behavior explanations, accepted values, units, limits, dependencies between settings, and implementation details in aligned end-of-line comments beside the corresponding Compose entries. Explain numeric and boolean meanings where they are not obvious; for example, `1 disables IPv6; 0 enables IPv6`. Keep useful environment section headings, but do not move routine per-variable explanations into standalone environment comments to bypass this rule. Defaults belong in environment files, never Compose interpolation fallbacks.

Align inline comments within each logical group with at least two spaces before `#`. When updating a local environment file, preserve every assignment value exactly, including credentials and operator overrides. Never print or commit real environment values.

### Generated output and secrets

Maraudarr writes each normal deployment into `dist/<preset>/`. Do not resolve `${VARIABLES}` inside the generated Compose file. The generated `.env` remains the only file users need to edit after generation.

`--output` is reserved for isolated tests and explicit automation paths. Normal user-facing Make targets use `--output-root` and must keep preset Compose, environment, and config state together under `dist/<preset>/`.

Never commit real credentials, API keys, generated application databases, or VPN state. Config seed files belong under `docker/services/*/config/`; generated runtime state belongs under `dist/<preset>/config/` and remains ignored. Services such as Kometa may intentionally mount operator-managed external state instead of receiving a generated config directory; document that boundary in the service chart and generated environment guidance.

Do not remove or overwrite existing application state while regenerating a stack. The explicit `make delete-config` target owns destructive config cleanup. `make nuke` intentionally removes the selected stack's Docker resources. Both targets must remain clearly marked as destructive in `make help` and public documentation; `make clean` must never touch deployments, `.env` files, configuration, backups, containers, volumes, or images. `make down` preserves volumes and images. `make nuke` also removes the separate `maraudarr` Compose project and repository-owned Buildx cache while preserving the selected deployment's `.env`, bind-mounted config, and host backups. All application volumes and internal backups must survive deployment cleanup; it must never invoke `delete-config`. Volume deletion belongs only to disposable tests with unique project names, a creation ledger, and verified project/run labels. Never use global pruning. Document application backup exports separately from cleanup.

## Documentation standards

Public Markdown should be funny, lightly pirate-themed, readable, and useful. Put the operational meaning first and use pirate language mainly in short introductions, transitions, and sign-offs. Commands, paths, user-interface labels, warnings, security guidance, destructive actions, and troubleshooting instructions stay literal.

Follow [the documentation style guide](docs/documentation-style.md) for audience, structure, sentence-case headings, filenames, links, code blocks, alerts, advanced Markdown, and rendered review. Use searchable words before decorative emoji in headings. Emoji must not carry meaning by itself.

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

Use one descriptive H1 for each ordinary page, sentence-case subheadings in order without skipped levels, and a short introduction before subsections. Use numbered steps for procedures, bullets for choices, blank lines around lists and fenced blocks, and readable tables only for genuine comparisons.

Use descriptive relative links for repository-owned files, resolve paths from the referring page, and verify heading anchors after heading changes. Update inbound links, MkDocs navigation, and affected published routes when moving pages. Give informative images meaningful alt text; decorative images must not carry essential instructions. Keep diagrams accompanied by an equivalent explanation.

Shared repository and site pages use GitHub-flavored Markdown and native GitHub alerts, supported on the Material site by the configured `pymdownx.quotes` extension. Material-only constructs such as content tabs and attribute lists belong only on site pages that need them and must render under `mkdocs.yml`; never assume they work in GitHub README files or templates. Do not replace shared alerts with Material `!!!` admonitions.

State prerequisites, supported versions, working directory, permissions, and required values before procedures. Use language-labelled fenced blocks (`sh`, `bash` only for Bash-specific syntax, `console`, `text`, `yaml`, or the actual language). Commands must be copyable, omit prompts, use safe example values, and explain placeholders outside the fence. Place a literal destructive-operation warning and backup/recovery prerequisites before commands that can lose data or interrupt service. Never include real secrets, tokens, private logs, or operator-specific values in examples or screenshots.

Check claims against current source and the supported stable release. Label unreleased behavior explicitly rather than implying that `main` is already published. Explain migrations, compatibility constraints, architecture boundaries, persistent storage, backup coverage, and restore limitations where they affect an operator's decision; configuration archives alone may not capture databases or named-volume data. Keep command, environment, catalog, and API documentation consistent with the implementation.

Run Markdown/pre-commit checks and `make docs` for documentation changes, inspect the rendered GitHub result and Material pages as applicable, and verify links, anchors, tables, alerts, code blocks, images, diagrams, and narrow-screen readability. A strict MkDocs build is a real site check, not proof that every external URL or GitHub-only file renders correctly. Report unavailable render or link checks instead of claiming them.

## Code quality and comments

Code comments use concise plain English rather than pirate language. Project-owned scripts, Dockerfiles, Compose files, environment files, and configuration files should begin with the established copyright, Apache-2.0, and filename summary block.

Put a blank line before a standalone explanatory comment that introduces the next logical code block. Keep a short explanatory sentence on one comment line; split comments only when their structure or length genuinely requires it.

Inline Compose comments use two spaces before `#`. Align the `#` characters for logically grouped lines. Every TOML table needs a concise purpose comment; keep multi-line arrays indented two spaces.

VS Code workspace JSON files use JSON with Comments so settings and extension choices can carry the same copyright, license, filename summary, and section comments as other project configuration.

Treat `.editorconfig` as the portable source of truth for UTF-8, LF, final newlines, trailing whitespace, and indentation. Workspace settings may repeat language indentation to disable VS Code auto-detection and may add schemas or extension-specific validation that EditorConfig cannot express. Keep those overlapping values identical. Use four spaces in shell, Python, JSON, and JSON with Comments; two spaces in Markdown, YAML, TOML, AWK, jq, CSS, and JavaScript; and literal tabs in Make recipes. Preserve syntax-required whitespace. Put a blank line before and after logical control-flow blocks, and place a concise explanatory comment above non-obvious checks, loops, and operations. Do not add comments that merely repeat the code.

## Shell and Make practices

Prefer POSIX `#!/bin/sh` for host and simple container scripts. Bash is allowed only when the script intentionally uses Bash features and its runtime installs Bash. Use POSIX function syntax in `sh` scripts. Quote expansions, validate input/path boundaries, propagate failures, and use safe temporary resources and cleanup scoped to resources the operation owns.

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

Use targeted ShellCheck suppressions only when a documented runtime constraint prevents a correct code fix; never disable a diagnostic across the repository to hide individual findings. `.shellcheckrc` supplies shared source resolution for editors and checks.

Keep host helpers grouped under `scripts/compose/`, `scripts/linux/`, `scripts/synology/`, or the established `scripts/docs/` toolchain directory. Keep shell tests under `test/generator/`, `test/helpers/`, `test/runtime/`, or `test/stubs/`; update all affected Make targets, workflow callers, documentation, and usage headers whenever a script moves.

Keep Makefile variables centralized near the top. User-facing targets may use light pirate humor, but errors must identify the problem and corrective action. Every target needs the established framed comment and dependency notes; preserve `.PHONY` declarations for non-file targets and literal recipe tabs. Keep normal/default targets non-destructive, quote paths and user input, guard destructive paths, and avoid parse-time side effects. Do not promise blanket dry-run safety: recursive Make recipes and expansion-time commands may execute under `make -n`. Inspect recipes and their prerequisites before invoking or recommending them. Keep `requirements-docs.txt` exact and SHA-256 hash-verified, and require pip's hash-checking mode whenever Make installs documentation tools.

## Python practices

Python modules and tests start with the copyright, Apache-2.0, and filename summary block, followed by a useful, concise module docstring. Prefer small functions, explicit types at application boundaries, standard-library facilities, and concise docstrings for public classes and non-obvious helpers. `ruff.toml` owns lint and formatting rules, including import order, four-space indentation, and Unix line endings. Run both Ruff lint and format checks during pull-request validation; editors and pre-commit must use the same configuration. Keep lint and test dependencies out of published production images.

Explain the scenario and intent of Python tests with concise docstrings and comments around controlled fixtures, injected failures, cleanup, and meaningful assertion groups. Use blank lines to separate setup, actions, and verification where it improves readability. Explain why a boundary matters rather than narrating obvious assignments or adding repetitive step labels.

Fix root causes instead of adding blanket lint, type, or test suppressions. Any narrow exception must document the intentional constraint beside it.

`pyrightconfig.json` owns strict Python checking for both editors and automation. Keep every project-owned Python module and test in scope, including optional fuzz harnesses. Use `make test-types` for the pinned containerized checker; `make test`, pre-commit, and PR/main/release validation must enforce it. Validate dynamic data at its boundary, annotate collection and callback contracts, and narrow optional values explicitly. Do not weaken strict mode or add blanket `Any` annotations to hide findings. Document any targeted diagnostic exception beside the intentional test or optional dependency. Keep checker packages in test images, never production images.

## Docker and Compose boundaries

Comment every Dockerfile build stage and each non-obvious instruction group. Explain the artifact produced, security boundary, and reason for a separate stage.

The generated Plundarr deployment must remain one complete, commented `docker-compose.yml` file. Synology Container Manager compatibility is a core constraint.

Generated VPN configuration services retain UID 0 for upstream scripts but drop all Linux capabilities and enable `no-new-privileges`. Docker applies namespace IPv6 settings before startup; use a compatible upstream service release that skips redundant sysctl writes. Generated qBittorrent services follow explicit Compose-managed Gluetun restarts through `depends_on.restart: true`; tunnel recovery does not restart application containers.

Profile-gated maintenance utilities must stay out of ordinary `make up` runs. Kometa Overlay Reset uses the `tools` profile and the explicit `make kometa-overlay-reset PRESET=duplex` one-shot target.

Maraudarr must remain:

- architecture-neutral
- unprivileged by default
- configurable through Docker build arguments
- read-only except for the mounted output repository and temporary filesystem
- isolated from the network while generating stacks
- published with OCI labels, SBOM, provenance, and vulnerability scanning

## Automation and dependencies

Keep the established local workflow filenames and responsibilities:

- `.github/workflows/build-and-push.yml`: Validate, publish, attest, mirror, and announce Maraudarr images.
- `.github/workflows/codeql-actions.yml`: Analyze Maraudarr Python and GitHub Actions source.
- `.github/workflows/scorecard.yml`: Measure and publish the repository's supply-chain security posture.
- `.github/workflows/validate-pr.yml`: Validate pull requests, including generator/image checks, repository linting, and developer documentation.

Use this repository's workflows and policy tests as the authority for CI and publishing behavior. Pin external GitHub Actions to full immutable commit SHAs with readable version comments, and build dependencies to synchronized digests or exact versions and hashes as appropriate. Give jobs the minimum required permissions, prefer `contents: read`, avoid persistent checkout credentials, and isolate any justified write permission to the job that needs it. Keep untrusted PR execution separate from privileged writes; never expose secrets to it.

Renovate owns dependency updates; do not add duplicate Dependabot coverage. Keep all project-owned YAML indented two spaces. Put reusable workflow shell logic in documented `.github` helpers rather than duplicate `run` blocks, and explain non-obvious security, lifecycle, and integration decisions.

Preserve the image-tag contract enforced by `test/policy/check-image-tag-policy.sh`: stable releases publish exact, minor, major, and `latest` aliases from one build; prereleases publish only exact and `sha-*` tags; successful `main` builds publish `edge` and `sha-*`; major version zero has no `0` alias. Build-pin synchronization is checked by `test/policy/check-build-pin-policy.sh`. Repository changes do not authorize publishing images, creating tags/releases, or changing repository settings.

## Validation

Choose checks by the changed behavior and report their exact commands and outcomes. Read the relevant Make recipes and scripts before running them; a target name, `make -n`, or a stub-based check is not evidence of real container or production behavior.

### Local and offline checks

From the repository root, use these real entry points as applicable:

```sh
make help
make test-unit
make test-make-helpers
make test-workflows
git diff --check
```

`make test-unit` uses host Python and installed dependencies; use a Python version supported by `docker/pyproject.toml` and report optional-dependency skips. The helper and workflow suites use deterministic fixtures and stubs, including rejected-input and cleanup ownership checks; they do not contact live registries, VPNs, or messaging services.

### Documentation and lint checks

Run `pre-commit run --all-files`. Pre-commit may need network access to install its pinned hooks and always runs the Docker-dependent type checker. Run CSpell across project-owned files; correct misspellings and add only genuine vocabulary to `.vscode/settings.json` under `cSpell.words`, never secrets or arbitrary strings.

For documentation, `make docs` builds MkDocs with `--strict`, installing exact hash-verified dependencies from `requirements-docs.txt` into `.venv-docs/` as needed. The required exact Python version and interpreter setting are declared in the Makefile; installation needs network access, while a prepared site build does not need deployment credentials. Use `make docs-serve` for local rendered inspection. Check changed relative links and heading anchors separately, including GitHub-only guidance outside site navigation.

### Docker and generator checks

```sh
make test-types
make test
make build
make test-image
make build-platforms
make test-examples
```

These require Docker/Compose, and image/toolchain preparation can need network access and architecture emulation. `make test` includes unit tests, strict types, helper/workflow checks, image-resolution fixtures, and the real Compose generation matrix; it is not an offline-only unit test. Image and multi-architecture checks belong to changes in the build context or container contract. `make test-examples` compares public references against fresh container output; `make examples` refreshes tracked examples and is a deliberate write, not a read-only check.

After generating a disposable preset in an isolated output directory, use real Compose validation with its matching environment file. For the normal `plundarr` output layout:

```sh
docker compose --env-file dist/plundarr/.env -f dist/plundarr/docker-compose.yml config --quiet
```

Do not print interpolated Compose configuration or environment values from real deployments. Never treat generated syntax validation as proof of live health or successful VPN recovery.

### Live and credentialed checks

`make test-vpn` inspects a running VPN stack; `make test-e2e` starts VPN/download services and restores example config; `make test-stack` starts every service and leaves the stack running on success. These use live state and may require real provider credentials. `test/runtime/test-compose-cleanup-live.sh` uses a real Docker daemon and creates/removes labelled disposable projects and volumes. Run live checks only in an explicitly authorized isolated environment, never against an operator deployment by default. Do not access live VPN, Plex, production data, or secrets merely to validate a guidance or documentation edit.

## Handoff

Review the complete diff and changed-file list before committing. Summarize what changed, why, exact validation passed/failed/skipped, prerequisites or limits, and any scope decisions or contradictions left for review. Distinguish tests actually run from recommended follow-up. Supply the branch, head SHA, and PR URL when created. Keep manual review checkpoints: a draft PR does not authorize approval, merging, auto-merge, deployment, or release work.
