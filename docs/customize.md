# Customize your Plundarr stack

Start with the [default setup](setup.md), then choose services and integrations for your library. Run generation commands from the directory mounted at `/output`; run application commands from the generated `dist/<preset>/` directory.

## Select services and presets

Maraudarr's interactive picker offers presets and optional services. Required services are added automatically. For Make shortcuts, install Git and Make, clone the repository, and run from its root:

```sh
git clone https://github.com/scottgigawatt/plundarr.git
cd plundarr
make configure
```

Make uses the published generator. For non-interactive generation, `PRESET` chooses the starting point; `ADD_SERVICES` and `REMOVE_SERVICES` accept comma-separated IDs:

```sh
make generate ADD_SERVICES=lidarr,recyclarr
make generate REMOVE_SERVICES=qbittorrent,cleanuparr ADD_SERVICES=nzbget
make generate PRESET=boudoirr ADD_SERVICES=whisparr-alt
```

Use `make presets` and `make services` to inspect the catalog, or browse [preset examples](https://github.com/scottgigawatt/plundarr/blob/main/examples/presets/README.md). To use Docker directly, replace `configure` in the [generator command](https://scottgigawatt.github.io/plundarr/setup/#generate-a-deployment) with `build --preset boudoirr --add whisparr-alt`, for example.

Repeat your full intended selection on regeneration. Maraudarr preserves environment values and application state, but those values do not remember service choices. Generation does not stop omitted running services. Review removals before recreating the project; see [maintenance](maintain.md#regenerate-a-deployment).

## Plan project networks

Each preset has its own project name, bridge subnet, and host ports:

| Preset | Subnet | Default host ports |
| --- | --- | --- |
| Plundarr | `172.20.0.0/16` | Standard application ports; CWA `8213` |
| Boudoirr | `172.21.0.0/16` | Selected ports offset by `10000` |
| Jellyfin | `172.22.0.0/16` | Jellyfin `28096` |
| Plex | `172.23.0.0/16` | Plex host networking |
| Calibre-Web Automated | `172.24.0.0/16` | CWA `48213` |
| Duplex | `172.25.0.0/16` | Themerr HTTPS `9494`, connector `9495`; Notifiarr `5454` |
| Watchtower | `172.26.0.0/16` | None |
| Portainer | `172.27.0.0/16` | HTTPS `9443`, Edge `8888` |
| Custom | `172.28.0.0/16` | Selected ports offset by `30000` |

The container address pool is `.5.0/24` and gateway `.5.254` within each `/16`. If a subnet overlaps a Docker network, VPN, or LAN route, change `COMPOSE_NETWORK_SUBNET`, `COMPOSE_NETWORK_IP_RANGE`, and `COMPOSE_NETWORK_GATEWAY` together. Check existing deployments for port conflicts too. Plex's host networking permits only one server on its standard ports unless Plex itself is configured differently.

## Configure media libraries

Maraudarr prepares mounts; configure library records inside each application after startup.

- **Jellyfin:** `JELLYFIN_DATA_PATH` mounts read/write at `/data`. Use `/data/movies` and `/data/tv` for the usual libraries.
- **Plex:** Media is read-only. Plundarr exposes movies, television, and anime; Boudoirr exposes movies and scenes; standalone Plex exposes movies and television. Config and transcode paths persist separately.
- **Lidarr:** Set `HOST_MUSIC_PATH` and select `/music` as its root. Selected Plex receives it read-only. Jellyfin can see that music only when the host directory is beneath `JELLYFIN_DATA_PATH`.
- **Calibre-Web Automated:** `CWA_LIBRARY_PATH` mounts at `/calibre-library`. Keep its config, destructive ingest directory, and library separate; follow [storage preparation](setup.md#review-the-settings).

## Choose Boudoirr companions

Boudoirr includes removable Cruisarr, Jellyfin, and Stash companions. Use `REMOVE_SERVICES=cruisarr,jellyfin,stash` to omit them, or remove individual IDs. Cruisarr uses Jellyfin for login; follow [Cruisarr setup](project-guides/cruisarr.md) for its private image access and owner setup.

The [Stash guide](project-guides/stash.md) covers shared read-only libraries, its writable creators directory, recycling, first scan, and backups. Main Whisparr's `/data/movies` and `/data/scenes` match Jellyfin's `/data/movies/main` and `/data/scenes/main`; Alt uses the corresponding `/alt` directories. Keep recycle and import folders out of media-library scans.

For a second Whisparr instance, read the [Whisparr Alt chart](https://github.com/scottgigawatt/plundarr/blob/main/docker/services/whisparr-alt/README.md). Keep its database, host libraries, API key, and download categories separate. Select metadata providers inside Whisparr.

## Preview and sync Recyclarr

Select `recyclarr`, then set `RECYCLARR_RADARR_API_KEY` and `RECYCLARR_SONARR_API_KEY`. Confirm their configured URLs point to the intended applications. The seeded `config/recyclarr/recyclarr.yml` syncs upstream quality-size definitions, preserves custom formats, and remains yours to edit.

From the repository root, preview first:

```sh
make recyclarr-preview PRESET=plundarr
```

> [!CAUTION]
> Synchronization changes the configured Radarr and Sonarr instances. Back up those applications and review URLs, keys, configuration, and preview output before applying changes.

Apply the reviewed configuration deliberately:

```sh
make recyclarr-sync PRESET=plundarr
```

Recyclarr is excluded from ordinary startup. See its [configuration notes](https://github.com/scottgigawatt/plundarr/blob/main/docker/services/recyclarr/config/README.md) for templates and profile choices.

## Configure Duplex services

Generate `duplex` and review `dist/duplex/.env`. Prepare the external Kometa checkout selected by `KOMETA_CONFIG_PATH`; Maraudarr leaves that state under your control. Kometa and PATTRMM Neo share its private runtime YAML. Neo must finish generating collections before Kometa reads them. The [Kometa chart](https://github.com/scottgigawatt/plundarr/blob/main/docker/services/kometa/README.md), [PATTRMM chart](https://github.com/scottgigawatt/plundarr/blob/main/docker/services/pattrmm/README.md), and [companion configuration](https://github.com/scottgigawatt/kometa-config) cover those settings.

Point `IMAGEMAID_PLEX_PATH` at Plex application data containing `Cache`, `Metadata`, and `Plug-in Support`; begin in report mode. Follow [Themerr setup](project-guides/themerr.md) for its separate encryption key, permissions, administrator login, and connectors. Keep the encryption key with backups.

Overlay Reset is selected with `ADD_SERVICES=overlay-reset`. Its `tools` profile excludes it from normal startup.

> [!CAUTION]
> Overlay Reset is destructive and has no undo. Back up posters, confirm the Plex URL, token, and library, keep `OVERLAY_RESET_DRY_RUN=True`, and inspect output before deliberately setting it to `False`.

Run it explicitly from the repository root:

```sh
make kometa-overlay-reset PRESET=duplex
```

## Find other integrations

Use the [service guides](project-guides/index.md) for Jellyfin Web/Vue, monitoring, Portainer, VPN settings, and theme songs. Each selected service's generated config directory contains its local first-run notes. Homepage widget credentials can be added after application setup; its generated notes explain browser links and internal API addresses.
