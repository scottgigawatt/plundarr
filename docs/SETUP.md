# Synology Setup ⚓

This guide deploys one generated Plundarr project with Synology Container
Manager on DSM 7.2 or later.

## Before You Start

Prepare:

- Container Manager, Git, and Make.
- A project directory such as `/volume1/docker/plundarr`.
- Host directories for downloads, media, and service configuration.
- PIA credentials when the selected preset includes Privateerr and Gluetun.

The optional
[Synology helper scripts](https://github.com/scottgigawatt/plundarr/tree/main/scripts#readme)
can prepare TUN, Docker socket, and inotify settings when your NAS needs them.

## 1. Generate the Project 🗺️

From the cloned repository, run the interactive generator:

```bash
make configure
```

Or generate a known preset directly:

```bash
make ship
make ship PRESET=boudoirr ADD_SERVICES=jellyfin
make ship PRESET=jellyfin
make ship PRESET=plex
```

Maraudarr writes `docker-compose.yml`, `.env`, `example.env`, and only the
selected service directories under `config/`.

Plundarr and Boudoirr select only qBittorrent as a downloader by default.
SABnzbd, NZBGet, and Watchtower are optional choices in `make configure`.
Equivalent repeatable commands include:

```bash
# Usenet only
make ship PRESET=boudoirr REMOVE_SERVICES=qbittorrent,cleanuparr ADD_SERVICES=sabnzbd

# Torrents and Usenet, with optional update checks
make ship PRESET=boudoirr ADD_SERVICES=sabnzbd,watchtower
```

## 2. Review `.env` 🔐

Check these values before launch:

| Setting                              | What to Confirm                                 |
| ------------------------------------ | ----------------------------------------------- |
| `PIA_USER`, `PIA_PASS`               | Real PIA credentials when VPN services are used |
| `DEFAULT_PUID`, `DEFAULT_PGID`       | IDs that can access every mounted host path     |
| `HOST_*_PATH`                        | Download and automation or Plex library paths   |
| `WHISPARR_DATA_PATH`                 | High-level Boudoirr media directory             |
| `JELLYFIN_DATA_PATH`                 | High-level Jellyfin media directory             |
| `TZ`, `*_WEBUI_PORT`                 | Timezone and available host ports               |
| `COMPOSE_NETWORK_*`                  | A private subnet that does not overlap your LAN |

Keep `.env` beside `docker-compose.yml` and never commit it. Maraudarr creates
supported first-run secrets automatically and preserves existing values when
the project is regenerated.

## 3. Create the Container Manager Project 📦

1. Open **Container Manager** → **Project** → **Create**.
2. Use the generated `COMPOSE_PROJECT_NAME` as the project name.
3. Select the cloned repository as the project path.
4. Select `docker-compose.yml` as the Compose file.
5. Review the chart and start the project.

Container Manager reads `.env` from the same directory automatically.

## Jellyfin Libraries 🪼

Jellyfin always receives `JELLYFIN_DATA_PATH` as writable `/data`:

- Standalone Jellyfin or Plundarr: add `/data/movies` and `/data/tv`.
- Boudoirr: add `/data/movies` and `/data/scenes`.

For Boudoirr with Jellyfin, set `WHISPARR_DATA_PATH` and
`JELLYFIN_DATA_PATH` to the same high-level host directory. Add `/data/scenes`
as Whisparr's root folder.

Configuration, cache, and logs remain under `config/jellyfin/`; logs are
already persisted through `/config/log` and need no separate mount.

## Network and Firewall 🌍

Fresh presets use separate `/16` networks:

| Preset   | Default Subnet  |
| -------- | --------------- |
| Plundarr | `172.28.0.0/16` |
| Boudoirr | `172.29.0.0/16` |
| Jellyfin | `172.30.0.0/16` |
| Plex     | `172.31.0.0/16` |

Change the generated `COMPOSE_NETWORK_*` values if a subnet overlaps another
Docker network, VPN, or LAN route.

If the DSM firewall blocks container traffic, add an **Allow** rule for the
selected subnet under **Control Panel** → **Security** → **Firewall**. A `/16`
network uses subnet mask `255.255.0.0`.

See Synology's official
[Container Manager project documentation](https://kb.synology.com/en-id/DSM/help/ContainerManager/docker_project?version=7)
for DSM interface details.
