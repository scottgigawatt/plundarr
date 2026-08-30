# Set up Plundarr with Docker or Synology ⚓

This guide generates a Plundarr deployment, reviews the host-specific settings, and launches the resulting one-file Docker Compose project with Docker Compose or Synology Container Manager.

## Generate a deployment

Run the interactive generator from the repository:

```sh
make configure
```

For a repeatable non-interactive build, select a preset and optional services directly:

```sh
make ship
make ship PRESET=boudoirr ADD_SERVICES=jellyfin
make ship PRESET=jellyfin
make ship PRESET=plex
make ship PRESET=duplex
make ship PRESET=watchtower
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
| Plundarr | `plundarr` | `172.28.0.0/16` | Standard service ports |
| Boudoirr | `boudoirr` | `172.29.0.0/16` | Selected ports offset by `10000` |
| Jellyfin | `jellyfin` | `172.30.0.0/16` | Jellyfin `28096` |
| Plex | `plex` | `172.31.0.0/16` | Plex host networking |
| Duplex | `duplex` | `172.26.0.0/16` | Tautulli `8181`; Notifiarr `5454` |
| Watchtower | `watchtower` | `172.25.0.0/16` | No published ports |
| Custom | `custom` | `172.27.0.0/16` | Selected ports offset by `30000` |

Container names include the project, service, and image tag, such as `plundarr-bazarr-latest`. Existing values remain preserved during regeneration, so older deployments may need manual network or port changes before another preset can run beside them.

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
   | IP address | `172.28.0.0` |
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
| Plex with Boudoirr | Separate read-only library mounts | Movies, scenes | Plex must be selected explicitly |
| Plex standalone | Separate read-only library mounts | Movies, television | Uses host networking |

Application libraries are configured in Jellyfin or Plex after the containers start. Maraudarr prepares consistent mounts but does not create media-server library records.

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
