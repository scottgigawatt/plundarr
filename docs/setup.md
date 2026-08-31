# Set up Plundarr with Docker or Synology ⚓

This guide generates a Plundarr deployment, reviews the host-specific settings, and launches the resulting one-file Docker Compose project with Docker Compose or Synology Container Manager.

## Generate a deployment

Run the interactive Maraudarr Docker Compose project generator from the repository:

```sh
make configure
```

For a repeatable non-interactive build, select a preset and optional services directly:

```sh
make ship
make ship PRESET=boudoirr ADD_SERVICES=jellyfin
make ship PRESET=jellyfin
make ship PRESET=plex
make ship PRESET=calibre-web-automated
make ship PRESET=duplex
make ship PRESET=watchtower
make ship ADD_SERVICES=lidarr
make ship ADD_SERVICES=recyclarr
make ship ADD_SERVICES=sonarr-anime
```

For a Usenet-only Plundarr deployment, remove the default torrent client and its cleanup companion:

```sh
make ship REMOVE_SERVICES=qbittorrent,cleanuparr ADD_SERVICES=sabnzbd
```

Maraudarr writes a complete project beneath `dist/<preset>/`:

```text
dist/<preset>/
├── docker-compose.yml
├── example.env
├── .env
└── config/
```

> [!IMPORTANT]
> Review the generated `.env` before launch. Confirm user and group IDs, host storage paths, timezone, project network values, and published ports. Presets containing Privateerr and Gluetun also require real `PIA_USER` and `PIA_PASS` values; startup rejects missing or generated example credentials.

## Plan project networks

Maraudarr gives each preset a distinct Compose project, bridge network, and default host-port range so fresh deployments can run side by side.

| Preset | Project | Default subnet | Published ports |
| --- | --- | --- | --- |
| Plundarr | `plundarr` | `172.20.0.0/16` | Standard service ports; CWA `8213` |
| Boudoirr | `boudoirr` | `172.21.0.0/16` | Selected ports offset by `10000` |
| Jellyfin | `jellyfin` | `172.22.0.0/16` | Jellyfin `28096` |
| Plex | `plex` | `172.23.0.0/16` | Plex host networking |
| Calibre-Web Automated | `calibre-web-automated` | `172.24.0.0/16` | CWA `48213` |
| Duplex | `duplex` | `172.25.0.0/16` | Tautulli `8181`; Notifiarr `5454` |
| Paperless reservation | External project | `172.26.0.0/16` | Reserved outside the Maraudarr catalog |
| Watchtower | `watchtower` | `172.27.0.0/16` | No published ports |
| Custom | `custom` | `172.28.0.0/16` | Selected ports offset by `30000` |

Every bridge-network preset uses `.5.0/24` as its container address pool and `.5.254` as its gateway inside the listed `/16`. The `172.26.0.0/16` reservation keeps the separately deployed Paperless project in sequence without pretending it is a Maraudarr preset. Container names include the project, service, and image tag, such as `plundarr-bazarr-latest`.

Change the generated network only when it overlaps another Docker network, virtual private network (VPN), local-area network route, or host service. Update `COMPOSE_NETWORK_SUBNET`, `COMPOSE_NETWORK_IP_RANGE`, and `COMPOSE_NETWORK_GATEWAY` together. The [Docker Compose IPAM reference](https://docs.docker.com/compose/compose-file/06-networks/#ipam) explains custom address planning.

Plex uses host networking. Only one Plex server can claim its standard host ports unless Plex itself is configured differently.

## Launch with Docker Compose

Start the selected preset through Make:

```sh
make up PRESET=<preset>
```

Omit `PRESET` for the default `plundarr` deployment. Inspect the resolved Compose model and service status with:

```sh
make config PRESET=<preset>
make ps PRESET=<preset>
```

## Configure the Synology firewall

If the Synology firewall is enabled, add one allow rule for every deployed preset that uses a bridge network. Plex uses host networking and does not need a preset-subnet rule.

For the default Plundarr network:

1. Open **Control Panel**, then **Security**, then **Firewall**.
2. Select **Edit Rules**, then **Create**.
3. Configure the rule:

   | Setting | Value |
   | --- | --- |
   | Ports | `All` |
   | Source IP | `Specific IP` → `Subnet` |
   | IP address | `172.20.0.0` |
   | Subnet mask | `255.255.0.0` |
   | Action | `Allow` |

4. Select **OK**.
5. Repeat the process for every additional generated bridge subnet.

Use the actual subnet from each preset's `.env`, especially when you changed a generated default. An incorrect firewall source or mask can block internal container traffic.

## Deploy with Synology Container Manager

Plundarr is tested with Container Manager on DSM 7.4. Keep DSM and Container Manager current before deployment.

1. Generate the selected project from the cloned repository.
2. Keep `docker-compose.yml`, `.env`, and `config/` together beneath `dist/<preset>/`.
3. Open **Container Manager**, then **Project**.
4. Select **Create**.
5. Choose the generated `dist/<preset>` directory as the project path.
6. Select `docker-compose.yml` as the Compose file.
7. Review the resolved settings and deploy the project.

The [Synology Container Manager project documentation](https://kb.synology.com/en-id/DSM/help/ContainerManager/docker_project?version=7) describes the surrounding user interface.

## Configure media libraries

| Server | Host mount behavior | Libraries to add | Notes |
| --- | --- | --- | --- |
| Jellyfin with Plundarr or standalone | `JELLYFIN_DATA_PATH` mounts read/write at `/data` | `/data/movies`, `/data/tv` | Persistent `/config` and `/cache` |
| Jellyfin with Boudoirr | The Whisparr and Jellyfin data roots share `/data` | `/data/movies`, `/data/scenes` | Set both high-level paths to the same host directory |
| Plex with Plundarr | Separate read-only library mounts | Movies, television, anime | Persistent config and transcode mounts |
| Plex with Plundarr and Lidarr | Separate read-only library mounts | Movies, television, anime, music at `/music` | Lidarr writes the same host music library |
| Plex with Boudoirr | Separate read-only library mounts | Movies, scenes | Plex must be selected explicitly |
| Plex standalone | Separate read-only library mounts | Movies, television | Uses host networking |
| Calibre-Web Automated with Plundarr or standalone | `CWA_LIBRARY_PATH` mounts read/write at `/calibre-library` | Calibre library containing `metadata.db` | Config and ingest use separate mounts |

Application libraries are configured in Jellyfin, Plex, or Calibre-Web Automated after the containers start. Maraudarr prepares consistent mounts but does not create media-server library records.

## Configure Lidarr

Generate Plundarr with the music automation service:

```sh
make ship ADD_SERVICES=lidarr
```

Review these values in `dist/plundarr/.env`:

| Setting | Purpose |
| --- | --- |
| `HOST_MUSIC_PATH` | Host music library mounted read/write at `/music` in Lidarr |
| `LIDARR_WEBUI_PORT` | Host port for Lidarr; defaults to `8686` |
| `LIDARR_CONFIG_PATH` | Persistent Lidarr database and application settings |
| `HOMEPAGE_VAR_LIDARR_KEY` | Lidarr API key used by the optional Homepage widget |

Lidarr automatically adds Prowlarr and its indexing dependency. Configure `/music` as the Lidarr root folder and connect a selected downloader after launch. Plex receives the same host path read-only at `/music` whenever Plex and Lidarr are selected together. Jellyfin can expose it as `/data/music` when `JELLYFIN_DATA_PATH` points to the parent media root.

The [LinuxServer Lidarr image](https://docs.linuxserver.io/images/docker-lidarr/) supports `linux/amd64` and `linux/arm64`, not `linux/arm/v7`. The [Homepage Lidarr widget guide](https://gethomepage.dev/widgets/services/lidarr/) documents the API key and supported fields used by the generated card.

## Preview and sync Recyclarr

Generate Plundarr with Recyclarr, then set API access for the in-stack Radarr and Sonarr instances. Selecting Recyclarr adds both services and their indexing chain when the preset does not already contain them:

```sh
make ship ADD_SERVICES=recyclarr
```

| Setting | Purpose |
| --- | --- |
| `RECYCLARR_RADARR_URL` | Radarr base URL; defaults to the in-stack service |
| `RECYCLARR_RADARR_API_KEY` | Radarr API key required before synchronization |
| `RECYCLARR_SONARR_URL` | Sonarr base URL; defaults to the in-stack service |
| `RECYCLARR_SONARR_API_KEY` | Sonarr API key required before synchronization |
| `RECYCLARR_CONFIG_PATH` | Regeneration-safe Recyclarr configuration and cache directory |

Maraudarr seeds `config/recyclarr/recyclarr.yml` once. The starter syncs upstream quality-size definitions only, does not delete old custom formats, and can be extended with the templates and profiles appropriate for the library.

Preview and apply Recyclarr through separate profile-aware targets:

```sh
make recyclarr-preview PRESET=plundarr
make recyclarr-sync PRESET=plundarr
```

> [!CAUTION]
> The sync target changes the configured Radarr and Sonarr instances. Confirm the URLs, API keys, configuration, and preview output before running it. Ordinary `make up` does not start Recyclarr.

See the official [Recyclarr feature reference](https://recyclarr.dev/guide/features/) and [`sync` command reference](https://recyclarr.dev/cli/sync/) before adding custom formats, quality profiles, naming rules, or additional instances.

## Configure Calibre-Web Automated

Plundarr includes Calibre-Web Automated as a removable default. Generate it alone when the ebook library should have its own Compose project, network, and host port:

```sh
make ship PRESET=calibre-web-automated
make up PRESET=calibre-web-automated
```

Review these values in the selected preset's `.env`:

| Setting | Purpose |
| --- | --- |
| `CWA_WEBUI_PORT` | Host port for the web interface; `8213` in Plundarr and `48213` standalone |
| `CWA_CONFIG_PATH` | Persistent users, settings, logs, plugins, and application databases |
| `CWA_INGEST_PATH` | Temporary import directory whose files CWA removes after processing |
| `CWA_LIBRARY_PATH` | Calibre library containing `metadata.db` and managed ebook files |
| `CWA_NETWORK_SHARE_MODE` | Use `true` only for NFS or SMB storage; keep `false` for local Synology volumes |

> [!CAUTION]
> Keep the config, ingest, and library paths as three separate directories. Never use an active download directory as the ingest path, and never place incomplete downloads there. Back up the complete config directory and Calibre library before updating CWA or changing its storage.

The default Plundarr Homepage card uses CWA's native widget. Replace `HOMEPAGE_VAR_CWA_USER` and `HOMEPAGE_VAR_CWA_PASS` with a CWA account in the generated `.env` to enable book, author, and series counts.

CWA is excluded from unattended Watchtower updates so database migrations remain a deliberate operator action. Its published image supports `linux/amd64` and `linux/arm64`, not `linux/arm/v7`.

See the [Calibre-Web Automated project](https://github.com/crocodilestick/Calibre-Web-Automated) for application-level setup and the [Homepage Calibre-Web widget guide](https://gethomepage.dev/widgets/services/calibre-web/) for dashboard integration details.

## Configure Duplex services

Generate Duplex and review `dist/duplex/.env`:

```sh
make ship PRESET=duplex
```

| Setting | Purpose |
| --- | --- |
| `KOMETA_CONFIG_PATH` | Independent Kometa checkout containing `config.yml`, assets, and metadata |
| `KOMETA_TIMES` | Comma-separated stable-image run times in `HH:MM` format |
| `IMAGEMAID_PLEX_PATH` | Plex application data containing `Cache`, `Metadata`, and `Plug-in Support` |
| `TAUTULLI_PUID` and `TAUTULLI_PGID` | Host identity allowed to write Tautulli state |
| `TAUTULLI_WEBUI_PORT` | Tautulli host port; defaults to `8181` |
| `NOTIFIARR_WEBUI_PORT` | Notifiarr host port; defaults to `5454` |

Kometa remains an independently managed checkout mounted at `/config`; Maraudarr does not clone or replace it. ImageMaid receives its own writable configuration directory and the Plex application-data directory at `/plex`.

Start the persistent Duplex services:

```sh
make up PRESET=duplex
```

Overlay Reset stays outside normal startup behind the `tools` profile.

> [!CAUTION]
> Kometa Overlay Reset is destructive and has no undo. Confirm the Plex URL, token, and library, keep `OVERLAY_RESET_DRY_RUN=True`, and inspect the output before deliberately setting it to `False`.

Run the profile-gated tool explicitly:

```sh
make kometa-overlay-reset PRESET=duplex
```

See the [Kometa Docker guide](https://kometa.wiki/en/latest/kometa/install/docker/), [Kometa environment reference](https://kometa.wiki/en/latest/kometa/environmental/), [ImageMaid guide](https://kometa.wiki/en/latest/kometa/scripts/imagemaid/), and [Overlay Reset guide](https://kometa.wiki/en/latest/kometa/scripts/overlay-reset/) for application-level configuration.

## Configure Watchtower

Plundarr and Boudoirr include Watchtower as a removable persistent default. Duplex does not. Any compatible preset may add it explicitly, or it can run as a standalone project:

```sh
make ship PRESET=duplex ADD_SERVICES=watchtower
make ship PRESET=watchtower
make up PRESET=watchtower
```

Run one update pass against the standalone project with:

```sh
make watchtower-run-once PRESET=watchtower
```

Watchtower controls the host Docker daemon through its socket and can inspect eligible containers outside its own Compose project. Run one persistent daemon per host, stop it before a one-shot pass, and use `com.centurylinklabs.watchtower.enable=false` to exclude containers deliberately.

## Continue the voyage

- Use the [root README on GitHub](https://github.com/scottgigawatt/plundarr/blob/main/README.md) for preset selection and common commands.
- Use the [host script guide](project-guides/scripts.md) for Synology and Linux helpers.
- Use the [testing guide](project-guides/testing.md) before running credential-backed VPN or stack tests.
- Use the [support guide](SUPPORT.md) when setup does not behave as documented.

Fair winds, sensible subnets, and no surprise port collisions. 🏴‍☠️
