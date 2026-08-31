# Contributing to Plundarr 🏴‍☠️

Ahoy, improbable contributor. Plundarr is a Docker Compose fleet for media services, PIA WireGuard, PIA port forwarding, Privateerr, and Gluetun, so changes should arrive shipshape and easy to sail on Synology.

## Before you start ⚓

- Read the [repository README](https://github.com/scottgigawatt/plundarr#readme).
- Read the [security policy](SECURITY.md) before sharing logs or generated config.
- Read the [documentation style](documentation-style.md) before changing public Markdown.
- Keep to the [Code](CODE_OF_CONDUCT.md).
- Check existing issues before opening a duplicate treasure map.

## What belongs here 🧭

Good contributions include:

- Clear bug fixes.
- Docker Compose improvements that keep Synology DSM Container Manager, PIA WireGuard, and port forwarding in mind.
- Documentation that helps real humans avoid setup mistakes.
- Test and workflow improvements for the Plundarr stack.
- Security hardening that stays free, open, and maintainable.

Questionable cargo includes:

- Huge rewrites without an issue first.
- Paid-only services, subscription gates, or magic hosted scanners.
- Vendoring upstream PIA manual connection scripts into this repo.
- Anything that requires committing secrets, live `wg0.conf`, real `privateerr.env` data, or private logs.

## Set up a development checkout 🛠️

```sh
git clone git@github.com:scottgigawatt/plundarr.git
cd plundarr
make ship
```

Edit `dist/plundarr/.env` with yer own values. Keep that file private.

Useful commands:

```sh
make help
make test
make test-workflows
make docs
make build
make test-image
make build-platforms
pre-commit run --all-files
```

Generated-stack checks such as `make config`, `make env`, `make up`, `make test-vpn`, `make test-e2e`, and `make test-stack` accept `PRESET=<preset>` when the change is preset-specific.

`make down PRESET=<preset>` preserves volumes and images. `make clean` is repository-only and never touches `dist/` or Docker. `make nuke` removes the selected project's Docker resources plus the separate `maraudarr` Compose project that runs Maraudarr and its scoped Buildx cache, but preserves deployment `.env`, backups, and persistent config. Only `make delete-config` deletes application state.

> [!IMPORTANT]
> 🧪 VPN and port-forwarding testing uses real PIA credentials from the selected preset's `.env`. That voyage should happen locally, not with secrets flung into public waters.

## Follow the project style 📜

- Public Markdown and user-facing command output may use light pirate flavor after the operational meaning is clear.
- Documentation follows [`documentation-style.md`](documentation-style.md), including sentence-case headings and alert limits.
- Code comments should use plain English.
- Shell scripts written for host use should use `#!/bin/sh` where possible.
- Shell scripts should use four spaces for indentation.
- Shell functions document their purpose, parameters, and return behavior.
- Copyable Markdown commands use `sh` fences without a shell prompt.
- Routine commands use ordinary `sh` fences. Required information uses `[!IMPORTANT]`, while risky commands use `[!CAUTION]`. Keep explanatory comments outside the code fence.
- YAML, TOML, AWK, and jq use two-space indentation; Python, shell, JSON, and JSON-with-comments use four.
- Docker Compose values should come from the selected preset's `.env` instead of inline fallback soup.
- Keep service config directories aligned with service names.
- Let Privateerr own the upstream PIA manual connection scripts.

### Configure editor tooling 🧰

`.editorconfig` is the portable source of truth for indentation, line endings, final newlines, and trailing whitespace. Install the recommendations from `.vscode/extensions.json` when using VS Code; each entry carries an aligned comment explaining whether it formats, validates, or only highlights a file type.

Workspace format-on-save is deliberately disabled. Prettier is available only for explicit formatting of supported CSS, JavaScript, JSON, and Markdown files, using the checked-in `.prettierrc.json5`. It does not parse jq, and the repository excludes jq, YAML, TOML, and aligned workspace JSONC from Prettier so their specialized validators and formatters cannot undo project-owned spacing. In particular, keep two spaces before pinned-action comments in workflow YAML.

## Prepare a pull request 🪝

Before opening a pull request:

- Run relevant `make` targets.
- Run `make test-workflows` for workflow, release, build-pin, or image-tag changes.
- Run `make config`.
- Run `pre-commit run --all-files` if hooks are installed.
- Confirm no secrets, live VPN configs, or logs slipped into the hold.
- Explain what changed and why.

Tiny pull requests be easier to review than a kraken-sized rewrite with six unrelated tentacles.

## Report security concerns 🛡️

Do not report security problems in public issues, pull requests, or Discord. Use the [security policy](SECURITY.md) and GitHub private vulnerability reporting. Use the [support guide](SUPPORT.md) for non-sensitive questions.

Fair winds, clean diffs, and may yer YAML indent on the first try. ☠️
