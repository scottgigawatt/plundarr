# Contributing to Plundarr 🏴‍☠️

Bring focused fixes, clear documentation, or better tests. Keep Docker Compose and Synology Container Manager compatibility, protect operator state, and discuss large design changes before starting.

## Before you start ⚓

Read the [README](https://github.com/scottgigawatt/plundarr/blob/main/README.md), [security policy](SECURITY.md), [Code of Conduct](CODE_OF_CONDUCT.md), and applicable [agent/contributor guidance](https://github.com/scottgigawatt/plundarr/blob/main/AGENTS.md). Check existing issues. Privateerr owns the PIA scripts; do not vendor them here. Never include credentials, generated VPN files, application state, or private logs in a contribution.

## Set up a development checkout 🛠️

Install Git, Make, Docker with Compose, and pre-commit. Host tests require Python supported by `docker/pyproject.toml`; documentation uses the exact interpreter in the [testing guide](development/maraudarr/testing.md#validate-documentation).

```sh
git clone https://github.com/scottgigawatt/plundarr.git
cd plundarr
```

For generator changes, [build and select this checkout's image](development/maraudarr/index.md#choose-the-generator-revision). A changed source file does not change an already-built image. Generate only into disposable test output; do not use operator deployments. Documentation/helper checks need no PIA credentials.

## Follow the project style 📜

Apply [GitHub/ISO documentation requirements](documentation-style.md): identify the reader/task, consolidate repeated explanations, and verify the rendered task path. Keep necessary backup, security, and compatibility guidance. Public prose may have light pirate flavor; technical comments and warnings use plain English.

`.editorconfig`, `ruff.toml`, and `pyrightconfig.json` own whitespace, Python style, and strict types. Follow the detailed [code and shell conventions](https://github.com/scottgigawatt/plundarr/blob/main/AGENTS.md#code-quality-and-comments). Compose defaults belong in environment fragments; source charts preserve comments and `${VARIABLES}`.

### Configure editor tooling 🧰

Use the recommended `.vscode/extensions.json` extensions. Format-on-save is disabled; Prettier is for explicit formatting of supported files. Keep specialized YAML, TOML, jq, and aligned JSONC spacing under their existing validators. Ruff handles Python lint/format; Pylance uses strict Pyright settings. Keep checker packages out of runtime images.

## Prepare a pull request 🪝

1. Choose checks from [developer testing](development/maraudarr/testing.md) for the changed boundary. Live tests require separate isolated deployment preparation; read the [live testing guide](https://github.com/scottgigawatt/plundarr/blob/main/test/README.md) first.
2. For generated-chart changes, run real Compose validation without printing secrets and [verify preset examples](https://github.com/scottgigawatt/plundarr/blob/main/examples/presets/README.md) from the source under review.
3. For documentation, run `make docs`, spelling and Markdown/pre-commit checks; inspect rendering, changed links/anchors, and representative reader tasks.
4. Review the complete diff and run `git diff --check`. Report commands actually run, failures/skips, and remaining limits alongside the problem and resulting behavior.

Use [support](SUPPORT.md) for non-sensitive questions and the [security policy](SECURITY.md) for private vulnerability reporting. Small, coherent pull requests make fewer tentacles for the reviewer. 🐙
