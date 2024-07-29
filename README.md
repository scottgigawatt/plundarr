# Plundarr 🏴‍☠️

Ahoy, mateys! Welcome to Plundarr, the ultimate Docker Compose setup for all ye media needs. Manage yer favorite 'arr' apps and PIA VPN connections with ease, all while sailin' the high seas of secure and automated media management. ⚓️

## Captain's Log 📜

Plundarr be a collection of Docker Compose configurations to run a shipshape array of 'arr' tools like Sonarr, Radarr, and more, all securely navigated through Private Internet Access with WireGuard, managed by Gluetun. Avast, set sail on the digital seas with yer media ship well-equipped! 🏴‍☠️

## Treasure Map 🗺️

| Shipmate        | What It Be                                                                                                                     | Yo Ho Ho and More Info                                    |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------- |
| Privateerr      | 🏴‍☠️ Arrr, generate yer WireGuard config files for PIA VPN connections! Protect yer booty with the best VPN on the high seas.    | [More info](https://github.com/scottgigawatt/privateerr)  |
| Gluetun         | 🌊 Secure VPN routing with WireGuard or OpenVPN, to keep yer online activities hidden from the pryin' eyes of landlubbers.     | [More info](https://github.com/qdm12/gluetun)             |
| FlareSolverr    | 🔥 Outsmart those pesky web protections and keep yer plunderin' smooth.                                                        | [More info](https://github.com/FlareSolverr/FlareSolverr) |
| Prowlarr        | 🐾 The savvy indexer manager for all yer 'arr' apps. Keep yer treasure map updated with the latest and greatest loot.          | [More info](https://github.com/Prowlarr/Prowlarr)         |
| qBittorrent     | 🌊 Yer trusty first mate for torrent management, hoist the colors and download with might.                                     | [More info](https://github.com/qbittorrent/qBittorrent)   |
| Radarr          | 🎥 Chart the course for yer movie collection. Automatically plunder new films and keep the ship's library full.                | [More info](https://github.com/Radarr/Radarr)             |
| Sonarr          | 📺 Set sail for TV show management. Fetch new episodes and keep yer watchlist shipshape.                                       | [More info](https://github.com/Sonarr/Sonarr)             |
| Bazarr          | 🦜 The parrot on yer shoulder for subtitles, squawkin' in many tongues for movies and TV shows.                                | [More info](https://github.com/morpheus65535/bazarr)      |
| Readarr         | 📚 Captain's log for ebooks. Keep yer digital library well-organized and shipshape.                                            | [More info](https://github.com/Readarr/Readarr)           |
| Overseerr       | ⚓️ The quartermaster for media library requests, manage yer crew's demands with ease.                                          | [More info](https://github.com/sct/overseerr)             |
| Duplicati       | 💣 Guard yer precious booty with backups, in case the kraken strikes.                                                          | [More info](https://www.duplicati.com)                    |

## Hoist the Sails ⚓️

Manage Docker configuration environment variables in the [`.env`](./example.env) file. Override these variables easily on the command line when startin' the Docker Compose stack. Before ye begin, copy the example environment configuration file and update it to suit yer needs:

```bash
# Hoist the Jolly Roger and clone the repository with submodules
git clone --recurse-submodules git@github.com:scottgigawatt/plundarr.git
cd plundarr

# Copy the example environment file
cp example.env .env

# Open .env file and adjust the values to yer requirements
```

### Docker Network Configuration 🐋

See the Docker Compose [IPAM](https://docs.docker.com/compose/compose-file/06-networks/#ipam) documentation fer more information on configurin' the followin' [IP address information](https://github.com/scottgigawatt/plundarr/blob/main/example.env#L9-L11) fer the compose stack. Ye can plunder the example config straight from the Docker Compose scrolls!

```bash
COMPOSE_NETWORK_SUBNET="${COMPOSE_NETWORK_SUBNET:-172.28.0.0/16}"
COMPOSE_NETWORK_IP_RANGE="${COMPOSE_NETWORK_IP_RANGE:-172.28.5.0/24}"
COMPOSE_NETWORK_GATEWAY="${COMPOSE_NETWORK_GATEWAY:-172.28.5.254}"
```

### ️Managing the Project with DSM Container Manager 📦

To bring this booty into DSM 7.2 Container Manager's Project feature, follow these steps, ye sea dogs:

1. SSH into yer Synology system.
2. Recursively clone this repository with submodules, e.g., to `/volume1/docker/plundarr`.
3. In Container Manager, click **Project** then **Create**.
4. Provide a title, e.g., **plundarr**.
5. Set the path to the cloned repository.
6. Navigate through the UI prompts t' finish creatin' the project.

Check out the official Synology documentation [here](https://kb.synology.com/en-id/DSM/help/ContainerManager/docker_project?version=7) fer more on Container Manager Projects. Yo ho ho!

### Ensure Yer Tunnels Be Ready at Boot 🚆🛤️

To make sure the `/dev/net/tun` device be present on Synology Disk Station for use with VPN applications like Gluetun, follow these steps, me hearties:

1. **Setup Task Scheduler on Synology NAS:**

    Open Synology's Control Panel and follow these steps to run the script on boot:

    - Go to **Task Scheduler** 🗓️.
    - Click **Create** -> **Triggered Task** -> **User-defined script** ✍️.
    - Give the task a name, e.g., 'Create Tunnel' 🌉.
    - Set the user to `root` 🧙.
    - Set the event to **Boot-up** 🚀.
    - Check **Enabled** ✅.
    - Under **Task Settings**, enter the following command under **Run command** 💻:

      ```bash
      bash /volume1/docker/plundarr/scripts/tun.sh
      ```

    - Click **OK** to save the task 💾.

This ensures that the `/dev/net/tun` device be available whenever yer Synology NAS boots up, so ye can sail the seas with yer VPN secure and sound. Arrr! 🏴‍☠️

For more details, see the script [here](scripts/tun.sh) 📜.

## Navigatin' Troubled Waters ‍️☠️🌊

The `plundarr` repo be providin' ye with tools t' view an' manage the environment an' Docker Compose configuration details. While the configuration files be heavily documented t' assist with understandin' an' customization, some o' ye may prefer t' see the uncommented versions fer simplicity.

### Makefile Targets ⚙️

The included `Makefile` contains targets t' help ye navigate these treacherous waters. Usin' these commands will provide ye with a clearer view o' the environment an' configuration details without the additional comments. Set sail with confidence, ye scurvy dogs! 🏴‍☠️

```sh
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

## Ship's Log 🏝️

Plundarr has been tested on Synology DS916+ running DSM 7.2.1-69057 Update 5. But fear not, me hearties! It should work on other lands as well.

## Articles of Agreement ⚖️

Licensed under the Apache 2 License - see [LICENSE](./LICENSE) for details.

---

Contribute or provide feedback to improve Plundarr. Arrr, happy sailing! 🏴‍☠️
