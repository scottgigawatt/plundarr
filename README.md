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

Ahoy, mateys! Plundarr charts a complete Docker Compose media fleet from the
services ye actually want, then packs the whole voyage into one commented
`docker-compose.yml` and one matching `.env` file. Docker Compose and Synology
Container Manager both get one final chart, while routine configuration stays
where it belongs: in `.env`. ⚓️

## Captain's Log 📜

**Maraudarr** be the shipwright of this operation. It is a short-lived,
published Docker image that chooses a ready-made voyage or loads the hold
service by service. Maraudarr keeps the handwritten comments, resolves required
shipmates, writes Plundarr into the repository root, and asks Docker Compose to
inspect the riggin' before anything leaves port.

## Maraudarr in Motion 🎬

Watch Maraudarr chart a Plundarr voyage, load Jellyfin aboard, generate the
complete configuration, and raise the Compose fleet:

<!-- markdownlint-disable MD033 -->
<p align="center">
  <img src="./docs/assets/maraudarr-demo.gif" width="800" alt="Maraudarr generates and starts a Plundarr Docker Compose stack" />
</p>
<!-- markdownlint-enable MD033 -->

The animation follows the real `make configure`, `make up`, and `make ps`
workflow. Curious captains can inspect or replay the
[recording source](./docs/demo/record-maraudarr-demo.sh).

> [!NOTE]
> The disposable recording uses inert VPN bootstrap stand-ins, so it needs no
> PIA credentials and opens no tunnel. A normal `make up` launches Privateerr
> and Gluetun from the generated chart.

## Treasure Map 🗺️

| Shipmate          | What It Be                                             | Yo Ho Ho and More Info                                               |
| ----------------- | ------------------------------------------------------ | -------------------------------------------------------------------- |
| Privateerr        | 🏴‍☠️ Creates PIA WireGuard config and port metadata.     | [More info](https://github.com/scottgigawatt/privateerr)             |
| Gluetun           | 🌊 Runs the VPN tunnel and PIA port forwarding.        | [More info](https://github.com/qdm12/gluetun)                        |
| FlareSolverr      | 🔥 Helps Prowlarr through supported anti-bot storms.   | [More info](https://github.com/FlareSolverr/FlareSolverr)            |
| Prowlarr          | 🐾 Manages indexers for the automation fleet.          | [More info](https://github.com/Prowlarr/Prowlarr)                    |
| qBittorrent       | 🌊 Downloads torrents through Gluetun.                 | [More info](https://github.com/qbittorrent/qBittorrent)              |
| SABnzbd           | 📰 Downloads Usenet cargo through Gluetun.             | [More info](https://sabnzbd.org)                                     |
| NZBGet            | ⚡ Runs a lean Usenet downloader through Gluetun.           | [More info](https://nzbget.com)                                      |
| Radarr            | 🎥 Finds, tracks, and organizes movies.                | [More info](https://github.com/Radarr/Radarr)                        |
| Sonarr            | 📺 Finds, tracks, and organizes TV shows.              | [More info](https://github.com/Sonarr/Sonarr)                        |
| Sonarr Anime      | 🍜 Runs a second Sonarr for anime TV cargo.            | [More info](https://github.com/Sonarr/Sonarr)                        |
| Whisparr          | 🔞 Manages an adult media library.                     | [More info](https://github.com/Whisparr/Whisparr)                    |
| Bazarr            | 🦜 Fetches subtitles for movies and TV shows.          | [More info](https://github.com/morpheus65535/bazarr)                 |
| Seerr             | ⚓️ Handles media requests for yer crew.                | [More info](https://github.com/seerr-team/seerr)                     |
| Plex              | 🎬 Streams selected libraries with Plex Media Server.  | [More info](https://www.plex.tv/media-server-downloads/)             |
| Jellyfin          | 🎞️ Streams movies, television, and anime.              | [More info](https://jellyfin.org)                                    |
| Cleanuparr        | 🧹 Removes blocked or unwanted downloads.              | [More info](https://github.com/Cleanuparr/Cleanuparr)                |
| Speedtest Tracker | ⚡️ Tracks internet speed over time.                    | [More info](https://docs.speedtest-tracker.dev/)                     |
| Apprise           | 📯 Delivers notifications without another public UI.   | [More info](https://github.com/caronc/apprise-api)                   |
| Duplicati         | 💣 Backs up yer precious booty.                        | [More info](https://www.duplicati.com)                               |
| Homepage          | 🏠 Provides a dashboard for the whole fleet.           | [More info](https://gethomepage.dev)                                 |
| Watchtower        | 🔭 Checks selected containers for image updates.       | [More info](https://github.com/containrrr/watchtower)                |
| **~~Readarr~~**   | ❌ Scuttled; use Calibre Web Automated instead.        | [Set Sail ⚓](https://github.com/scottgigawatt/calibre-web-automated) |

## Hoist the Sails ⚓️

The default Plundarr voyage uses qBittorrent and needs no setup questions.
`make ship` uses Maraudarr locally when available, pulls it when missing, and
builds it from this checkout when no published image is available. It then
generates the complete Plundarr stack in this repository:

```bash
# Hoist the Jolly Roger, clone the repo, and chart the default stack
❯ git clone https://github.com/scottgigawatt/plundarr.git
❯ cd plundarr
❯ make ship
```

Maraudarr writes the complete Plundarr project where ye already expect it:

```text
docker-compose.yml
example.env
.env
config/
```

> [!IMPORTANT]
> 🔐 Open `.env` before launch. Most defaults can stay aboard, but real PIA
> credentials and host storage paths must match yer own harbor.

### Focus on These Settings ⚙️

| Setting                              | Why Ye Care                                                   |
| ------------------------------------ | ------------------------------------------------------------- |
| 🔐 `PIA_USER` / `PIA_PASS`           | Required for PIA WireGuard and port forwarding                |
| 👤 `DEFAULT_PUID` / `DEFAULT_PGID`   | Must be able to read and write the mounted files              |
| 📦 `HOST_DOWNLOADS_PATH`             | Shared download root for the automation fleet                 |
| 🎥 `HOST_MOVIES_PATH`                | Final movie library                                           |
| 📺 `HOST_TV_PATH`                    | Final television library                                      |
| 🍜 `HOST_ANIME_TV_PATH`              | Anime library when Sonarr Anime or Jellyfin needs it          |
| 🕰️ `TZ`                              | Timezone used by the containers                               |
| 🚪 `*_WEBUI_PORT`                    | Change only when a host port already be occupied              |

> [!TIP]
> 🗺️ The defaults expect downloads under `/volume1/downloads`, movies under
> `/volume1/plex/movies`, television under `/volume1/plex/tv`, and service
> configuration under this repository's `config/` directory.

When the chart looks shipshape, launch the complete fleet in one shot:

```bash
make up
```

## Chart Yer Own Voyage 🧭

Open Maraudarr's full interactive voyage through Make:

```bash
make configure
```

Choose a preset, inspect its cargo, add or remove services, and approve the
final manifest. The prompts stay friendly, lightly pirate, and very clear about
what will be written.

| Voyage           | Default Cargo                                                                                                                                   |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| 🏴‍☠️ `plundarr`    | Privateerr, Gluetun, FlareSolverr, Prowlarr, qBittorrent, Radarr, Sonarr, Bazarr, Seerr, Cleanuparr, Speedtest Tracker, Duplicati, and Homepage |
| 🔞 `boudoirr`    | Privateerr, Gluetun, FlareSolverr, Prowlarr, qBittorrent, SABnzbd, Whisparr, Cleanuparr, and Watchtower                                         |
| 🧩 `custom`      | An empty hold; choose every service yerself                                                                                                     |

Useful commands for captains who already know the route:

| Command                                                                                    | What It Does                            |
| ------------------------------------------------------------------------------------------ | --------------------------------------- |
| 🗺️ `make presets`                                                                          | Shows each preset and its default cargo |
| 📦 `make services`                                                                         | Lists every service Maraudarr can add   |
| ⚓ `make ship OPTIONAL_SERVICES=qbittorrent,cleanuparr,apprise,jellyfin`                   | Adds Apprise and Jellyfin               |
| 🎬 `make ship OPTIONAL_SERVICES=qbittorrent,cleanuparr,plex`                               | Adds containerized Plex                 |
| 📰 `make ship OPTIONAL_SERVICES=nzbget`                                                    | Charts an NZBGet Usenet voyage          |
| 🔞 `make ship PRESET=boudoirr OPTIONAL_SERVICES=qbittorrent,sabnzbd,cleanuparr,watchtower` | Charts the Boudoirr voyage              |

Switch the default Plundarr voyage from torrents to Usenet:

```bash
make ship PRESET=plundarr OPTIONAL_SERVICES=sabnzbd
```

Or choose NZBGet as the Usenet runner:

```bash
make ship PRESET=plundarr OPTIONAL_SERVICES=nzbget
```

Both Usenet clients can sail together when ye want separate queues:

```bash
make ship PRESET=plundarr OPTIONAL_SERVICES=sabnzbd,nzbget
```

> [!NOTE]
> 🧰 Rebuilds preserve existing values by variable name. Fresh voyages receive
> strong Speedtest Tracker, Duplicati, and NZBGet secrets, while values for
> temporarily unselected services wait safely in a marked footer until that
> cargo returns.

> [!NOTE]
> 🌊 Only selected download clients share Gluetun's network namespace. Prowlarr,
> Radarr, Sonarr, Bazarr, and the rest of the automation fleet use the normal
> project network.

### Synology Notes 📦

Synology Container Manager gets the same one-file deployment chart:

1. Keep `.env` beside `docker-compose.yml`.
2. Create a Container Manager project from `docker-compose.yml`.
3. Review the generated chart, then launch the project.

Read the Synology setup scroll before the first voyage:

- 🖥️ [Docker Project Setup](./docs/SETUP.md)
- 🦜 [Synology Helper Scripts](scripts/README.md)

## Spyglass Check 🔎

Useful test voyages:

```bash
make test-maraudarr
make test-vpn
make test-e2e
make test-stack
```

> [!WARNING]
> ⚠️☠️ VPN tests use real PIA credentials from `.env` and may launch real
> containers. Read the [full testing chart](./test/README.md) before firing
> those cannons.

## Navigatin' Troubled Waters ☠️🌊

> [!TIP]
> 🧭 Prefer a trusty first mate? The `Makefile` wraps the common Maraudarr and
> Docker Compose commands while still printin' the complete command it runs.

| Command                         | What It Does                                             |
| ------------------------------- | -------------------------------------------------------- |
| 🗺️ `make ship`                  | Prepares Maraudarr and generates the Plundarr stack      |
| 🧭 `make configure`             | Opens Maraudarr's interactive configurator               |
| 📜 `make presets`               | Lists presets and their exact default services           |
| 📦 `make services`              | Lists every service Maraudarr can select                 |
| 🌊 `make update-maraudarr`      | Refreshes the published Maraudarr image                  |
| 🧾 `make compose-services`      | Lists services in the generated Plundarr chart           |
| 🔎 `make config`                | Prints Docker Compose's validated model                  |
| 🚀 `make up`                    | Starts the complete generated stack                      |
| ⚓ `make down`                  | Stops and removes the generated stack                    |
| 💾 `make backup-config`         | Archives `config/` with a collision-safe timestamp       |
| ☠️ `make clean-config`          | Deletes the complete generated config directory          |
| 🐍 `make test-maraudarr-unit`   | Runs Maraudarr's Python unit tests                        |
| 🧪 `make test-maraudarr`        | Tests presets and generated Compose combinations         |
| ⚒️ `make build-maraudarr`       | Builds the Maraudarr image locally from this repository  |

Need the whole command chart? Run `make help`.

## More Treasure Maps 🗺️

| Scroll                                              | When Ye Need It                                  |
| --------------------------------------------------- | ------------------------------------------------ |
| ⚒️ [Inside Maraudarr](docker/README.md)             | Image commands, security, tags, and architecture |
| 🖥️ [Synology Setup](docs/SETUP.md)                  | Container Manager and host-path preparation      |
| 🧪 [Testing Hold](test/README.md)                   | VPN, end-to-end, and stack validation            |
| 🛠️ [Contributin' Code Booty](docs/CONTRIBUTING.md)  | Repository standards and pull requests           |
| 🤝 [The Pirate Code](docs/CODE_OF_CONDUCT.md)       | Expectations for every member of the crew        |
| 🛡️ [Security Parley](docs/SECURITY.md)              | Private vulnerability reporting                  |

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

### 🧭 Crew Charts & Codes

| 📜 Shipboard Scroll                                  | ⚓ What It Helps Ye Do                                                     |
| ---------------------------------------------------- | -------------------------------------------------------------------------- |
| 🛠️ [Patch the Hull](docs/CONTRIBUTING.md)            | Bring fixes and bright ideas aboard without springing leaks below deck.    |
| 🤝 [The Crewmate Compact](docs/CODE_OF_CONDUCT.md)   | Keep the deck welcoming, useful, and free of plank-walking nonsense.       |
| 🔐 [Whisper to the Quartermaster](docs/SECURITY.md)  | Report dangerous leaks privately before the sharks catch their scent.      |

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
