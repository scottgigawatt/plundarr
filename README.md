# Plundarr 🏴‍☠️

Plundarr is a generated Docker Compose media stack for Docker Compose and Synology Container Manager. Maraudarr, the included generator, turns your selected services into one commented `docker-compose.yml`, an editable `.env`, and configuration directories under `dist/<preset>/`, then exits.

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
  <a href="https://hub.docker.com/r/scottgigawatt/maraudarr"><img src="https://img.shields.io/docker/pulls/scottgigawatt/maraudarr?label=Maraudarr%20pulls&amp;logo=docker&amp;logoColor=white&amp;color=FF69B4" alt="Maraudarr image pulls on Docker Hub" /></a>
  <a href="https://github.com/scottgigawatt/plundarr/pkgs/container/maraudarr"><img src="https://img.shields.io/badge/Fleet-amd64%20%7C%20arm64%20%7C%20arm%2Fv7-6D28D9?logo=docker&amp;logoColor=white" alt="Maraudarr images for amd64, arm64, and arm/v7" /></a>
  <a href="https://github.com/scottgigawatt/plundarr/actions/workflows/build-and-push.yml"><img src="https://img.shields.io/badge/Bilge%20Check-Trivy-BE185D?logo=aqua&amp;logoColor=white" alt="Container images scanned with Trivy" /></a>
  <a href="https://www.bestpractices.dev/projects/14767"><img src="https://www.bestpractices.dev/projects/14767/badge" alt="OpenSSF Best Practices status" /></a>
</p>

<p align="center">─── ⛧ ───</p>

<p align="center">
  <em>☠️ Compose in dependency hell? Bribe the ferryman and enter</em>
  <a href="https://discord.gg/BpEGzWwGYf"><img src="https://img.shields.io/discord/1403601106315116626?label=%F0%9F%94%A5HADES%F0%9F%94%A5&logo=discord&logoColor=white&color=5865F2" alt="HADES Discord community" align="absmiddle" /></a>
</p>
<!-- markdownlint-enable MD033 -->

<!-- markdownlint-disable-next-line MD033 -->
<hr />

## Generate the default stack ⚡

Install Git, Make, Docker with Compose, and an active PIA subscription for the default VPN-enabled stack. Run from the cloned repository root. These commands build the catalog and seeds in this checkout; for a published image, select its matching source documentation through [generator revision selection](docs/development/maraudarr/index.md#choose-the-generator-revision).

```sh
git clone https://github.com/scottgigawatt/plundarr.git
cd plundarr
export MARAUDARR_IMAGE=maraudarr:local
make build
make ship
```

Keep `MARAUDARR_IMAGE` set for later generation commands. Maraudarr creates `dist/plundarr/docker-compose.yml`, `.env`, `example.env`, and `config/`. Plundarr is the generated deployment that remains after the generator exits. Privateerr prepares PIA configuration; Gluetun runs the VPN tunnel.

> [!IMPORTANT]
> Before launch, edit `dist/plundarr/.env`: set PIA credentials and confirm host paths, user/group IDs, timezone, network values, and ports. Follow the [setup guide](docs/setup.md) for application-specific preparation or Synology Container Manager deployment.

Validate without printing credentials, start, and inspect the stack:

```sh
docker compose --env-file dist/plundarr/.env -f dist/plundarr/docker-compose.yml config --quiet
make up
make ps
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

Use `make configure` for the interactive picker, or `make ship PRESET=YOUR-PRESET` with an ID below. Standalone media-server and utility presets do not require PIA.

| Preset                          | Purpose                                                                       |
| ------------------------------- | ----------------------------------------------------------------------------- |
| 🏴‍☠️&nbsp;`plundarr`              | Movies, television, and ebooks with VPN-protected torrent downloads           |
| 🔞&nbsp;`boudoirr`              | Whisparr automation, VPN downloads, and removable Velvarr/Jellyfin companions |
| 🎞️&nbsp;`jellyfin`              | Standalone Jellyfin media server                                              |
| 🎬&nbsp;`plex`                  | Standalone Plex Media Server                                                  |
| 📚&nbsp;`calibre-web-automated` | Standalone ebook library and ingest                                           |
| 🎭&nbsp;`duplex`                | Plex metadata/artwork, theme songs, and maintenance                           |
| 🔭&nbsp;`watchtower`            | Container image updates                                                       |
| 🚢&nbsp;`portainer`             | Docker management with Portainer CE                                           |
| 🧩&nbsp;`custom`                | Services selected individually                                                |

Browse [complete preset examples](examples/presets/README.md), or inspect the selected generator's current catalog with `make presets` and `make services`.

## Customize a deployment 🧩

`ADD_SERVICES` and `REMOVE_SERVICES` accept comma-separated IDs. Required core services cannot be removed; defaults and optional services can be changed. For example:

```sh
make ship ADD_SERVICES=lidarr,recyclarr
make ship REMOVE_SERVICES=qbittorrent,cleanuparr ADD_SERVICES=nzbget
make ship PRESET=boudoirr ADD_SERVICES=whisparr-alt
```

Repeat your complete intended selection on every regeneration. Existing `.env` values and application data survive, but saved values do not reselect services. Omitted running containers are not stopped automatically; review Compose orphans separately.

Use the [setup guide](docs/setup.md) for network planning, storage, media libraries, and optional services. Focused guides cover [VPN regions and recovery](docs/project-guides/vpn.md), [Velvarr](docs/project-guides/velvarr.md), [Jellyfin customization](docs/project-guides/jellyfin.md), [monitoring](docs/project-guides/monitoring.md), [Themerr](docs/project-guides/themerr.md), and [Portainer](docs/project-guides/portainer.md).

`.env` supplies Compose settings; applications still need their own setup. Jellyfin Web JSON/CSS, Recyclarr YAML, and external Kometa/PATTRMM settings may also need editing. Prepare those paths before launch. Recyclarr and Overlay Reset are profile-gated tools with deliberate invocation and dry-run/preview requirements in the setup guide.

## Inspect and maintain the stack 🔎

Use `make help` for commands. Replace `YOUR-PRESET` with the selected ID; omit it for default Plundarr:

Before a config archive, follow the [backup procedure](docker/config/README.md#back-up-or-reset-the-hold-): export application databases, stop affected writers, and retain `.env`, encryption keys, external state, and named-volume exports separately. `make backup` archives host config only. Verify an off-host recovery copy. `make down` preserves volumes and images; `make clean` removes disposable repository artifacts only.

```sh
make ps PRESET=YOUR-PRESET
make down PRESET=YOUR-PRESET
```

> [!CAUTION]
> `make nuke` stops the selected deployment and removes containers, networks, eligible images, the separate Maraudarr project, and scoped build cache; it preserves application volumes, deployment files, config, and host backups. Restarting may need image downloads. `make delete-config` deletes host config and exports stored there. Review backups and the selected preset before either operation.

`make config` and `make env` can print credentials. Keep their output private. [Live VPN/stack tests](test/README.md) can start services and replace test configuration; they are optional development checks for isolated environments.

## Read more and get help 📚

- [Plundarrpedia](https://scottgigawatt.github.io/plundarrpedia/): integrated deployment and platform walkthroughs.
- [Developer documentation](https://scottgigawatt.github.io/plundarr/): generator architecture, extension, tests, and API reference.
- [Host helper scripts](scripts/README.md): Linux, Synology, backup, restart, and status helpers.
- [Contributing](docs/CONTRIBUTING.md), [support](docs/SUPPORT.md), [security policy](docs/SECURITY.md), and [Code of Conduct](docs/CODE_OF_CONDUCT.md).

## Compatibility and licensing ⚖️

Maraudarr supports `linux/amd64`, `linux/arm64`, and `linux/arm/v7`; selected service images may support fewer architectures. Plundarr is tested with Synology Container Manager and Docker Desktop on macOS; compatible Linux Docker hosts are expected to work.

Plundarr uses the [Apache License 2.0](LICENSE) and the published Privateerr image. It does not vendor PIA's manual-connection scripts. Fair winds and no surprise port collisions. 🏴‍☠️
