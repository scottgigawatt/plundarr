<!-- markdownlint-disable-next-line MD033 MD041 -->
<hr />

<!-- markdownlint-disable MD033 -->
<p align="center">
  <em>🏴‍☠️ Enjoyin' the spoils? Drop us a ⭐ an' let the whole crew know this chart helped.</em>
</p>

<p align="center">
  <a href="https://github.com/scottgigawatt/plundarr/stargazers"><img src="https://img.shields.io/github/stars/scottgigawatt/plundarr?style=social&amp;label=Treasure%20Hunters" alt="GitHub stars: Treasure Hunters" /></a>
  <a href="https://github.com/scottgigawatt/plundarr/forks"><img src="https://img.shields.io/github/forks/scottgigawatt/plundarr?style=social&amp;label=Mutinous%20Forks" alt="GitHub forks: Mutinous Forks" /></a>
  <a href="https://github.com/scottgigawatt/plundarr/watchers"><img src="https://img.shields.io/github/watchers/scottgigawatt/plundarr?style=social&amp;label=Crow%27s%20Nest%20Lookouts" alt="GitHub watchers: Crow's Nest Lookouts" /></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Containers-Ahoy%21-2496ED?logo=docker&amp;logoColor=white" alt="Containers: Ahoy!" />
  <img src="https://img.shields.io/badge/Cloaked-by%20PIA%20%26%20WireGuard-2EA44F?logo=wireguard&amp;logoColor=white" alt="Cloaked by PIA and WireGuard" />
  <a href="./LICENSE"><img src="https://img.shields.io/github/license/scottgigawatt/plundarr?label=Legal%20Scroll&amp;color=8250DF" alt="Legal Scroll: Apache 2.0 license" /></a>
</p>

<p align="center">
  <a href="https://github.com/scottgigawatt/plundarr/commits/main"><img src="https://img.shields.io/github/last-commit/scottgigawatt/plundarr?label=Last%20Plunder&amp;logo=git&amp;color=D97706" alt="Date of the last commit to main" /></a>
  <img src="https://img.shields.io/badge/Sea--Tested-Synology%20%7C%20macOS-0891B2" alt="Sea-tested on Synology and macOS" />
  <img src="https://img.shields.io/badge/Rum%20Supply-Full-C2410C" alt="Rum supply: Full" />
</p>

<p align="center">
  <a href="https://github.com/scottgigawatt/plundarr/actions/workflows/build-and-push.yml"><img src="https://img.shields.io/github/actions/workflow/status/scottgigawatt/plundarr/build-and-push.yml?branch=main&amp;label=Maraudarr%20build&amp;logo=githubactions&amp;logoColor=white" alt="Maraudarr build status on main" /></a>
  <a href="https://github.com/scottgigawatt/plundarr/pkgs/container/maraudarr"><img src="https://img.shields.io/badge/Fleet-amd64%20%7C%20arm64%20%7C%20arm%2Fv7-6D28D9?logo=docker&amp;logoColor=white" alt="Maraudarr images for amd64, arm64, and arm/v7" /></a>
  <a href="https://github.com/scottgigawatt/plundarr/actions/workflows/build-and-push.yml"><img src="https://img.shields.io/badge/Bilge%20Check-Trivy-BE185D?logo=aqua&amp;logoColor=white" alt="Container images scanned with Trivy" /></a>
</p>

<p align="center">─── ⛧ ───</p>

<p align="center">
  <em>☠️ Questions or cursed code? Cross the Styx — <strong>enter 🔥HADES🔥</strong>.</em>
</p>

<p align="center">
  <a href="https://discord.gg/BpEGzWwGYf"><img src="https://img.shields.io/discord/1403601106315116626?label=%F0%9F%94%A5HADES%F0%9F%94%A5&logo=discord&logoColor=white&color=5865F2" alt="HADES Discord community" /></a>
</p>
<!-- markdownlint-enable MD033 -->

<!-- markdownlint-disable-next-line MD033 -->
<hr />

# Plundarr 🏴‍☠️

Plundarr is a generated, ready-to-run Docker Compose media stack built from the services you select. Maraudarr—the Docker Compose project generator included in this repository—turns that selection into one complete deployment under `dist/<preset>/`, with a commented `docker-compose.yml`, an editable `.env`, and the selected service configuration directories.

Each generated Compose project works with Docker Compose and Synology Container Manager. Routine configuration stays in the deployment's `.env`; you do not need to assemble Compose fragments by hand.

## Understand Plundarr and Maraudarr

The repository has two deliberately separate parts:

- **Maraudarr is the Docker Compose project generator.** It resolves the selected preset, services, and dependencies; writes and validates the complete Compose project under `dist/<preset>/`; preserves existing environment values and application state; and exits.
- **Plundarr is the generated Docker Compose deployment.** It remains on your host and runs the selected services from `dist/<preset>/` after Maraudarr has finished.

VPN-enabled presets use [Privateerr](https://github.com/scottgigawatt/privateerr) to generate PIA WireGuard configuration and [Gluetun](https://github.com/qdm12/gluetun) to establish and maintain the actual VPN tunnel.

Maraudarr images are published to [GitHub Container Registry](https://github.com/scottgigawatt/plundarr/pkgs/container/maraudarr) and [Docker Hub](https://hub.docker.com/r/scottgigawatt/maraudarr). `make ship` runs that Compose project generator from the published image when available and can build it from the checkout as a fallback.

## Generate the default stack ⚡

Before you begin, install Git, Docker with Docker Compose, and Make. The default `plundarr` preset is VPN-enabled and requires an active PIA subscription; the standalone media-server and utility presets do not. This first voyage creates the movie, television, and ebook stack with qBittorrent as its downloader and Calibre-Web Automated as a removable default:

```sh
git clone https://github.com/scottgigawatt/plundarr.git
cd plundarr
make ship
```

Maraudarr writes:

```text
dist/
└── plundarr/
    ├── docker-compose.yml
    ├── example.env
    ├── .env
    └── config/
```

When generation finishes, Maraudarr exits. The files in `dist/plundarr/` are the Plundarr deployment you configure, start, stop, and maintain. Other preset selections use their matching `dist/<preset>/` directory.

> [!IMPORTANT]
> Review `dist/plundarr/.env` before launch. Set real PIA credentials for VPN-enabled presets and confirm host storage paths, user and group IDs, timezone, network values, and published ports.

Start the generated project:

```sh
make up
```

<!-- markdownlint-disable MD033 -->
<details>
<summary>Watch Maraudarr generate and start the default stack</summary>

The recording shows `make configure`, `make up`, and `make ps` using `dist/plundarr/`.

<img src="./docs/assets/maraudarr-demo.gif" width="1000" alt="Maraudarr selects services, generates a Plundarr project, and starts its Docker Compose services" />

You can inspect or replay the [recording source](./docs/demo/record-maraudarr-demo.sh).

</details>
<!-- markdownlint-enable MD033 -->

## Choose a preset 🗺️

Use `make configure` for an interactive picker or pass `PRESET` to `make ship` for a repeatable build.

| 🗺️ Preset | 🎯 Primary purpose |
| --- | --- |
| 🏴‍☠️ `plundarr` | Movies, television, and ebooks with a VPN-protected torrent downloader |
| 🔞 `boudoirr` | Whisparr automation with a VPN-protected torrent downloader |
| 🎞️ `jellyfin` | Standalone Jellyfin media server |
| 🎬 `plex` | Standalone Plex Media Server |
| 📚 `calibre-web-automated` | Standalone ebook library and automatic ingest service |
| 🎭 `duplex` | Plex metadata, artwork, monitoring, and maintenance tools |
| 🔭 `watchtower` | Standalone container image updates |
| 🧩 `custom` | A stack assembled service by service |

Inspect the current catalog before generating:

```sh
make presets
make services
```

The catalog includes VPN foundations, torrent and Usenet clients, movie, television, music, subtitle, and quality-profile automation, Jellyfin and Plex, Plex utilities, notifications, backups, dashboards, monitoring, and maintenance tools. Maraudarr adds required dependencies and displays the resolved fleet before writing it.

## Customize a deployment 🧩

`ADD_SERVICES` and `REMOVE_SERVICES` accept comma-separated service IDs. Preset core services cannot be removed; removable defaults and optional services can be changed interactively or on the command line.

Generate common combinations:

```sh
make ship PRESET=boudoirr ADD_SERVICES=jellyfin
make ship PRESET=calibre-web-automated
make ship ADD_SERVICES=lidarr
make ship ADD_SERVICES=recyclarr
make ship ADD_SERVICES=lidarr,recyclarr
make ship ADD_SERVICES=sonarr-anime
make ship ADD_SERVICES=sabnzbd
make ship REMOVE_SERVICES=qbittorrent,cleanuparr ADD_SERVICES=nzbget
make ship REMOVE_SERVICES=calibre-web-automated
make ship PRESET=duplex ADD_SERVICES=watchtower
```

Regeneration preserves existing values by variable name and does not replace application state. Values for temporarily unselected services remain in a marked footer so they can return when the service is selected again.

### Configure Lidarr

Add Lidarr to Plundarr for music automation:

```sh
make ship ADD_SERVICES=lidarr
```

Set `HOST_MUSIC_PATH` to the host music library. Lidarr receives it read/write at `/music` and shares `/downloads` with the selected download clients. Open Lidarr after launch, use `/music` as its root folder, then connect Prowlarr and a download client. When Plex is also selected, Maraudarr adds the same library read-only at `/music`; Jellyfin reaches it as `/data/music` when its data root and the Plundarr media root point to the same host directory. The generated Homepage card requires a Lidarr API key in `HOMEPAGE_VAR_LIDARR_KEY`.

The [LinuxServer Lidarr image](https://docs.linuxserver.io/images/docker-lidarr/) supports `linux/amd64` and `linux/arm64`, not `linux/arm/v7`. The [Homepage Lidarr widget guide](https://gethomepage.dev/widgets/services/lidarr/) documents the API key and supported fields used by the generated card.

### Preview and sync Recyclarr

Add the profile-gated Recyclarr tool. Its catalog dependencies ensure Radarr and Sonarr are present:

```sh
make ship ADD_SERVICES=recyclarr
```

Set the selected service URLs and API keys in `dist/plundarr/.env`, then review the regeneration-safe starter file at `dist/plundarr/config/recyclarr/recyclarr.yml`. The starter syncs only upstream quality-size definitions and leaves old custom formats intact.

Preview first, then deliberately apply the same configuration:

```sh
make recyclarr-preview
make recyclarr-sync
```

> [!CAUTION]
> `make recyclarr-sync` changes the configured Radarr and Sonarr instances. Recyclarr never starts during ordinary `make up`; use the preview output to verify the target instances and proposed changes before applying them.

See the official [Recyclarr feature reference](https://recyclarr.dev/guide/features/) and [`sync` command reference](https://recyclarr.dev/cli/sync/) before extending the starter configuration.

### Configure Calibre-Web Automated

Calibre-Web Automated is removable default cargo in Plundarr and also has a focused standalone preset:

```sh
make ship PRESET=calibre-web-automated
make up PRESET=calibre-web-automated
```

Set `CWA_CONFIG_PATH`, `CWA_INGEST_PATH`, and `CWA_LIBRARY_PATH` to three separate host directories. The ingest directory is destructive: CWA removes books after processing them, so finish downloads elsewhere and move only completed files into it. Preserve the complete config directory and the Calibre library containing `metadata.db` in backups. Set `CWA_NETWORK_SHARE_MODE=true` only for NFS or SMB storage.

CWA image updates remain excluded from Watchtower so database migrations stay under operator control. The published CWA image supports `linux/amd64` and `linux/arm64`, not `linux/arm/v7`.

### Configure Duplex

Generate the Plex maintenance preset:

```sh
make ship PRESET=duplex
```

Set `KOMETA_CONFIG_PATH` to an independently managed Kometa checkout containing its `config.yml`, assets, metadata, and overlays. Set `IMAGEMAID_PLEX_PATH` to Plex application data containing `Cache`, `Metadata`, and `Plug-in Support`.

Kometa Overlay Reset remains behind the `tools` Compose profile and never starts during ordinary `make up` runs. Keep `OVERLAY_RESET_DRY_RUN=True`, inspect the dry-run output, and invoke the tool explicitly:

```sh
make kometa-overlay-reset PRESET=duplex
```

### Run Watchtower

Run Watchtower as a persistent standalone project:

```sh
make ship PRESET=watchtower
make up PRESET=watchtower
```

Use the same generated project for one update pass:

```sh
make watchtower-run-once PRESET=watchtower
```

Run only one persistent Watchtower daemon per Docker host and stop it before a one-shot pass. Containers with `com.centurylinklabs.watchtower.enable=false` remain excluded.

## Configure the important values ⚙️

Maraudarr writes only variables used by the selected services. Start with these groups in `dist/<preset>/.env`:

- **Credentials:** `PIA_USER` and `PIA_PASS` for VPN-enabled presets.
- **Host identity:** `DEFAULT_PUID`, `DEFAULT_PGID`, and service-specific user or group IDs.
- **Storage:** Download, movie, television, anime, scene, ebook, Jellyfin, Plex, Kometa, and backup paths selected by the stack.
- **Networking:** Project subnet, gateway, address range, and `*_WEBUI_PORT` values when defaults collide.
- **Time:** `TZ` and service schedules.

Configuration remains under `dist/<preset>/config/` unless you deliberately change a generated path. Read the [Docker and Synology setup guide](docs/setup.md) for network planning, firewall rules, side-by-side presets, and media-library mounts.

## Deploy with Synology Container Manager 📦

Each preset is already a complete one-file Container Manager project:

1. Keep `.env` beside `docker-compose.yml` in `dist/<preset>/`.
2. Create a Container Manager project from that preset directory.
3. Select its `docker-compose.yml`.
4. Review the generated settings and deploy the project.

The same generated files work with ordinary Docker Compose; Synology does not receive a reduced or separate chart.

## Inspect and maintain the stack 🔎

Use `make help` for the complete command reference. Common checks include:

```sh
make config
make env
make ps
make test
```

`make clean` removes disposable repository artifacts only. `make down PRESET=<preset>` stops the selected project while preserving volumes, images, `.env`, config, backups, and generated credentials.

> [!CAUTION]
> `make nuke PRESET=<preset>` removes attributable Docker resources, images, volumes, and scoped build cache for the selected deployment and the separate Maraudarr project. It preserves deployment files and application config. Only `make delete-config PRESET=<preset>` deletes application state; back up the deployment before using it.

VPN and full-stack tests can use real PIA credentials and launch containers. Read the [testing guide](test/README.md) before running `make test-vpn`, `make test-e2e`, or `make test-stack`.

## Read more and get help 📚

- [Developer documentation](https://scottgigawatt.github.io/plundarr/): Maraudarr architecture, extension guides, and Python reference.
- [Docker and Synology setup](docs/setup.md): Networks, firewall rules, Container Manager, and library mounts.
- [Host helper scripts](scripts/README.md): Linux, Synology, backup, restart, and status helpers.
- [Testing](test/README.md): Maraudarr, generated Compose projects, workflows, VPN connections, and full-stack validation.
- [Support](docs/SUPPORT.md): Usage questions, bugs, documentation requests, and safe reporting routes.
- [Contributing](docs/CONTRIBUTING.md): Development setup and pull request expectations.
- [Security policy](docs/SECURITY.md): Supported versions and private vulnerability reporting.
- [Code of Conduct](docs/CODE_OF_CONDUCT.md): Community expectations and enforcement.

## Compatibility and licensing ⚖️

Maraudarr is published for `linux/amd64`, `linux/arm64`, and `linux/arm/v7`. Individual third-party service images may support fewer architectures. Plundarr is tested with Synology Container Manager and Docker Desktop on macOS; compatible Linux Docker hosts are expected to work.

Plundarr is licensed under the [Apache License 2.0](LICENSE). It consumes the published Privateerr image and does not vendor the upstream PIA manual-connection scripts.

Fair winds, clean logs, and may your containers never mutiny. 🏴‍☠️
