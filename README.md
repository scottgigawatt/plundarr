<!-- markdownlint-disable-next-line MD033 MD041 -->
<p align="center">
  <em>🏴‍☠️ Generate one media stack, edit one environment file, and keep the fleet under control.</em>
</p>

<!-- markdownlint-disable MD033 -->
<p align="center">
  <a href="https://github.com/scottgigawatt/plundarr/actions/workflows/build-and-push.yml"><img src="https://github.com/scottgigawatt/plundarr/actions/workflows/build-and-push.yml/badge.svg" alt="Maraudarr build status" /></a>
  <img src="https://img.shields.io/github/license/scottgigawatt/plundarr?label=License" alt="Apache 2.0 license" />
  <img src="https://img.shields.io/badge/Platforms-amd64%20%7C%20arm64%20%7C%20arm%2Fv7-blue?logo=docker" alt="Published for amd64, arm64, and arm/v7" />
  <img src="https://img.shields.io/badge/Scanned-Trivy-1904DA?logo=aqua" alt="Container image scanned with Trivy" />
  <img src="https://img.shields.io/badge/Tested-Synology%20%7C%20macOS-blue" alt="Tested on Synology and macOS" />
</p>

<p align="center">
  <a href="https://discord.gg/BpEGzWwGYf"><img src="https://img.shields.io/discord/1403601106315116626?label=%F0%9F%94%A5HADES%F0%9F%94%A5&logo=discord&logoColor=white&color=5865F2" alt="HADES Discord community" /></a>
</p>
<!-- markdownlint-enable MD033 -->

# Plundarr 🏴‍☠️

Plundarr generates a complete, single-file Docker Compose media stack from the services you select. Each deployment lands in `dist/<preset>/` with one commented `docker-compose.yml`, one editable `.env`, and the selected service configuration directories.

The generated project works with Docker Compose and Synology Container Manager. Routine configuration stays in the deployment's `.env`; you do not need to assemble Compose fragments by hand.

## Understand Plundarr and Maraudarr

The project has two deliberately separate parts:

- **Maraudarr is the generator.** It resolves presets, services, and dependencies; preserves existing environment values and application state; validates the generated project; and exits.
- **Plundarr is the generated deployment.** It remains on your host and runs the selected services from `dist/<preset>/`.

Maraudarr images are published to [GitHub Container Registry](https://github.com/scottgigawatt/plundarr/pkgs/container/maraudarr) and [Docker Hub](https://hub.docker.com/r/scottgigawatt/maraudarr). `make ship` uses the published image when available and can build it from the checkout as a fallback.

## Generate the default stack ⚡

The default voyage creates the `plundarr` preset with qBittorrent as its downloader:

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

| Preset | Primary purpose |
| --- | --- |
| `plundarr` | Movies and television automation with a VPN-protected torrent downloader |
| `boudoirr` | Whisparr automation with a VPN-protected torrent downloader |
| `jellyfin` | Standalone Jellyfin media server |
| `plex` | Standalone Plex Media Server |
| `duplex` | Plex metadata, artwork, monitoring, and maintenance tools |
| `watchtower` | Standalone container image updates |
| `custom` | A stack assembled service by service |

Inspect the current catalog before generating:

```sh
make presets
make services
```

The catalog includes VPN foundations, torrent and Usenet clients, media automation, Jellyfin and Plex, Plex utilities, notifications, backups, dashboards, monitoring, and maintenance tools. Maraudarr adds required dependencies and displays the resolved fleet before writing it.

## Customize a deployment 🧩

`ADD_SERVICES` and `REMOVE_SERVICES` accept comma-separated service IDs. Preset core services cannot be removed; removable defaults and optional services can be changed interactively or on the command line.

Generate common combinations:

```sh
make ship PRESET=boudoirr ADD_SERVICES=jellyfin
make ship ADD_SERVICES=sonarr-anime
make ship ADD_SERVICES=sabnzbd
make ship REMOVE_SERVICES=qbittorrent,cleanuparr ADD_SERVICES=nzbget
make ship PRESET=duplex ADD_SERVICES=watchtower
```

Regeneration preserves existing values by variable name and does not replace application state. Values for temporarily unselected services remain in a marked footer so they can return when the service is selected again.

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
- **Storage:** Download, movie, television, anime, scene, Jellyfin, Plex, Kometa, and backup paths selected by the stack.
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
- [Testing](test/README.md): Generator, workflow, VPN, and stack validation.
- [Support](docs/SUPPORT.md): Usage questions, bugs, documentation requests, and safe reporting routes.
- [Contributing](docs/CONTRIBUTING.md): Development setup and pull request expectations.
- [Security policy](docs/SECURITY.md): Supported versions and private vulnerability reporting.
- [Code of Conduct](docs/CODE_OF_CONDUCT.md): Community expectations and enforcement.

## Compatibility and licensing ⚖️

Maraudarr is published for `linux/amd64`, `linux/arm64`, and `linux/arm/v7`. Individual third-party service images may support fewer architectures. Plundarr is tested with Synology Container Manager and Docker Desktop on macOS; compatible Linux Docker hosts are expected to work.

Plundarr is licensed under the [Apache License 2.0](LICENSE). It consumes the published Privateerr image and does not vendor the upstream PIA manual-connection scripts.

Fair winds, clean logs, and may your containers never mutiny. 🏴‍☠️
