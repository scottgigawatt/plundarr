# Maraudarr ⚒️

Maraudarr generates Plundarr Compose deployments and exits. It resolves selected services, preserves Compose comments and existing operator state, and validates the files before publishing them under `dist/<preset>/`.

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

## Generate a deployment

Use the [repository quickstart](../README.md#generate-the-default-stack-) for prerequisites, image selection, generation, and startup. Run Make commands from the repository root. `MARAUDARR_IMAGE` chooses the packaged source/catalog; mounting a checkout does not make that image use live Python source.

The [setup guide](../docs/setup.md) covers Docker/Synology deployment and service preparation. `make help` lists operations; the [testing guide](../docs/development/maraudarr/testing.md) explains validation by changed boundary.

## Explore the image contents 📦

The `docker/` directory is the complete build context. Nothing outside it is copied into Maraudarr.

| Hold | Cargo |
| --- | --- |
| 🐍 `src/maraudarr/` | Catalog loading, rendering, config seeding, and terminal UI |
| 🗺️ `catalog/` | Service order, dependencies, descriptions, and presets |
| 🧱 `templates/` | Shared Compose anchors and environment defaults |
| 🧩 `services/` | One Compose chart, environment fragment, and config seed per service |
| 🧪 `tests/` | Python unit tests |
| 🚪 `maraudarr-entrypoint.sh` | PID 1 signal handoff to the Python command |

Folder-level README files explain each maintenance boundary. The scoped [`AGENTS.md`](AGENTS.md) records the same rules for coding agents.

## Understand runtime guardrails 🔐

The published image and Make targets use a deliberately narrow runtime:

| Guardrail | Behavior |
| --- | --- |
| 👤 Unprivileged identity | Image UID, GID, and group name are configurable; Make uses the invoking host user |
| 🔒 Read-only image | Only the mounted repository and `/tmp` are writable |
| 🌐 No network | Generation runs with `--network none` |
| ✂️ No capabilities | Every optional Linux capability is dropped |
| 🧱 No escalation | `no-new-privileges` is enforced |
| 🧾 Atomic output | Compose and environment files replace their targets only after validation |
| 🗃️ State preservation | Existing application config files are never deleted during regeneration |

Maraudarr validates every generated pair with its bundled standalone `docker-compose config --quiet` command before replacing a preset's output. The explicit `make delete-config PRESET=YOUR-PRESET` target is the only normal path that removes a complete config hold.

## Choose a registry tag 🗂️

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

Major version zero omits the broad `0` alias. Prereleases publish only their exact version and immutable `sha-...` tag; they never move stable aliases. Release publication additionally requires a `v`-prefixed annotated SemVer tag whose commit already belongs to `main`.

Published platforms are `linux/amd64`, `linux/arm64`, and `linux/arm/v7`. Builds include OCI metadata, an SBOM, provenance, and a Trivy gate for high and critical image vulnerabilities.

> [!NOTE]
> GHCR may show `unknown/unknown` attestation entries beside runnable platforms. Those are provenance or SBOM manifests, not broken container images.

## Maintain Maraudarr 🛠️

Each selectable service is one catalog unit under `services/<name>/`. Follow [adding a service](../docs/development/maraudarr/adding-a-service.md), the scoped [agent guidance](AGENTS.md), and the [developer overview](../docs/development/maraudarr/index.md). Keep runtime dependencies and the complete image build context here; keep developer tools out of production.
