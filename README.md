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
services ye actually want, then packs each voyage into one commented
`docker-compose.yml` and matching `.env` file beneath `dist/<preset>/`. Docker
Compose and Synology Container Manager both get one final chart, while routine
configuration stays where it belongs: in that voyage's `.env`. ⚓️

## Captain's Log 📜

Plundarr has two clearly separate parts:

<!-- markdownlint-disable MD033 -->
| Component     | What It Does and Produces                                                                                                                                                                                                                                                                                                                                                                |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Maraudarr** | Short-lived Compose generator that chooses services, resolves dependencies, validates the result, and exits. Maraudarr is a multi-architecture image published to:<br>📦&nbsp;[GitHub Container Registry](https://github.com/scottgigawatt/plundarr/pkgs/container/maraudarr)<br>🐳&nbsp;[Docker Hub](https://hub.docker.com/r/scottgigawatt/maraudarr) |
| **Plundarr**  | Generated media stack that stays on yer host and runs the selected services. Each voyage contains:<br>🧾&nbsp;`dist/<preset>/docker-compose.yml`<br>⚙️&nbsp;`dist/<preset>/.env`<br>📂&nbsp;`dist/<preset>/config/` |
<!-- markdownlint-enable MD033 -->

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
workflow for `dist/plundarr/`. Curious captains can inspect or replay the
[recording source](./docs/demo/record-maraudarr-demo.sh).

> [!NOTE]
> The disposable recording uses inert VPN bootstrap stand-ins, so it needs no
> PIA credentials and opens no tunnel. A normal `make up` launches Privateerr
> and Gluetun from the generated chart.

## Treasure Map 🗺️

Choose a preset in `make configure`, or pass it to `make ship`. These are the
exact services included before ye add or remove anything:

| Preset           | Best For                             | Included Out of the Box                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| ---------------- | ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 🏴‍☠️&nbsp;`plundarr` | Movies and TV automation             | [Privateerr](https://github.com/scottgigawatt/privateerr), [Gluetun](https://github.com/qdm12/gluetun), [FlareSolverr](https://github.com/FlareSolverr/FlareSolverr), [Prowlarr](https://github.com/Prowlarr/Prowlarr), [qBittorrent](https://github.com/qbittorrent/qBittorrent), [Radarr](https://github.com/Radarr/Radarr), [Sonarr](https://github.com/Sonarr/Sonarr), [Bazarr](https://github.com/morpheus65535/bazarr), [Seerr](https://github.com/seerr-team/seerr), [Cleanuparr](https://github.com/Cleanuparr/Cleanuparr), [Speedtest Tracker](https://docs.speedtest-tracker.dev/), [Duplicati](https://www.duplicati.com), and [Homepage](https://gethomepage.dev/latest/) |
| 🔞&nbsp;`boudoirr`    | Whisparr automation                  | [Privateerr](https://github.com/scottgigawatt/privateerr), [Gluetun](https://github.com/qdm12/gluetun), [FlareSolverr](https://github.com/FlareSolverr/FlareSolverr), [Prowlarr](https://github.com/Prowlarr/Prowlarr), [qBittorrent](https://github.com/qbittorrent/qBittorrent), [Whisparr](https://github.com/Whisparr/Whisparr), and [Cleanuparr](https://github.com/Cleanuparr/Cleanuparr)                                                                                                                                                                                                                                                                                       |
| 🎞️&nbsp;`jellyfin`    | Standalone movies and TV playback    | [Jellyfin](https://jellyfin.org/docs/)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| 🎬&nbsp;`plex`        | Standalone movies and TV playback    | [Plex Media Server](https://support.plex.tv/articles/categories/plex-media-server/)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| 🧩&nbsp;`custom`      | A stack assembled service by service | Nothing; every service is selected explicitly                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |

Plundarr and Boudoirr use qBittorrent as their only default downloader. On
those presets, SABnzbd, NZBGet, Jellyfin, Plex, and Watchtower are never
silently added.

### Cargo Ye Can Add 🧩

Every catalog service can be added to a compatible preset. Maraudarr adds any
required foundation services and shows the resolved fleet before writing it.

| Cargo Hold       | Selectable Services                                                                                                                                                                                                                                                                                                                                                           |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| VPN foundation   | [Privateerr](https://github.com/scottgigawatt/privateerr) and [Gluetun](https://github.com/qdm12/gluetun)                                                                                                                                                                                                                                                                     |
| Download clients | [qBittorrent](https://github.com/qbittorrent/qBittorrent), [SABnzbd](https://sabnzbd.org/wiki/), and [NZBGet](https://nzbget.com/documentation/)                                                                                                                                                                                                                              |
| Automation       | [FlareSolverr](https://github.com/FlareSolverr/FlareSolverr), [Prowlarr](https://wiki.servarr.com/prowlarr), [Radarr](https://wiki.servarr.com/radarr), [Sonarr](https://wiki.servarr.com/sonarr), [Sonarr Anime](https://wiki.servarr.com/sonarr), [Whisparr](https://wiki.servarr.com/whisparr), [Bazarr](https://wiki.bazarr.media/), and [Seerr](https://docs.seerr.dev/) |
| Media servers    | [Jellyfin](https://jellyfin.org/docs/) and [Plex Media Server](https://support.plex.tv/articles/categories/plex-media-server/)                                                                                                                                                                                                                                                |
| Operations       | [Cleanuparr](https://cleanuparr.github.io/Cleanuparr/), [Speedtest Tracker](https://docs.speedtest-tracker.dev/), [Apprise](https://github.com/caronc/apprise-api), [Duplicati](https://docs.duplicati.com/), [Homepage](https://gethomepage.dev/latest/), and [Watchtower](https://containrrr.dev/watchtower/)                                                               |

> [!NOTE]
> 📚 Readarr has been scuttled from this fleet; use
> [Calibre Web Automated](https://github.com/scottgigawatt/calibre-web-automated)
> for book cargo.

## Hoist the Sails ⚓️

The default Plundarr voyage uses qBittorrent and needs no setup questions.
`make ship` uses Maraudarr locally when available, pulls it when missing, and
builds it from this checkout when no published image is available. It then
generates the complete Plundarr project in `dist/plundarr/`:

> [!TIP]
>
> ```sh
> git clone https://github.com/scottgigawatt/plundarr.git
> cd plundarr
> make ship
> ```

Maraudarr gives each preset its own complete deployment directory:

```text
dist/
└── plundarr/
    ├── docker-compose.yml
    ├── example.env
    ├── .env
    └── config/
```

> [!IMPORTANT]
> 🔐 Open `dist/plundarr/.env` before launch. Most defaults can stay aboard,
> but real PIA credentials and host storage paths must match yer own harbor.

### Focus on These Settings ⚙️

Maraudarr writes only settings used by the selected services:

| Setting                              | Why Ye Care                                                                     |
| ------------------------------------ | ------------------------------------------------------------------------------- |
| 🔐&nbsp;`PIA_USER`                   | Privateerr username; `make up` rejects empty or generated example values        |
| 🔐&nbsp;`PIA_PASS`                   | Privateerr password; `make up` rejects empty or generated example values        |
| 👤&nbsp;`DEFAULT_PUID`               | User ID that must be able to read and write the mounted files                   |
| 👤&nbsp;`DEFAULT_PGID`               | Group ID that must be able to read and write the mounted files                  |
| 📦&nbsp;`HOST_DOWNLOADS_PATH`        | Shared download root for automation services                                    |
| 🎥&nbsp;`HOST_MOVIES_PATH`           | Movies path used by automation services and Plex                                |
| 📺&nbsp;`HOST_TV_PATH`               | TV path used by automation services and Plex                                    |
| 🐉&nbsp;`HOST_ANIME_TV_PATH`         | Anime TV path used when Sonarr Anime is selected                                |
| 🔞&nbsp;`HOST_SCENES_PATH`           | Scenes path used by Boudoirr automation and Plex                                |
| 🔞&nbsp;`WHISPARR_DATA_PATH`         | High-level media root mounted into Whisparr at `/data`                          |
| 🎞️&nbsp;`JELLYFIN_DATA_PATH`         | High-level media root mounted into Jellyfin at `/data`                          |
| 🕰️&nbsp;`TZ`                         | Timezone used by the containers                                                 |
| 🚪&nbsp;`*_WEBUI_PORT`               | Change only when a host port is already occupied                                |

> [!TIP]
> 🗺️ Fresh paths match the selected preset. Service configuration stays under
> that preset's `dist/<preset>/config/` directory unless ye change its path in
> `.env`.

When the chart looks shipshape, launch the complete fleet in one shot:

> [!TIP]
>
> ```sh
> make up
> ```

### Chart Yer Own Voyage 🧭

Open Maraudarr's full interactive voyage through Make:

> [!TIP]
>
> ```sh
> make configure
> ```

Choose a preset from the 🗺️ Treasure Map above, inspect its default cargo, add or remove services, and approve the final manifest. The prompts stay friendly, lightly pirate, and clear about what will be written. 🏴‍☠️

#### 🗺️ Inspect Presets and Services

> [!TIP]
>
> ```sh
> make presets
> make services
> ```

#### 🎞️ Generate a Standalone Media Server

> [!TIP]
>
> ```sh
> make ship PRESET=jellyfin
> make ship PRESET=plex
> ```

#### 🧩 Add Common Extras

> [!TIP]
>
> ```sh
> make ship PRESET=boudoirr ADD_SERVICES=jellyfin
> make ship ADD_SERVICES=sonarr-anime
> make ship ADD_SERVICES=sabnzbd
> ```

#### 📰 Use Usenet Instead of Torrents

> [!TIP]
>
> ```sh
> make ship REMOVE_SERVICES=qbittorrent,cleanuparr ADD_SERVICES=nzbget
> ```

#### 🔭 Add Update Checks

> [!TIP]
>
> ```sh
> make ship PRESET=boudoirr ADD_SERVICES=sabnzbd,watchtower
> ```

`ADD_SERVICES` and `REMOVE_SERVICES` accept comma-separated service IDs. Preset
core services cannot be removed. Default services can be unchecked in
`make configure` or named in `REMOVE_SERVICES`; adding SABnzbd without removing
qBittorrent keeps both downloader types.

> [!NOTE]
> 🧰 Rebuilds preserve existing values by variable name. Fresh voyages receive
> strong Speedtest Tracker, Duplicati, and NZBGet secrets, while values for
> temporarily unselected services wait safely in a marked footer until that
> cargo returns.
>
> 🌊 Only selected download clients share Gluetun's network namespace. Prowlarr,
> Radarr, Sonarr, Bazarr, and the rest of the automation fleet use the normal
> project network. See [Docker Project Setup](./docs/SETUP.md) for preset
> networks, side-by-side deployments, and Jellyfin or Plex library paths.

### Synology Notes 📦

Synology Container Manager gets the same one-file deployment chart for each
preset:

1. Keep `dist/<preset>/.env` beside `dist/<preset>/docker-compose.yml`.
2. Create one Container Manager project from that preset directory's
   `docker-compose.yml`.
3. Review the generated chart, then launch the project.

Read the Synology setup scroll before the first voyage:

- 🖥️ [Docker Project Setup](./docs/SETUP.md)
- 🦜 [Synology Helper Scripts](scripts/README.md)

## Spyglass Check 🔎

Useful test voyages:

> [!TIP]
>
> ```sh
> make test
> make test-vpn
> make test-e2e
> make test-stack
> ```

> [!WARNING]
> ⚠️☠️ VPN tests use real PIA credentials from the selected preset's `.env` and
> may launch real containers. Read the [full testing chart](./test/README.md)
> before firing those cannons.

### 🧹 Clear Developer Artifacts

> [!TIP]
>
> ```sh
> make clean
> ```

This removes only generated documentation, Python caches, and test logs.
Deployment charts, `.env` files, config, backups, containers, volumes, and
images stay put.

## Navigatin' Troubled Waters ☠️🌊

> [!TIP]
> 🧭 `make help` is the complete grouped command chart. It marks the two
> intentionally destructive targets, `delete-config` and `nuke`, as danger
> commands; use `backup` before either one.

## More Treasure Maps & Crew Codes 🗺️

| Scroll                                                                                   | When Ye Need It                                 |
| ---------------------------------------------------------------------------------------- | ----------------------------------------------- |
| 📚&nbsp;[Developer Chart Room](https://scottgigawatt.github.io/plundarr/)                     | Maraudarr architecture and Python reference     |
| ⚒️&nbsp;[Maraudarr Overview](https://scottgigawatt.github.io/plundarr/development/maraudarr/) | Generator behavior, service charts, and testing |
| 🖥️&nbsp;[Synology Setup](https://scottgigawatt.github.io/plundarr/SETUP/)                    | Container Manager and host-path preparation     |
| 🛠️&nbsp;[Contributing](https://scottgigawatt.github.io/plundarr/CONTRIBUTING/)               | Repository standards and pull requests          |
| 🤝&nbsp;[Code of Conduct](https://scottgigawatt.github.io/plundarr/CODE_OF_CONDUCT/)          | Expectations for every member of the crew       |
| 🛡️&nbsp;[Security](https://scottgigawatt.github.io/plundarr/SECURITY/)                       | Private vulnerability reporting                 |
| 🧪&nbsp;[Testing Hold](test/README.md)                                                        | VPN, end-to-end, and stack validation           |
| 🦜&nbsp;[Synology Helper Scripts](scripts/README.md)                                          | Host-specific helper usage                      |

## Ship's Log 🏝️

| Compatibility               |   Status    | Details                                                                                                                                                                  |
| :-------------------------- | :---------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 🗄️&nbsp;Synology DiskStation    | ✅&nbsp;Tested    | DSM 7.4.1-90080 with Container Manager projects                                                                                                                               |
| 🍎&nbsp;macOS                    | ✅&nbsp;Tested    | macOS Tahoe 26 with Docker Desktop and Docker Compose                                                                                                                         |
| 🐧&nbsp;Other Docker hosts       | 🧭&nbsp;Expected | A compatible Docker Engine and Compose implementation should run the generated chart                                                                                          |
| 🏗️&nbsp;Maraudarr architectures | ✅&nbsp;Published | `linux/amd64`, `linux/arm64`, and `linux/arm/v7`                                                                                                                              |
| 📦&nbsp;Container registries     | ✅&nbsp;Mirrored  | [📦&nbsp;GitHub Container Registry](https://github.com/scottgigawatt/plundarr/pkgs/container/maraudarr) and [🐳&nbsp;Docker Hub](https://hub.docker.com/r/scottgigawatt/maraudarr) |

Third-party service images may support fewer architectures than Maraudarr.

## Articles of Agreement ⚖️

- This project be licensed under the [Apache License 2.0](LICENSE).
- Privateerr uses the unmodified upstream [PIA manual-connections](https://github.com/pia-foss/manual-connections) scripts under their upstream MIT license.
- Plundarr consumes the published Privateerr image and does not vendor the upstream PIA manual-connections scripts that Privateerr uses.

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
