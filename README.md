<hr />

<p align="center">
  <em>🏴‍☠️ Enjoyin' the spoils? Drop us a ⭐️ an' let the whole crew know about this fine treasure!</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Containers-Ahoy%21-blue?logo=docker" alt="Containers Ahoy" />
  <img src="https://img.shields.io/badge/Cloaked-by%20PIA%20%26%20WireGuard-green?logo=protonvpn" alt="Cloaked" />
  <img src="https://img.shields.io/github/license/scottgigawatt/privateerr?label=Pirate%20Code&color=blue" alt="Pirate Code" />
  <img src="https://img.shields.io/github/last-commit/scottgigawatt/privateerr?label=Last%20Plunder&logo=git" alt="Last Plunder" />
  <img src="https://img.shields.io/github/repo-size/scottgigawatt/privateerr?label=Cargo%20Hold" alt="Cargo Hold" />
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

<hr />

# Plundarr 🏴‍☠️

Ahoy, mateys! Welcome to Plundarr, the ultimate Docker Compose setup for all ye media needs. Manage yer favorite 'arr' apps and PIA VPN connections with ease, all while sailin' the high seas of secure and automated media management. ⚓️

## Captain's Log 📜

Plundarr be a collection of Docker Compose configurations to run a shipshape array of 'arr' tools like Sonarr, Radarr, and more, all securely navigated through Private Internet Access with WireGuard, managed by Gluetun. Avast, set sail on the digital seas with yer media safe from pryin' eyes—tucked away like treasure on a deserted isle! 🏝️

## ⚡️ Quick Start

In a rush to set sail? Here's all ye need:

```bash
git clone --recurse-submodules git@github.com:scottgigawatt/plundarr.git
cd plundarr
cp example.env .env
vim .env  # Adjust yer settings
make up   # Hoist the stack!
```

> [!TIP]
> Run `make help` to spy 🔎 all the commands at yer disposal.

## Treasure Map 🗺️

| Shipmate          | What It Be                                                                                                                                    | Yo Ho Ho and More Info                                    |
|-------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------|
| Privateerr        | 🏴‍☠️ Arrr, generate yer WireGuard config files fer PIA VPN connections! Protect yer precious booty with the finest VPN on the seven seas.    | [More info](https://github.com/scottgigawatt/privateerr)  |
| Gluetun           | 🌊 Batten down the hatches! Secure yer VPN route with WireGuard or OpenVPN, keepin' yer online doin's hidden from pryin' landlubber eyes.     | [More info](https://github.com/qdm12/gluetun)             |
| FlareSolverr      | 🔥 Outsmart them scurvy web defenses and keep yer plunderin' smooth as a fine barrel o' rum.                                                  | [More info](https://github.com/FlareSolverr/FlareSolverr) |
| Prowlarr          | 🐾 The savvy first mate fer wranglin' all yer indexers, keepin' yer treasure map up-to-date with the latest and greatest booty.               | [More info](https://github.com/Prowlarr/Prowlarr)         |
| qBittorrent       | 🌊 Yer trusty first mate fer torrentin', hoist the colors and download with the might of a thousand cannons.                                  | [More info](https://github.com/qbittorrent/qBittorrent)   |
| Radarr            | 🎥 Chart yer course fer cinematic riches! Automatically plunder new films and keep yer ship's library filled to the brim.                     | [More info](https://github.com/Radarr/Radarr)             |
| Sonarr            | 📺 Set sail on the seas of TV shows! Fetch new episodes and keep yer watchlist shipshape and Bristol fashion.                                 | [More info](https://github.com/Sonarr/Sonarr)             |
| Bazarr            | 🦜 The parrot on yer shoulder squawkin' subtitles in many tongues fer all yer movies and TV shows.                                            | [More info](https://github.com/morpheus65535/bazarr)      |
| Overseerr         | ⚓️ The quartermaster fer handlin' all yer crew's media requests, keepin' the ship runnin' smooth and the crew satisfied.                      | [More info](https://github.com/sct/overseerr)             |
| Cleanuparr        | 🧹 The swabbie keepin' yer ship clean by removin' blocked or unwanted downloads from Sonarr, Radarr, and yer download mates like qBittorrent. | [More info](https://github.com/Cleanuparr/Cleanuparr)     |
| Speedtest Tracker | ⚡️ Keep a log of yer internet speed to make sure yer ISP ain't sellin' ye snake oil. Monitor yer connection and track yer speeds over time.   | [More info](https://docs.speedtest-tracker.dev/)          |
| Duplicati         | 💣 Guard yer precious booty with backups, lest the kraken strike and sink yer ship.                                                           | [More info](https://www.duplicati.com)                    |
| Homepage          | 🏠 The captain's command deck fer all yer apps! A fully customizable, static dashboard fer keepin' tabs on all yer ship's systems.            | [More info](https://gethomepage.dev)                      |

## Hoist the Sails ⚓️

> [!IMPORTANT]
> 🏴‍☠️ Before settin' sail, copy [`example.env`](./example.env) to `.env` and tweak it to yer own pirate code.

Manage Docker configuration environment variables in the `.env` file. Override these variables easily on the command line when startin' the Docker Compose stack:

```bash
# Hoist the Jolly Roger and clone the repository with submodules
git clone --recurse-submodules git@github.com:scottgigawatt/plundarr.git
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
> ⚓️ Before hoistin' the sails, make sure to scour the [Docker Project Setup](./SETUP.md) scroll! It charts the course fer proper Docker networkin', Synology tweaks, firewall rules, and launchin' with Container Manager. Missin' these steps might leave yer ship dead in the water!

The [Docker Project Setup](./SETUP.md) parchment covers:

- 🌍🔧 [Configuring Docker Networking](./SETUP.md#chartin-the-docker-network-waters-)
- 🖥️🔧 [Synology Configuration](./SETUP.md#batten-down-the-hatches-️)
  - 🔥🛡️ [Updating Firewall Settings](./SETUP.md#guardin-the-ship-️)
  - 📦🚀 [Deploying With Container Manager](./SETUP.md#launchin-yer-fleet-)

Mind these steps, lest ye be marooned on a deserted isle! 🏝️

### Prep the Ship at Boot: Tunnels & Containers 🏴‍☠️⚙️

> [!CAUTION]
> ⚓️ Without the `/dev/net/tun` device, yer VPN ship be sinkin' at the docks! Make sure it be ready at boot, or face the kraken.

🏴‍☠️ Fer makin' sure `/dev/net/tun` be ready when yer Synology be wakin' from slumber, chart a course to the `tun.sh` scroll in the scripts hold an' follow the setup guide thar.

- 🦜 [Peruse the tun.sh Parchment](scripts/tun.sh)
- 🗺️ [Chart the Boot-Up Course](scripts/README.md#-tunsh--forge-the-vpn-passage)

> [!TIP]
> 🧰 And if ye run into mutiny where yer containers don't hoist in proper order on reboot, call upon the `compose_restart.sh` scroll! This script tears down an' rebuilds yer Docker fleet clean and proper, ensurin' each ship sets sail in the right sequence after a stormy system reboot.

To keep yer containers from stumblin' outta their hammocks in the wrong order 🛏️➡️🪝, study the scrolls below like a map to buried booty 🗺️💰☠️, yarrr!

- ⚙️ [Inspect the compose_restart.sh Scroll](scripts/compose_restart.sh)
- ⏱️ [Schedule the Crew with Task Scheduler](scripts/README.md#️-command-the-fleet-to-rise-on-boot)

### 🔎 Spyglass Check

To confirm yer VPN sails be catchin' wind:

```bash
❯ make test-vpn
sh scripts/test_vpn.sh
Running VPN container test...
Step 1: Running Docker container with VPN network:
docker run --rm --network=container:gluetun-latest alpine:latest sh -c 'apk add --no-cache wget >/dev/null 2>&1 && wget -qO- https://ipinfo.io'
Step 2: Received container response:
{
  "ip": "172.16.88.88",
  "city": "Tortuga",
  "region": "Rum Islands",
  "country": "XP",
  "loc": "21.4200,-71.1419",
  "org": "AS7777 The Jolly Rogers",
  "postal": "00000",
  "timezone": "Ocean/HighSeas",
  "readme": "https://ipinfo.io/missingauth"
}
Step 3: Getting host IP info from ipinfo.io...
Step 4: Received host response:
{
  "ip": "10.42.42.42",
  "hostname": "flagship.plundarr.local",
  "city": "Port Royal",
  "region": "Skull Coast",
  "country": "XP",
  "loc": "17.9355,-76.8419",
  "org": "AS1492 Blackbeard’s Backbone Ltd.",
  "postal": "99999",
  "timezone": "Ocean/SkullBay",
  "readme": "https://ipinfo.io/missingauth"
}
Step 5: Comparing container and host IPs...
VPN is active. Container IP: 172.16.88.88 (Tortuga, Rum Islands XP), Host IP: 10.42.42.42 (Port Royal, Skull Coast XP).
```

> [!WARNING]
> ⚠️☠️ Ye should see an IP that ain't from yer home port. If not, batten down and check yer `.env` scroll.

> [!NOTE]
> 🏴‍☠️ The `privateerr` image be used to generate the sacred PIA WireGuard config scroll that powers yer Gluetun VPN sails. By default, Plundarr pulls this image straight from GitHub Container Registry (GHCR), no buildin' required.
>
> But if the winds be against ye—or ye fancy testin' custom changes—ye can chart a local build instead using the [`docker-compose.build.yml`](./docker-compose.build.yml) override scroll.
>
> To build `privateerr` locally:
>
> ```bash
> make build
> ```
>
> This override be swappin' the pull fer a local build usin' yer own Dockerfile and variables from the `.env` scroll. Use it when the registry be unreachable or ye need to tinker with the hull below deck.

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
  all             - Builds and starts the service stack.
  build-depends   - Ensures build dependencies are installed.
  stop            - Stops running containers without removing them.
  down            - Stops and removes containers.
  clean           - Stops and removes containers, networks, volumes, and images.
  build           - Builds a local image of the privateerr service for use when it cannot be pulled from GHCR.
  up              - (Re)creates and starts containers for services.
  build-up        - Alias for build, up.
  start           - Starts existing containers for a service.
  test-vpn        - Obtain the VPN IP address and ensure the connection is working.
  config          - Renders the actual data model to be applied on the Docker Engine.
  env             - Prints the evaluated docker compose default env configuration.
  print-config    - Print the raw uncommented docker compose yaml configuration.
  print-env       - Print the raw uncommented docker compose env configuration.
  logs            - Shows logs for the service.
  open            - Opens the service site in the default web browser.
  run             - Alias for up, open, logs.
  help            - Displays this help message.
```

Dig deeper in the Cap'n's Makefile:

- 🔎 [Scour the Buildin' Blueprint](./Makefile)

## Ship's Log 🏝️

Plundarr has been tested on Synology DS1522+ and DS916+ runnin' DSM 7.2. But fear not, me hearties—this treasure ain't just fer Synology! She oughta run smooth on other shores like macOS, Linux, an' any land where Docker sails free.

## Articles of Agreement ⚖️

This project be licensed under the Apache 2 License—see the [LICENSE](LICENSE) scroll for details.

The PIA manual connection scripts used in this repository be licensed under the [MIT license](https://choosealicense.com/licenses/mit/), buried [here](https://github.com/pia-foss/manual-connections/blob/master/LICENSE).

---

```
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
