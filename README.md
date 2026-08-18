<!-- markdownlint-disable-next-line MD033 MD041 -->
<hr />

<!-- markdownlint-disable MD033 -->
<p align="center">
  <em>🏴‍☠️ Enjoyin' the spoils? Drop us a ⭐️ an' let the whole crew know about this fine treasure!</em>
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/scottgigawatt/plundarr?style=social&label=Treasure%20Hunters" alt="Treasure Hunters" />
  <img src="https://img.shields.io/github/forks/scottgigawatt/plundarr?style=social&label=Mutinous%20Forks" alt="Mutinous Forks" />
  <img src="https://img.shields.io/github/watchers/scottgigawatt/plundarr?style=social&label=Crow%27s%20Nest%20Lookouts" alt="Crow's Nest Lookouts" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Containers-Ahoy%21-blue?logo=docker" alt="Containers Ahoy" />
  <img src="https://img.shields.io/badge/Cloaked-by%20PIA%20%26%20WireGuard-green?logo=protonvpn" alt="Cloaked" />
  <img src="https://img.shields.io/github/license/scottgigawatt/plundarr?label=Legal%20Scroll&color=blue" alt="Legal Scroll" />
  <img src="https://img.shields.io/github/last-commit/scottgigawatt/plundarr?label=Last%20Plunder&logo=git" alt="Last Plunder" />
  <img src="https://img.shields.io/badge/Sea--Tested-Synology%20%7C%20macOS-blue" alt="Sea-Tested" />
  <img src="https://img.shields.io/badge/Rum%20Supply-Full-orange" alt="Rum Supply" />
</p>

<p align="center">
  <a href="https://github.com/scottgigawatt/plundarr/actions/workflows/build-and-push.yml"><img src="https://github.com/scottgigawatt/plundarr/actions/workflows/build-and-push.yml/badge.svg" alt="Maraudarr Build" /></a>
  <img src="https://img.shields.io/badge/Fleet-amd64%20%7C%20arm64%20%7C%20arm%2Fv7-blue?logo=docker" alt="Multi-Architecture Fleet" />
  <img src="https://img.shields.io/badge/Bilge%20Check-Trivy-1904DA?logo=aqua" alt="Scanned with Trivy" />
</p>

<p align="center">─── ⛧ ───</p>

<p align="center">
    <em>☠️ Questions or cursed code? Cross the Styx — <strong>Enter 🔥HADES🔥</strong>.</em>
</p>

<p align="center">
  <a href="https://discord.gg/BpEGzWwGYf">
    <img src="https://img.shields.io/discord/1403601106315116626?label=%F0%9F%94%A5HADES%F0%9F%94%A5&logo=discord&logoColor=white&color=5865F2" alt="🔥HADES🔥 Discord" />
  </a>
</p>

<!-- markdownlint-enable MD033 -->
<!-- markdownlint-disable-next-line MD033 -->
<hr />

# Plundarr 🏴‍☠️

Plundarr turns a preset and a few choices into one complete, commented Docker
Compose stack. It is designed for Docker Compose and Synology Container
Manager: one `docker-compose.yml`, one `.env`, and one `config/` directory.

**Maraudarr** is the short-lived generator. **Plundarr** is the stack it writes.

## Quick Start ⚓️

Install Docker, Docker Compose, Git, and Make, then run:

```bash
git clone https://github.com/scottgigawatt/plundarr.git
cd plundarr
make configure
```

Choose a preset and any extra services. Maraudarr shows the final service list
before writing:

```text
docker-compose.yml
example.env
.env
config/
```

> [!IMPORTANT]
> Open `.env` before launch. Check user IDs, storage paths, timezone, and any
> credentials required by the services you selected. Never commit `.env`.

Start the generated stack:

```bash
make up
```

> [!TIP]
> Want the default Plundarr stack without prompts? Run `make ship` instead.

## Choose a Preset 🧭

| Preset        | Best For                                             |
| ------------- | ---------------------------------------------------- |
| `plundarr`    | Movies and TV automation with qBittorrent            |
| `boudoirr`    | Whisparr automation with qBittorrent                 |
| `jellyfin`    | Standalone Jellyfin with movies and TV               |
| `plex`        | Standalone Plex with movies and TV                   |
| `custom`      | Starting empty and selecting every service yourself  |

Use `ADD_SERVICES` and `REMOVE_SERVICES` for a repeatable, non-interactive
build:

```bash
make ship PRESET=jellyfin
make ship PRESET=boudoirr ADD_SERVICES=jellyfin
make ship PRESET=boudoirr ADD_SERVICES=plex
make ship REMOVE_SERVICES=qbittorrent,cleanuparr ADD_SERVICES=sabnzbd
make ship PRESET=boudoirr ADD_SERVICES=sabnzbd,watchtower
```

Run `make presets` or `make services` to see every available choice. Preset
core services cannot be removed; Maraudarr explains any required dependencies
it adds automatically.

## Choose Downloaders and Updates 📥

Plundarr and Boudoirr start with qBittorrent as their only downloader. SABnzbd,
NZBGet, and Watchtower are optional and remain unchecked in `make configure`.

- **Usenet only:** uncheck qBittorrent and Cleanuparr, then select SABnzbd or
  NZBGet.
- **Torrents and Usenet:** keep qBittorrent checked and select a Usenet client.
- **Automatic update checks:** select Watchtower only when you want it.

For non-interactive generation, use the same `ADD_SERVICES` and
`REMOVE_SERVICES` options shown above. Replace `sabnzbd` with `nzbget` when that
is your preferred Usenet client.

## Storage Without Surprises 📦

The generated `.env` is the only settings file most users need to edit.

| Setting Group                        | Check Before Launch                               |
| ------------------------------------ | ------------------------------------------------- |
| `PIA_USER`, `PIA_PASS`               | Required when Privateerr and Gluetun are selected |
| `DEFAULT_PUID`, `DEFAULT_PGID`       | Must be allowed to access the mounted host paths  |
| `HOST_*_PATH`                        | Downloads and Plex or automation libraries        |
| `WHISPARR_DATA_PATH`                 | High-level Boudoirr media directory               |
| `JELLYFIN_DATA_PATH`                 | High-level Jellyfin media directory               |
| `TZ`, `*_WEBUI_PORT`                 | Timezone and any host-port conflicts              |

Jellyfin always receives three writable mounts: `/config`, `/cache`, and one
media root at `/data`. Use `/data/movies` and `/data/tv` normally, or
`/data/movies` and `/data/scenes` with Boudoirr. Jellyfin logs are already
persisted under `/config/log`.

For Boudoirr with Jellyfin, point `WHISPARR_DATA_PATH` and
`JELLYFIN_DATA_PATH` at the same high-level directory. Use `/data/scenes` as
Whisparr's root folder and as the scenes library in Jellyfin.

Plex keeps separate read-only library mounts. Plundarr uses movies, TV, and
anime; Boudoirr uses movies and scenes; standalone Plex uses movies and TV.

Regeneration preserves existing `.env` values and application state. Only
`make clean-config` intentionally removes the generated config directory.

## Everyday Commands 🧰

| Command                 | Purpose                                      |
| ----------------------- | -------------------------------------------- |
| `make configure`        | Choose a preset and services interactively   |
| `make ship`             | Generate the default stack without prompts   |
| `make up` / `make down` | Start or stop the generated stack            |
| `make config`           | Validate and print the final Compose model   |
| `make backup-config`    | Archive the service configuration directory  |
| `make help`             | List every available command                 |

Using Synology? Follow the short [Container Manager setup guide](docs/SETUP.md)
and review the optional [Synology helper scripts](scripts/README.md).

## What Can Sail? 🗺️

- **VPN and downloads:** Privateerr, Gluetun, qBittorrent, SABnzbd, and NZBGet.
- **Automation:** Prowlarr, Radarr, Sonarr, Sonarr Anime, Bazarr, Seerr, and
  Whisparr.
- **Media servers:** Jellyfin and Plex, independently or together.
- **Utilities:** Cleanuparr, Speedtest Tracker, Apprise, Duplicati, Homepage,
  FlareSolverr, and Watchtower.

Run `make services` for descriptions and upstream links.

## Maraudarr in Motion 🎬

<!-- markdownlint-disable MD033 -->
<p align="center">
  <img src="./docs/assets/maraudarr-demo.gif" width="800" alt="Maraudarr generates and starts a Plundarr Docker Compose stack" />
</p>
<!-- markdownlint-enable MD033 -->

The recording uses inert VPN stand-ins. A real VPN-enabled stack needs valid
PIA credentials in `.env`.

## Testing and Help 🔎

For generator changes, run `make test-maraudarr`. Runtime VPN checks can launch
real containers and use real PIA credentials; read the [testing guide](test/README.md)
before running `make test-vpn`, `make test-e2e`, or `make test-stack`.

| Guide                                                                | Use It For                                 |
| -------------------------------------------------------------------- | ------------------------------------------ |
| [Synology setup](docs/SETUP.md)                                      | Container Manager and network setup        |
| [Maraudarr internals](docker/README.md)                              | Generator image and maintenance            |
| [Developer documentation](https://scottgigawatt.github.io/plundarr/) | Architecture and Python reference          |
| [Contributing](docs/CONTRIBUTING.md)                                 | Code style and pull requests               |
| [Security](docs/SECURITY.md)                                         | Private vulnerability reporting            |

## Ship's Log 🏝️

Plundarr has sailed on Synology DSM and macOS, but the generated Compose chart
ought to run in any harbor with a compatible Docker Engine. The Maraudarr
image publishes for `linux/amd64`, `linux/arm64`, and `linux/arm/v7`; individual
third-party service images may support fewer architectures.

## Articles of Agreement ⚖️

This project be licensed under the [Apache License 2.0](LICENSE).

Privateerr uses the unmodified upstream
[PIA manual-connections](https://github.com/pia-foss/manual-connections)
scripts under their upstream MIT license. Plundarr consumes the published
Privateerr image and does not vendor those scripts.

---

```text
               |    |    |
              )_)  )_)  )_)
             )___))___))___)\
            )____)____)_____)\\
         _____|____|____|____\\\__
  ~~ ~~  \_______________________/  ~~ ~~
  ~  ~   ~~~ ~~~~~ ~~~~~ ~~~ ~~~   ~  ~~
      ~   ~   ~  ~~~  ~~~~ ~  ~~   ~ ~

       🏴‍☠️  The Plunderer's Docker Fleet ☠️⚓️
       "Code ho! Containers below deck!"
```

<!-- markdownlint-disable-next-line MD036 -->
_Fair winds, clean logs, and may yer containers never mutiny. 🏴‍☠️_
