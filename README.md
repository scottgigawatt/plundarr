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

Adjust the values of these environment variables to yer requirements.

## Ship's Log 🏝️

Plundarr has been tested on Synology DS916+ running DSM 7.2.1-69057 Update 5. But fear not, me hearties! It should work on other lands as well.

## Articles of Agreement ⚖️

Licensed under the Apache 2 License - see [LICENSE](./LICENSE) for details.

---

Contribute or provide feedback to improve Plundarr. Arrr, happy sailing! 🏴‍☠️
