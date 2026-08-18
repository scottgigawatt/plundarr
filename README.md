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

Plundarr has two clearly separate parts:

<!-- markdownlint-disable MD060 -->
| Component | What It Does | Where It Lives |
| --------- | ------------ | -------------- |
| **Maraudarr** | Short-lived generator that chooses services, resolves dependencies, validates the result, and exits | Published as [`ghcr.io/scottgigawatt/maraudarr`](https://github.com/scottgigawatt/plundarr/pkgs/container/maraudarr) and [`scottgigawatt/maraudarr`](https://hub.docker.com/r/scottgigawatt/maraudarr) |
| **Plundarr** | The generated media stack that stays on yer host and runs the selected services | `docker-compose.yml`, `.env`, and `config/` in this repository |
<!-- markdownlint-enable MD060 -->

`make ship` and `make configure` run the published Maraudarr image when it is
available, or build it from this checkout as a fallback. Maraudarr keeps the
handwritten Compose comments, preserves existing settings and application
state, and asks Docker Compose to inspect the riggin' before anything leaves
port. It does not remain running with the generated fleet.

## Maraudarr in Motion 🎬

Watch Maraudarr chart the default Plundarr voyage, generate one complete
configuration, and raise the Compose fleet:

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

Choose a preset in `make configure`, or pass it to `make ship`. These are the
exact services included before ye add or remove anything:

<!-- markdownlint-disable MD060 -->
| Preset | Best For | Included Out of the Box |
| ------ | -------- | ----------------------- |
| 🏴‍☠️ `plundarr` | Movies and TV automation | [Privateerr](https://github.com/scottgigawatt/privateerr), [Gluetun](https://github.com/qdm12/gluetun), [FlareSolverr](https://github.com/FlareSolverr/FlareSolverr), [Prowlarr](https://github.com/Prowlarr/Prowlarr), [qBittorrent](https://github.com/qbittorrent/qBittorrent), [Radarr](https://github.com/Radarr/Radarr), [Sonarr](https://github.com/Sonarr/Sonarr), [Bazarr](https://github.com/morpheus65535/bazarr), [Seerr](https://github.com/seerr-team/seerr), [Cleanuparr](https://github.com/Cleanuparr/Cleanuparr), [Speedtest Tracker](https://docs.speedtest-tracker.dev/), [Duplicati](https://www.duplicati.com), and [Homepage](https://gethomepage.dev/latest/) |
| 🔞 `boudoirr` | Whisparr automation | [Privateerr](https://github.com/scottgigawatt/privateerr), [Gluetun](https://github.com/qdm12/gluetun), [FlareSolverr](https://github.com/FlareSolverr/FlareSolverr), [Prowlarr](https://github.com/Prowlarr/Prowlarr), [qBittorrent](https://github.com/qbittorrent/qBittorrent), [Whisparr](https://github.com/Whisparr/Whisparr), and [Cleanuparr](https://github.com/Cleanuparr/Cleanuparr) |
| 🎞️ `jellyfin` | Standalone movies and TV playback | [Jellyfin](https://jellyfin.org/docs/) |
| 🎬 `plex` | Standalone movies and TV playback | [Plex Media Server](https://support.plex.tv/articles/categories/plex-media-server/) |
| 🧩 `custom` | A stack assembled service by service | Nothing; every service is selected explicitly |
<!-- markdownlint-enable MD060 -->

Plundarr and Boudoirr use qBittorrent as their only default downloader. On
those presets, SABnzbd, NZBGet, Jellyfin, Plex, and Watchtower are never
silently added.

### Cargo Ye Can Add 🧩

Every catalog service can be added to a compatible preset. Maraudarr adds any
required foundation services and shows the resolved fleet before writing it.

<!-- markdownlint-disable MD060 -->
| Cargo Hold | Selectable Services |
| ---------- | ------------------- |
| VPN foundation | [Privateerr](https://github.com/scottgigawatt/privateerr) and [Gluetun](https://github.com/qdm12/gluetun) |
| Download clients | [qBittorrent](https://github.com/qbittorrent/qBittorrent), [SABnzbd](https://sabnzbd.org/wiki/), and [NZBGet](https://nzbget.com/documentation/) |
| Automation | [FlareSolverr](https://github.com/FlareSolverr/FlareSolverr), [Prowlarr](https://wiki.servarr.com/prowlarr), [Radarr](https://wiki.servarr.com/radarr), [Sonarr](https://wiki.servarr.com/sonarr), [Sonarr Anime](https://wiki.servarr.com/sonarr), [Whisparr](https://wiki.servarr.com/whisparr), [Bazarr](https://wiki.bazarr.media/), and [Seerr](https://docs.seerr.dev/) |
| Media servers | [Jellyfin](https://jellyfin.org/docs/) and [Plex Media Server](https://support.plex.tv/articles/categories/plex-media-server/) |
| Operations | [Cleanuparr](https://cleanuparr.github.io/Cleanuparr/), [Speedtest Tracker](https://docs.speedtest-tracker.dev/), [Apprise](https://github.com/caronc/apprise-api), [Duplicati](https://docs.duplicati.com/), [Homepage](https://gethomepage.dev/latest/), and [Watchtower](https://containrrr.dev/watchtower/) |
<!-- markdownlint-enable MD060 -->

> [!NOTE]
> 📚 Readarr has been scuttled from this fleet; use
> [Calibre Web Automated](https://github.com/scottgigawatt/calibre-web-automated)
> for book cargo.

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

Maraudarr writes only settings used by the selected services:

<!-- markdownlint-disable MD060 -->
| Setting | Why Ye Care |
| ------- | ----------- |
| 🔐 `PIA_USER` / `PIA_PASS` | Required when Privateerr and Gluetun are selected |
| 👤 `DEFAULT_PUID` / `DEFAULT_PGID` | Must be able to read and write the mounted files |
| 📦 `HOST_DOWNLOADS_PATH` | Shared download root for automation services |
| 🎥 `HOST_MOVIES_PATH`, `HOST_TV_PATH`, `HOST_ANIME_TV_PATH`, `HOST_SCENES_PATH` | Automation and Plex library paths used by the selected preset |
| 🔞 `WHISPARR_DATA_PATH` | High-level media root mounted into Whisparr at `/data` |
| 🎞️ `JELLYFIN_DATA_PATH` | High-level media root mounted into Jellyfin at `/data` |
| 🕰️ `TZ` | Timezone used by the containers |
| 🚪 `*_WEBUI_PORT` | Change only when a host port is already occupied |
<!-- markdownlint-enable MD060 -->

> [!TIP]
> 🗺️ Fresh paths match the selected preset. Service configuration stays under
> this repository's `config/` directory unless ye change its path in `.env`.

When the chart looks shipshape, launch the complete fleet in one shot:

```bash
make up
```

## Chart Yer Own Voyage 🧭

Open Maraudarr's full interactive voyage through Make:

```bash
make configure
```

Choose a preset from the Treasure Map above, inspect its default cargo, add or
remove services, and approve the final manifest. The prompts stay friendly,
lightly pirate, and clear about what will be written.

Useful commands for captains who already know the route:

<!-- markdownlint-disable MD060 -->
| Command | What It Does |
| ------- | ------------ |
| 🗺️ `make presets` | Shows each preset and its exact default cargo |
| 📦 `make services` | Lists every service Maraudarr can add |
| 🎞️ `make ship PRESET=jellyfin` | Generates standalone Jellyfin |
| 🎬 `make ship PRESET=plex` | Generates standalone Plex |
| 🔞 `make ship PRESET=boudoirr ADD_SERVICES=jellyfin` | Adds Jellyfin to Boudoirr |
| 🍜 `make ship ADD_SERVICES=sonarr-anime` | Adds the optional second Sonarr instance |
| 📰 `make ship REMOVE_SERVICES=qbittorrent,cleanuparr ADD_SERVICES=sabnzbd` | Switches the default Plundarr preset to Usenet only |
| 🔭 `make ship PRESET=boudoirr ADD_SERVICES=sabnzbd,watchtower` | Adds Usenet and update checks to Boudoirr |
<!-- markdownlint-enable MD060 -->

`ADD_SERVICES` and `REMOVE_SERVICES` accept comma-separated service IDs. For
example, switch Plundarr from torrents to NZBGet-only Usenet:

```bash
make ship REMOVE_SERVICES=qbittorrent,cleanuparr ADD_SERVICES=nzbget
```

Or keep qBittorrent and add SABnzbd for both downloader types:

```bash
make ship ADD_SERVICES=sabnzbd
```

Preset core services cannot be removed. Default services can be unchecked in
`make configure` or named in `REMOVE_SERVICES`.

> [!NOTE]
> 🧰 Rebuilds preserve existing values by variable name. Fresh voyages receive
> strong Speedtest Tracker, Duplicati, and NZBGet secrets, while values for
> temporarily unselected services wait safely in a marked footer until that
> cargo returns.

> [!NOTE]
> 🌊 Only selected download clients share Gluetun's network namespace. Prowlarr,
> Radarr, Sonarr, Bazarr, and the rest of the automation fleet use the normal
> project network. See [Docker Project Setup](./docs/SETUP.md) for preset
> networks, side-by-side deployments, and Jellyfin or Plex library paths.

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

| Command                       | What It Does                                            |
| ----------------------------- | ------------------------------------------------------- |
| 🗺️ `make ship`                | Prepares Maraudarr and generates the Plundarr stack     |
| 🧭 `make configure`           | Opens Maraudarr's interactive configurator              |
| 📜 `make presets`             | Lists presets and their exact default services          |
| 📦 `make services`            | Lists every service Maraudarr can select                |
| 🌊 `make update-maraudarr`    | Refreshes the published Maraudarr image                 |
| 🧾 `make compose-services`    | Lists services in the generated Plundarr chart          |
| 🔎 `make config`              | Prints Docker Compose's validated model                 |
| 🚀 `make up`                  | Starts the complete generated stack                     |
| ⚓ `make down`                | Stops and removes the generated stack                   |
| 💾 `make backup-config`       | Archives `config/` with a collision-safe timestamp      |
| ☠️ `make clean-config`        | Deletes the complete generated config directory         |
| 🐍 `make test-maraudarr-unit` | Runs Maraudarr's Python unit tests                      |
| 🧪 `make test-maraudarr`      | Tests presets and generated Compose combinations        |
| ⚒️ `make build-maraudarr`     | Builds the Maraudarr image locally from this repository |
| 📚 `make docs`                | Builds the strict developer documentation site          |
| 🔭 `make docs-serve`          | Previews developer documentation on localhost           |

Need the whole command chart? Run `make help`.

## More Treasure Maps 🗺️

| Scroll                                                               | When Ye Need It                                  |
| -------------------------------------------------------------------- | ------------------------------------------------ |
| 📚 [Developer Chart Room](https://scottgigawatt.github.io/plundarr/) | Architecture and generated Python reference      |
| ⚒️ [Inside Maraudarr](docker/README.md)                              | Image commands, security, tags, and architecture |
| 🖥️ [Synology Setup](docs/SETUP.md)                                   | Container Manager and host-path preparation      |
| 🧪 [Testing Hold](test/README.md)                                    | VPN, end-to-end, and stack validation            |
| 🛠️ [Contributin' Code Booty](docs/CONTRIBUTING.md)                   | Repository standards and pull requests           |
| 🤝 [The Pirate Code](docs/CODE_OF_CONDUCT.md)                        | Expectations for every member of the crew        |
| 🛡️ [Security Parley](docs/SECURITY.md)                               | Private vulnerability reporting                  |

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

| 📜 Shipboard Scroll                                 | ⚓ What It Helps Ye Do                                                  |
| --------------------------------------------------- | ----------------------------------------------------------------------- |
| 🛠️ [Patch the Hull](docs/CONTRIBUTING.md)           | Bring fixes and bright ideas aboard without springing leaks below deck. |
| 🤝 [The Crewmate Compact](docs/CODE_OF_CONDUCT.md)  | Keep the deck welcoming, useful, and free of plank-walking nonsense.    |
| 🔐 [Whisper to the Quartermaster](docs/SECURITY.md) | Report dangerous leaks privately before the sharks catch their scent.   |

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
