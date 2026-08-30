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

Maraudarr is the short-lived generator image inside the Plundarr repository. It loads a preset, resolves required services, preserves the handwritten Compose comments, and writes a deployable Plundarr project into the mounted repository:

```text
dist/<preset>/
├── docker-compose.yml
├── example.env
├── .env
└── config/
```

> [!IMPORTANT]
> **Plundarr** is the generated media stack. **Maraudarr** is only the tool that builds it. The image does not run the selected media services.

## Take the Quick Passage 🧭

Run these commands from the repository root. Make keeps the Docker wiring out of sight and prints only the useful status and Maraudarr output.

| Command | What It Does |
| --- | --- |
| `make ship` | Prepares Maraudarr and generates the default Plundarr stack |
| `make configure` | Opens the interactive preset and service picker |
| `make presets` | Lists every preset and its exact defaults |
| `make services` | Lists every selectable service |
| `make watchtower-run-once PRESET=watchtower` | Runs one host update pass and exits |
| `make overlay-reset PRESET=duplex` | Runs profile-gated Overlay Reset once and exits |
| `make pull-image` | Pulls the latest published Maraudarr image from GHCR |
| `make build` | Builds the Maraudarr image locally from this directory |
| `make test-unit` | Runs Maraudarr's Python unit tests |
| `make test-workflows` | Checks workflow helpers and shared publishing policy |
| `make test` | Runs unit, helper, policy, and real Compose matrix tests |
| `make build-platforms` | Verifies all published CPU architectures |

Maraudarr uses a matching local image first. When none exists, Make tries GHCR and automatically builds from this checkout if the published image is not yet available. No pull-skip variable be needed.

Refresh or rebuild Maraudarr explicitly when ye want a different image:

> [!TIP]
>
> ```sh
> make pull-image
> make build
> ```

Add optional cargo without opening the interactive prompts:

> [!TIP]
>
> ```sh
> make ship PRESET=boudoirr ADD_SERVICES=jellyfin
> make ship PRESET=jellyfin
> make ship PRESET=plex
> make ship PRESET=duplex
> make ship PRESET=watchtower
> make ship ADD_SERVICES=sonarr-anime
> ```

`ADD_SERVICES` and `REMOVE_SERVICES` accept comma-separated service IDs. Plundarr and Boudoirr preselect qBittorrent as their only downloader and include Watchtower as a removable default. SABnzbd and NZBGet remain ordinary opt-in choices:

The first command selects Usenet only. The second keeps torrents, adds Usenet, and opts into update checks:

> [!TIP]
>
> ```sh
> make ship REMOVE_SERVICES=qbittorrent,cleanuparr ADD_SERVICES=sabnzbd
> make ship PRESET=boudoirr ADD_SERVICES=sabnzbd
> ```

The default Plundarr voyage includes one Sonarr instance. `sonarr-anime` is an opt-in second instance with its own configuration and library path.

The `watchtower` preset runs the maintained `nickfedor/watchtower:latest` image persistently. Use `make watchtower-run-once PRESET=watchtower` instead for one host-wide update pass that exits when complete. Run only one persistent Watchtower daemon per Docker host.

The `duplex` preset uses Kometa, ImageMaid, PATTRMM, Tautulli, Notifiarr, and Overlay Reset. Kometa's config is an external checkout selected with `KOMETA_CONFIG_PATH`; Maraudarr does not create a submodule or manage that repository. PATTRMM, Notifiarr, and Overlay Reset are removable defaults, while Watchtower remains available as an explicit addition. The Overlay Reset service is profile-gated and defaults to a dry run when invoked with `make overlay-reset PRESET=duplex`.

## What Be in This Image? 📦

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

## Keep the Powder Dry 🔐

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

Maraudarr validates every generated pair with its bundled standalone `docker-compose config --quiet` command before replacing a preset's output. The explicit `make delete-config PRESET=<preset>` target is the only normal path that removes a complete config hold.

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

Major version zero omits the broad `0` alias. Prereleases publish only their exact version and immutable `sha-...` tag; they never move stable aliases. Release publication additionally requires a `v`-prefixed annotated SemVer tag whose commit already belongs to `main`.

Published platforms are `linux/amd64`, `linux/arm64`, and `linux/arm/v7`. Builds include OCI metadata, an SBOM, provenance, and a Trivy gate for high and critical image vulnerabilities.

> [!NOTE]
> GHCR may show `unknown/unknown` attestation entries beside runnable platforms. Those are provenance or SBOM manifests, not broken container images.

## Maintain the Riggin' 🛠️

Run host-side tests while editing Python or service charts:

> [!TIP]
>
> ```sh
> make test-unit
> ```

Then fire the complete checks:

> [!IMPORTANT]
>
> ```sh
> make test
> make build
> make build-platforms
> pre-commit run --all-files
> ```

> [!TIP]
> New services belong under `services/<name>/`. Do not revive aggregate "extras" or "addons" charts; one service directory is one maintainable unit.
