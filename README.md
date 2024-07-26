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

# Weigh anchor and start the container
PIA_USER=<pia_username> PIA_PASS=<pia_password> make
```

See the Docker Compose [IPAM](https://docs.docker.com/compose/compose-file/06-networks/#ipam) documentation for more information on configuring the following [IP address information](https://github.com/scottgigawatt/plundarr/blob/main/example.env#L9-L11) for the compose stack:

```bash
COMPOSE_NETWORK_SUBNET="${COMPOSE_NETWORK_SUBNET:-0.0.0.0/16}"
COMPOSE_NETWORK_IP_RANGE="${COMPOSE_NETWORK_IP_RANGE:-0.0.0.0/24}"
COMPOSE_NETWORK_GATEWAY="${COMPOSE_NETWORK_GATEWAY:-0.0.0.0}"
```

## Ensure Yer Tunnels Be Ready at Boot 🛠️⚓️🏴‍☠️

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

## Viewing the Configuration Details 🏴‍⚓️

The `plundarr` repo be providin' ye with tools t' view an' manage the environment an' Docker Compose configuration details. While the configuration files be heavily documented t' assist with understandin' an' customization, some o' ye may prefer t' see the uncommented versions fer simplicity.

### Makefile Targets 🏴‍☠️⚓️

The included `Makefile` contains targets t' help ye navigate these treacherous waters. Usin' these commands will provide ye with a clearer view o' the environment an' configuration details without the additional comments. Set sail with confidence, ye scurvy dogs! 🏴‍☠️

- **Print the evaluated Docker Compose default environment configuration:**

  ```sh
  ❯ make env
  COMPOSE_PROJECT_NAME=plundarr
  COMPOSE_NETWORK_SUBNET=0.0.0.0/16
  COMPOSE_NETWORK_IP_RANGE=0.0.0.0/24
  COMPOSE_NETWORK_GATEWAY=0.0.0.0
  HOST_VOLUME=/volume1
  HOST_DOWNLOADS_PATH=/volume1/downloads
  ...
  ```

- **Render the actual data model t' be applied on the Docker Engine:**

  ```sh
  make config
  ❯ make config
  docker-compose config
  name: plundarr
  services:
    bazarr:
      container_name: bazarr-latest
      depends_on:
        gluetun:
          condition: service_started
          restart: true
          required: true
  ...
  ```

- **Print the raw uncommented Docker Compose environment configuration:**

  ```sh
  ❯ make print-env
  COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-plundarr}"
  COMPOSE_NETWORK_SUBNET="${COMPOSE_NETWORK_SUBNET:-0.0.0.0/16}"
  COMPOSE_NETWORK_IP_RANGE="${COMPOSE_NETWORK_IP_RANGE:-0.0.0.0/24}"
  COMPOSE_NETWORK_GATEWAY="${COMPOSE_NETWORK_GATEWAY:-0.0.0.0}"
  HOST_VOLUME="${HOST_VOLUME:-/volume1}"
  HOST_DOWNLOADS_PATH="${HOST_DOWNLOADS_PATH:-/volume1/downloads}"
  ```

- **Print the raw uncommented Docker Compose YAML configuration:**

  ```sh
  ❯ make print-config
  ---
  version: "2.9"
  x-default-container: &default-container
    pull_policy: always
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: ${LOG_MAX_SIZE}
        max-file: ${LOG_MAX_FILE}
  x-default-environment: &default-environment
      TZ: ${TZ}
  x-arr-stack-environment: &arr-stack-environment
      <<: *default-environment
      PUID: ${DEFAULT_PUID}
      PGID: ${DEFAULT_PGID}
  x-arr-stack-container: &arr-stack-container
    <<: *default-container
    group_add:
      - ${DEFAULT_GROUP}
    environment:
      <<: *arr-stack-environment
  services:
    privateerr:
      image: ${PRIVATEERR_IMAGE}:${PRIVATEERR_TAG}
      build:
        context: config/privateerr/docker
        dockerfile: Dockerfile
        args:
          PRIVATEERR_BASE_IMAGE: ${PRIVATEERR_BASE_IMAGE}
          PRIVATEERR_BASE_TAG: ${PRIVATEERR_BASE_TAG}
          TZ: ${TZ}
          PIA_APP_HOME: ${PIA_APP_HOME}
      container_name: privateerr-${PRIVATEERR_TAG}
  ...
  ```

## Ship's Log 🏝️

Plundarr has been tested on Synology DS916+ running DSM 7.2.1-69057 Update 5. But fear not, me hearties! It should work on other lands as well.

## Articles of Agreement ⚖️

Licensed under the Apache 2 License - see [LICENSE](./LICENSE) for details.

---

Contribute or provide feedback to improve Plundarr. Arrr, happy sailing! 🏴‍☠️
