<!-- markdownlint-disable MD033 -->
<!-- markdownlint-disable MD041 -->
<p align="center">
  <strong>🏴‍☠️ Maraudarr</strong><br />
  <em>The little image that charts a whole Plundarr fleet.</em>
</p>

<p align="center">
  <a href="https://github.com/scottgigawatt/plundarr/actions/workflows/build-and-push.yml"><img src="https://github.com/scottgigawatt/plundarr/actions/workflows/build-and-push.yml/badge.svg" alt="Maraudarr Build" /></a>
  <img src="https://img.shields.io/badge/Fleet-amd64%20%7C%20arm64%20%7C%20arm%2Fv7-blue?logo=docker" alt="Multi-Architecture Fleet" />
  <img src="https://img.shields.io/badge/Run%20As-Non--Root-success" alt="Runs as non-root" />
  <img src="https://img.shields.io/badge/Bilge%20Check-Trivy-1904DA?logo=aqua" alt="Scanned with Trivy" />
</p>
<!-- markdownlint-enable MD033 -->

# Maraudarr ⚒️

Maraudarr is the short-lived generator image inside the Plundarr repository. It
loads a preset, resolves required services, preserves the handwritten Compose
comments, and writes a deployable Plundarr project into the mounted repository:

```text
docker-compose.yml
example.env
.env
config/
```

> [!IMPORTANT]
> **Plundarr** is the generated media stack. **Maraudarr** is only the tool that
> builds it. The image does not run the selected media services.

## Take the Quick Passage 🧭

Run these commands from the repository root. Make prints the complete Docker
command before Maraudarr leaves port.

| Command                    | What It Does                                                                 |
| -------------------------- | ---------------------------------------------------------------------------- |
| `make ship`                | Prepares Maraudarr and generates the default Plundarr stack                  |
| `make configure`           | Opens the interactive preset and service picker                              |
| `make presets`             | Lists every preset and its exact defaults                                    |
| `make services`            | Lists every selectable service                                               |
| `make update-maraudarr`    | Refreshes the published Maraudarr image from GHCR                            |
| `make build-maraudarr`     | Builds the Maraudarr image locally from this directory                       |
| `make test-maraudarr-unit` | Runs Maraudarr's Python unit tests                                           |
| `make test-maraudarr`      | Runs unit tests and the real Compose matrix                                  |
| `make build-multiarch`     | Verifies all published CPU architectures                                     |

Maraudarr uses a matching local image first. When none exists, Make tries GHCR
and automatically builds from this checkout if the published image is not yet
available. No pull-skip variable be needed.

Refresh or rebuild Maraudarr explicitly when ye want a different image:

```bash
make update-maraudarr
make build-maraudarr
```

Add optional cargo without opening the interactive prompts:

```bash
make ship OPTIONAL_SERVICES=qbittorrent,cleanuparr,apprise,jellyfin
```

## What Be in This Image? 📦

The `docker/` directory is the complete build context. Nothing outside it is
copied into Maraudarr.

| Hold                         | Cargo                                                                |
| ---------------------------- | -------------------------------------------------------------------- |
| 🐍 `src/maraudarr/`          | Catalog loading, rendering, config seeding, and terminal UI          |
| 🗺️ `catalog/`                | Service order, dependencies, descriptions, and presets               |
| 🧱 `templates/`              | Shared Compose anchors and environment defaults                      |
| 🧩 `services/`               | One Compose chart, environment fragment, and config seed per service |
| 🧪 `tests/`                  | Python unit tests                                                    |
| 🚪 `maraudarr-entrypoint.sh` | PID 1 signal handoff to the Python command                           |

Folder-level README files explain each maintenance boundary. The scoped
[`AGENTS.md`](AGENTS.md) records the same rules for coding agents.

## Keep the Powder Dry 🔐

The published image and Make targets use a deliberately narrow runtime:

| Guardrail                | Behavior                                                                  |
| ------------------------ | ------------------------------------------------------------------------- |
| 👤 Unprivileged identity | Image UID and GID are configurable; Make uses the invoking host user      |
| 🔒 Read-only image       | Only the mounted repository and `/tmp` are writable                       |
| 🌐 No network            | Generation runs with `--network none`                                     |
| ✂️ No capabilities       | Every optional Linux capability is dropped                                |
| 🧱 No escalation         | `no-new-privileges` is enforced                                           |
| 🧾 Atomic output         | Compose and environment files replace their targets only after validation |
| 🗃️ State preservation    | Existing application config files are never deleted during regeneration   |

Maraudarr validates every generated pair with `docker compose config --quiet`
before replacing root output. The explicit `make clean-config` target is the
only normal path that removes the complete config hold.

## Registry Charts 🗂️

Release workflows publish the same multi-architecture manifest to:

```text
ghcr.io/scottgigawatt/maraudarr
docker.io/scottgigawatt/maraudarr
```

| Tag                 | Meaning                                        |
| ------------------- | ---------------------------------------------- |
| `latest`            | Latest stable semantic-version release         |
| `1.2.3`, `1.2`, `1` | Stable release aliases generated from `v1.2.3` |
| `edge`              | Latest successful build from `main`            |
| `sha-...`           | Immutable source revision build                |

Published platforms are `linux/amd64`, `linux/arm64`, and `linux/arm/v7`.
Builds include OCI metadata, an SBOM, provenance, and a Trivy gate for high and
critical image vulnerabilities.

> [!NOTE]
> GHCR may show `unknown/unknown` attestation entries beside runnable platforms.
> Those are provenance or SBOM manifests, not broken container images.

## Maintain the Riggin' 🛠️

Run host-side tests while editing Python or service charts:

```bash
make test-maraudarr-unit
```

Then fire the complete checks:

```bash
make test-maraudarr
make build-maraudarr
pre-commit run --all-files
```

> [!TIP]
> New services belong under `services/<name>/`. Do not revive aggregate
> "extras" or "addons" charts; one service directory is one maintainable unit.
