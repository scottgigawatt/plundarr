🏴‍☠️ _Enjoyin' the spoils? Drop us a ⭐️ an' let the whole crew know about this fine treasure!_

![Docker](https://img.shields.io/badge/docker-ready-blue?logo=docker) ![VPN](https://img.shields.io/badge/VPN-PIA%20%7C%20WireGuard-green?logo=protonvpn) ![License](https://img.shields.io/github/license/scottgigawatt/plundarr?color=blue)

# Plundarr 🏴‍☠️

Ahoy, mateys! Welcome to Plundarr, the ultimate Docker Compose setup for all ye media needs. Manage yer favorite 'arr' apps and PIA VPN connections with ease, all while sailin' the high seas of secure and automated media management. ⚓️

## Captain's Log 📜

Plundarr be a collection of Docker Compose configurations to run a shipshape array of 'arr' tools like Sonarr, Radarr, and more, all securely navigated through Private Internet Access with WireGuard, managed by Gluetun. Avast, set sail on the digital seas with yer media ship well-equipped! 🏴‍☠️

## ⚡️ Quick Start

In a rush to set sail? Here's all ye need:

```bash
git clone --recurse-submodules git@github.com:scottgigawatt/plundarr.git
cd plundarr
cp example.env .env
vim .env  # Adjust yer settings
make up   # Hoist the stack!
```

Run `make help` to spy all the commands at yer disposal.

## Treasure Map 🗺️

| Shipmate          | What It Be                                                                                                                                  | Yo Ho Ho and More Info                                    |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| Privateerr        | 🏴‍☠️ Arrr, generate yer WireGuard config files fer PIA VPN connections! Protect yer precious booty with the finest VPN on the seven seas.  | [More info](https://github.com/scottgigawatt/privateerr)  |
| Gluetun           | 🌊 Batten down the hatches! Secure yer VPN route with WireGuard or OpenVPN, keepin' yer online doin's hidden from pryin' landlubber eyes.   | [More info](https://github.com/qdm12/gluetun)             |
| FlareSolverr      | 🔥 Outsmart them scurvy web defenses and keep yer plunderin' smooth as a fine barrel o' rum.                                                | [More info](https://github.com/FlareSolverr/FlareSolverr) |
| Prowlarr          | 🐾 The savvy first mate fer wranglin' all yer indexers, keepin' yer treasure map up-to-date with the latest and greatest booty.             | [More info](https://github.com/Prowlarr/Prowlarr)         |
| qBittorrent       | 🌊 Yer trusty first mate fer torrentin', hoist the colors and download with the might of a thousand cannons.                                | [More info](https://github.com/qbittorrent/qBittorrent)   |
| Radarr            | 🎥 Chart yer course fer cinematic riches! Automatically plunder new films and keep yer ship's library filled to the brim.                   | [More info](https://github.com/Radarr/Radarr)             |
| Sonarr            | 📺 Set sail on the seas of TV shows! Fetch new episodes and keep yer watchlist shipshape and Bristol fashion.                               | [More info](https://github.com/Sonarr/Sonarr)             |
| Bazarr            | 🦜 The parrot on yer shoulder squawkin' subtitles in many tongues fer all yer movies and TV shows.                                          | [More info](https://github.com/morpheus65535/bazarr)      |
| Readarr           | 📚 The captain's log fer yer ebooks. Keep yer digital library well-organized and as neat as a pin.                                          | [More info](https://github.com/Readarr/Readarr)           |
| Overseerr         | ⚓️ The quartermaster fer handlin' all yer crew's media requests, keepin' the ship runnin' smooth and the crew satisfied.                    | [More info](https://github.com/sct/overseerr)             |
| Cleanuperr        | 🧹 The swabbie keepin' yer ship clean by removin' blocked or unwanted downloads from Sonarr, Radarr, and yer download mates like qBittorrent.  | [More info](https://github.com/flmorg/cleanuperr)         |
| Speedtest Tracker | ⚡️ Keep a log of yer internet speed to make sure yer ISP ain't sellin' ye snake oil. Monitor yer connection and track yer speeds over time. | [More info](https://docs.speedtest-tracker.dev/)          |
| Duplicati         | 💣 Guard yer precious booty with backups, lest the kraken strike and sink yer ship.                                                         | [More info](https://www.duplicati.com)                    |
| Homepage          | 🏠 The captain's command deck fer all yer apps! A fully customizable, static dashboard fer keepin' tabs on all yer ship's systems.          | [More info](https://gethomepage.dev)                      |

## Hoist the Sails ⚓️

> [!NOTE]
> 🏴‍☠️ Before settin' sail, copy the example `.env` scroll and tweak it to yer own pirate code.

Manage Docker configuration environment variables in the [`.env`](./example.env) file. Override these variables easily on the command line when startin' the Docker Compose stack:

```bash
# Hoist the Jolly Roger and clone the repository with submodules
git clone --recurse-submodules git@github.com:scottgigawatt/plundarr.git
cd plundarr

# Copy the example environment file
cp example.env .env

# Open .env file and adjust the values to yer requirements
vim .env
```

For more details, see the example env configuration here:

- 🏴‍☠️ [Peek at the Pirate's Env Code](./example.env)

### Setting Sail on the Docker Seas 🌊🐋

See the Docker Compose [IPAM](https://docs.docker.com/compose/compose-file/06-networks/#ipam) documentation fer more information on configurin' the followin' [IP address information](https://github.com/scottgigawatt/plundarr/blob/main/example.env#L9-L11) fer the compose stack. Ye can plunder the example config straight from the Docker Compose scrolls!

```bash
#
# Chart the usable IP waters for this here subnet: 172.28.0.1 - 172.28.255.254
# Total number of scallywag hosts: 65,536
# Number of seaworthy hosts: 65,534
# Subnet mask (or should I say, pirate's mask): 255.255.0.0
#
COMPOSE_NETWORK_SUBNET="${COMPOSE_NETWORK_SUBNET:-172.28.0.0/16}"

#
# Plot the IP course for the containers: 172.28.5.1 - 172.28.5.254
# Total number of seadogs: 256
# Number of usable scurvy dogs: 254
# Subnet mask: 255.255.255.0 (aye, the smallest o' the masks)
#
COMPOSE_NETWORK_IP_RANGE="${COMPOSE_NETWORK_IP_RANGE:-172.28.5.0/24}"

#
# Set sail with the network gateway at the last IP address, the final port o' call
#
COMPOSE_NETWORK_GATEWAY="${COMPOSE_NETWORK_GATEWAY:-172.28.5.254}"
```

### ️Commandin' the Fleet with DSM Container Manager 🏴‍☠️

> [!TIP]
> 🦜 If ye be usin' Synology DSM 7.2, the Container Manager Project feature be yer secret map to quicker plunderin'.

To bring this booty into DSM 7.2 Container Manager's Project feature, follow these steps, ye sea dogs:

1. SSH into yer Synology system.
2. Recursively clone this repository with submodules, e.g., to `/volume1/docker/plundarr`.
3. In Container Manager, click **Project** then **Create**.
4. Provide a title, e.g., **plundarr**.
5. Set the path to the cloned repository.
6. Navigate through the UI prompts t' finish creatin' the project.

Check out the official Synology documentation [here](https://kb.synology.com/en-id/DSM/help/ContainerManager/docker_project?version=7) fer more on Container Manager Projects. Yo ho ho!

### Ensure Yer Tunnels Be Ready at Boot 🏴‍☠️⛏️

> [!IMPORTANT]
> ⚓️ Without the `/dev/net/tun` device, yer VPN ship be sinkin' at the docks! Make sure it be ready at boot, or face the kraken.
>
> 🏴‍☠️ Fer makin' sure `/dev/net/tun` be ready when yer Synology be wakin' from slumber, chart a course to the `tun.sh` scroll in the scripts hold an' follow the setup guide thar.
>
> - 🦜 [Peruse the tun.sh Parchment](scripts/tun.sh)
> - 🗺️ [Chart the Boot-Up Course](scripts/README.md#-tunsh--forge-the-vpn-passage)

### Spyglass Check 🔎

To confirm yer VPN sails be catchin' wind:

```bash
make test-vpn
```

Ye should see an IP that ain’t from yer home port. If not, batten down and check yer `.env` scroll.

## Navigatin' Troubled Waters ☠️🌊

> [!WARNING]
> ☠️ These configs be as wordy as an old sea dog's yarn! Use the Makefile commands if ye prefer smooth sailin' with fewer scrolls.

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
  build           - Builds the service stack.
  up              - Builds, (re)creates, and starts containers for services.
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

> [!CAUTION]
> 🏴‍☠️⚖️ Mind the legal seas! Ye must honor both the Apache 2 License and the MIT License, or be prepared to walk the plank.

This project be licensed under the Apache 2 License - see the [LICENSE](LICENSE) scroll for details.

The PIA manual connection scripts used in this repository be licensed under the [MIT license](https://choosealicense.com/licenses/mit/), buried [here](https://github.com/pia-foss/manual-connections/blob/master/LICENSE).

---

```
           |    |    |
          )_)  )_)  )_)
         )___))___))___)\
        )____)____)_____)\\
      _____|____|____|____\\\__
-----\                   /-----
  ^^^^^ ^^^^^^^^^^^^^^^^^^^^^
    ^^^^      ^^^^     ^^^    ^^
         The Pirate's Docker Fleet ☠️
```

Contribute or provide feedback to improve Plundarr. Arrr, happy sailing! 🏴‍☠️
