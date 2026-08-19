# Contributing to Plundarr 🏴‍☠️

Ahoy, improbable contributor. Plundarr is a Docker Compose fleet for media services, PIA WireGuard, PIA port forwarding, Privateerr, and Gluetun, so changes should arrive shipshape and easy to sail on Synology.

## Before Ye Start ⚓

- Read the [repository README](https://github.com/scottgigawatt/plundarr#readme).
- Read the [security policy](SECURITY.md) before sharing logs or generated config.
- Keep to the [Code](CODE_OF_CONDUCT.md).
- Check existing issues before opening a duplicate treasure map.

## What Belongs Here 🧭

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

## Local Setup 🛠️

> [!EXAMPLE]
>
> ```sh
> git clone git@github.com:scottgigawatt/plundarr.git
> cd plundarr
> make ship
> ```

Edit `dist/plundarr/.env` with yer own values. Keep that file private.

Useful commands:

> [!EXAMPLE]
>
> ```sh
> make help
> make test
> make docs
> make build
> make test-image
> make build-platforms
> pre-commit run --all-files
> ```

Generated-stack checks such as `make config`, `make env`, `make up`,
`make test-vpn`, `make test-e2e`, and `make test-stack` accept
`PRESET=<preset>` when the change is preset-specific.

> [!IMPORTANT]
> 🧪 VPN and port-forwarding testing uses real PIA credentials from the selected
> preset's `.env`. That voyage should happen locally, not with secrets flung
> into public waters.

## Style Rules 📜

- Public Markdown and user-facing command output may speak fluent pirate.
- Code comments should use plain English.
- Shell scripts written for host use should use `#!/bin/sh` where possible.
- Shell scripts should use four spaces for indentation.
- Shell functions document their purpose, parameters, and return behavior.
- Copyable Markdown commands use `sh` fences without a shell prompt.
- Teaching examples wrap copyable commands in an `[!EXAMPLE]` callout and keep
  explanatory comments outside the code fence.
- YAML and TOML use two-space indentation; Python, shell, and JSON use four.
- Docker Compose values should come from the selected preset's `.env` instead
  of inline fallback soup.
- Keep service config directories aligned with service names.
- Let Privateerr own the upstream PIA manual connection scripts.

## Pull Requests 🪝

Before opening a pull request:

- Run relevant `make` targets.
- Run `make config`.
- Run `pre-commit run --all-files` if hooks are installed.
- Confirm no secrets, live VPN configs, or logs slipped into the hold.
- Explain what changed and why.

Tiny pull requests be easier to review than a kraken-sized rewrite with six unrelated tentacles.

## Security Reports 🛡️

Do not report security problems in public issues or pull requests. Use the [security policy](SECURITY.md), or hail the captain in [🔥HADES🔥](https://discord.gg/BpEGzWwGYf) Discord for a safer channel.

Fair winds, clean diffs, and may yer YAML indent on the first try. ☠️
