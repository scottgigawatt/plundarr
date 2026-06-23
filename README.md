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

Ahoy, mateys! Welcome to Plundarr, the ultimate Docker Compose setup for all ye media needs. Manage yer favorite 'arr' apps, PIA WireGuard VPN, and port-forwarded download routes with ease, all while sailin' the high seas of secure and automated media management. ⚓️

## Captain's Log 📜

Plundarr be a collection of Docker Compose configurations to run a shipshape array of 'arr' tools like Sonarr, Radarr, and more, all securely navigated through Private Internet Access with WireGuard and port forwarding, managed by Gluetun. Avast, set sail on the digital seas with yer media safe from pryin' eyes—tucked away like treasure on a deserted isle! 🏝️

- [Contributing](./docs/CONTRIBUTING.md)
- [Keep to the Code](./docs/CODE_OF_CONDUCT.md)
- [Security Policy](./docs/SECURITY.md)

## Treasure Map 🗺️

| Shipmate          | What It Be                                                                                                                                                  | Yo Ho Ho and More Info                                               |
|-------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------|
| Privateerr        | 🏴‍☠️ Arrr, generate yer PIA WireGuard config and Gluetun metadata so port forwarding knows which dock to hail.                                             | [More info](https://github.com/scottgigawatt/privateerr)             |
| Gluetun           | 🌊 Batten down the hatches! Secure yer VPN route with WireGuard and PIA port forwarding, keepin' yer online doin's hidden from pryin' landlubber eyes.      | [More info](https://github.com/qdm12/gluetun)                        |
| FlareSolverr      | 🔥 Outsmart them scurvy web defenses and keep yer plunderin' smooth as a fine barrel o' rum.                                                                | [More info](https://github.com/FlareSolverr/FlareSolverr)            |
| Prowlarr          | 🐾 The savvy first mate fer wranglin' all yer indexers, keepin' yer treasure map up-to-date with the latest and greatest booty.                             | [More info](https://github.com/Prowlarr/Prowlarr)                    |
| qBittorrent       | 🌊 Yer trusty first mate fer torrentin', hoist the colors and download with the might of a thousand cannons.                                                | [More info](https://github.com/qbittorrent/qBittorrent)              |
| SABnzbd           | 📰 Usenet cargo runner fer grabbin' NZBs, repairin' the haul, and droppin' finished loot into the same download hold.                                      | [More info](https://sabnzbd.org)                                     |
| Radarr            | 🎥 Chart yer course fer cinematic riches! Automatically plunder new films and keep yer ship's library filled to the brim.                                   | [More info](https://github.com/Radarr/Radarr)                        |
| Sonarr            | 📺 Set sail on the seas of TV shows! Fetch new episodes and keep yer watchlist shipshape and Bristol fashion.                                               | [More info](https://github.com/Sonarr/Sonarr)                        |
| Bazarr            | 🦜 The parrot on yer shoulder squawkin' subtitles in many tongues fer all yer movies and TV shows.                                                          | [More info](https://github.com/morpheus65535/bazarr)                 |
| **~~Readarr~~**   | ❌ Scuttled, matey—she sails no more. Hoist 📚 [Calibre Web Automated](https://github.com/scottgigawatt/calibre-web-automated) fer smooth e-book plunderin'. | [Set Sail ⚓](https://github.com/scottgigawatt/calibre-web-automated) |
| Seerr             | ⚓️ The quartermaster fer handlin' all yer crew's media requests, keepin' the ship runnin' smooth and the crew satisfied.                                    | [More info](https://github.com/seerr-team/seerr)                     |
| Cleanuparr        | 🧹 The swabbie keepin' yer ship clean by removin' blocked or unwanted downloads from Sonarr, Radarr, and yer download mates like qBittorrent.               | [More info](https://github.com/Cleanuparr/Cleanuparr)                |
| Speedtest Tracker | ⚡️ Keep a log of yer internet speed to make sure yer ISP ain't sellin' ye snake oil. Monitor yer connection and track yer speeds over time.                 | [More info](https://docs.speedtest-tracker.dev/)                     |
| Duplicati         | 💣 Guard yer precious booty with backups, lest the kraken strike and sink yer ship.                                                                         | [More info](https://www.duplicati.com)                               |
| Homepage          | 🏠 The captain's command deck fer all yer apps! A fully customizable, static dashboard fer keepin' tabs on all yer ship's systems.                          | [More info](https://gethomepage.dev)                                 |

## Hoist the Sails ⚓️

> [!IMPORTANT]
> 🏴‍☠️ Before settin' sail, copy [`example.env`](./example.env) to `.env` and tweak it to yer own pirate code.

Manage Docker configuration environment variables in the `.env` file. Override these variables easily on the command line when startin' the Docker Compose stack:

```bash
# Hoist the Jolly Roger and clone the repository
git clone git@github.com:scottgigawatt/plundarr.git
cd plundarr

# Copy the example environment file
cp example.env .env

# Open .env file and adjust the values to yer requirements
vim .env
```

For more details, see the example environment configuration here:

- 🏴‍☠️ [Peek at the Pirate's Env Code](./example.env)

### 📜 Important Setup Scroll! ☠️

> [!WARNING]
> ⚓️ Before hoistin' the sails, make sure to scour the [Docker Project Setup](./docs/SETUP.md) scroll! It charts the course fer proper Docker networkin', Synology tweaks, firewall rules, and launchin' with Container Manager. Missin' these steps might leave yer ship dead in the water!

The [Docker Project Setup](./docs/SETUP.md) parchment covers:

- 🌍🔧 [Configuring Docker Networking](./docs/SETUP.md#chartin-the-docker-network-waters-)
- 🖥️🔧 [Synology Configuration](./docs/SETUP.md#batten-down-the-hatches-️)
  - 🔥🛡️ [Updating Firewall Settings](./docs/SETUP.md#guardin-the-ship-️)
  - 📦🚀 [Deploying With Container Manager](./docs/SETUP.md#launchin-yer-fleet-)

Mind these steps, lest ye be marooned on a deserted isle! 🏝️

### Prep the Ship at Boot: Tunnels & Containers 🏴‍☠️⚙️

> [!CAUTION]
> ⚓️ Without the `/dev/net/tun` device, yer VPN ship be sinkin' at the docks! Make sure it be ready at boot, or face the kraken.

🏴‍☠️ Fer makin' sure `/dev/net/tun` be ready when yer Synology be wakin' from slumber, chart a course to the `tun.sh` scroll in the scripts hold an' follow the setup guide thar.

- 🦜 [Peruse the tun.sh Parchment](scripts/synology/tun.sh)
- 🗺️ [Chart the Synology Script Hold](scripts/README.md)

> [!TIP]
> 🧰 And if ye run into mutiny where yer containers don't hoist in proper order on reboot, call upon the `compose-restart.sh` scroll! This script tears down an' rebuilds yer Docker fleet clean and proper, ensurin' each ship sets sail in the right sequence after a stormy system reboot.

To keep yer containers from stumblin' outta their hammocks in the wrong order 🛏️➡️🪝, study the scrolls below like a map to buried booty 🗺️💰☠️, yarrr!

- ⚙️ [Inspect the compose-restart.sh Scroll](scripts/compose-restart.sh)
- ⏱️ [Schedule the Crew with Task Scheduler](scripts/README.md)

### 🔎 Spyglass Check

Basic test voyages:

```bash
make test-vpn
make test-e2e
make test-stack
```

> [!WARNING]
> ⚠️☠️ VPN tests can use real PIA credentials from `.env`. Read the full testing chart before a live voyage: [`test/README.md`](./test/README.md).

To scrub generated service config back to a fresh-clone state without deleting `.env`, run:

```bash
make reset-service-configs
```

> [!NOTE]
> 🏴‍☠️ The `privateerr` image generates the sacred PIA WireGuard config and port-forwarding metadata scroll that powers yer Gluetun VPN sails. Plundarr pulls this image straight from GitHub Container Registry (GHCR).
>
> Privateerr writes [`config/gluetun/wireguard/wg0.conf`](./config/gluetun/wireguard/wg0.conf) and [`config/gluetun/wireguard/privateerr.env`](./config/gluetun/wireguard/privateerr.env). Gluetun starts through [`config/gluetun/scripts/gluetun-entrypoint-wrapper.sh`](./config/gluetun/scripts/gluetun-entrypoint-wrapper.sh), reads `PIA_WG_SERVER_NAME`, exports `SERVER_NAMES`, and then hands control back to Gluetun so PIA port forwarding can dock proper.
>
> Gluetun also calls [`config/gluetun/scripts/qbittorrent-port-forwarding.sh`](./config/gluetun/scripts/qbittorrent-port-forwarding.sh) when PIA assigns or removes a forwarded port. That script updates qBittorrent's listening port through the local Web API so yer torrent sails catch the right wind.
>
> This keeps Synology DSM Container Manager on one main `docker-compose.yml` voyage: Privateerr, Gluetun, and the downstream services all set sail together.

## Navigatin' Troubled Waters ☠️🌊

> [!TIP]
> ️🧭🗺️ These configs be as wordy as an old sea dog's yarn! Use the Makefile commands if ye prefer less squawkin' 🦜 and cleaner decks 🧹.

The `Makefile` be yer trusty first mate fer handlin' this project with ease. It's packed with handy commands to hoist the stack, drop anchor, chart logs, test yer VPN tunnels, and swab the decks.

### Cap'n's Commands 🦜💀

Run `make help` to spy the full treasure map of commands. Let automation be the wind in yer sails—don't get marooned in manual seas.

```console
❯ make help
Usage: make [TARGET]

Targets:
  all                    Starts the service stack.
  build-depends          Ensures build dependencies are installed.
  check-env              Ensures .env exists before Compose-backed targets run.
  down                   Stops and removes the service stack.
  clean                  Stops the stack and restores example config files.
  nuke                   Removes containers, images, generated files, and restores example config.
  reset-config           Restores example wg0.conf and privateerr.env files.
  reset-service-configs  Removes ignored generated service config files without deleting .env.
  test-vpn               Validates running Privateerr and Gluetun VPN runtime state.
  test-e2e               Starts Privateerr, Gluetun, qBittorrent, and SABnzbd, validates VPN state, then removes them.
  test-stack             Starts every service, waits for health, then validates VPN and qBittorrent state.
  test-down              Stops the stack and restores example config files.
  test-logs              Shows logs for the service stack.
  up                     (Re)creates and starts every service.
  config                 Renders the Docker Compose model.
  env                    Prints the evaluated docker compose default env configuration.
  print-config           Prints the raw uncommented docker compose yaml configuration.
  print-env              Prints the raw uncommented docker compose env configuration.
  logs                   Shows logs for the service stack.
  open                   Opens the service sites in the default web browser.
  run                    Alias for up, open, logs.
  start                  Alias for up.
  stop                   Alias for down.
  help                   Displays this help message.
```

Dig deeper in the Cap'n's Makefile:

- 🔎 [Scour the Buildin' Blueprint](./Makefile)

## Ship's Log 🏝️

Plundarr has been tested on Synology DS1522+ and DS916+ runnin' DSM 7.2. But fear not, me hearties—this treasure ain't just fer Synology! She oughta run smooth on other shores like macOS, Linux, an' any land where Docker sails free.

## Articles of Agreement ⚖️

This project be licensed under the Apache 2 License—see the [LICENSE](LICENSE) scroll for details.

Privateerr uses the unmodified upstream [PIA manual-connections](https://github.com/pia-foss/manual-connections) scripts, which are licensed under the [MIT license](https://github.com/pia-foss/manual-connections/blob/master/LICENSE). Plundarr consumes the published Privateerr image and does not vendor those scripts.

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

Contribute or provide feedback to improve Plundarr. Arrr, happy sailing! 🏴‍☠️
