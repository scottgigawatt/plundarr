# Plundarr 🏴‍☠️

Ahoy, mateys! Welcome to Plundarr, the ultimate Docker Compose setup for all ye pirate-themed media needs. Manage yer favorite 'arr' apps and PIA VPN connections with ease, all while sailin' the high seas of secure and automated media management. ⚓️

## Captain's Log 📜

Plundarr be a collection of Docker Compose configurations to run a shipshape array of 'arr' tools like Sonarr, Radarr, and more, all securely navigated through Private Internet Access with WireGuard, managed by Gluetun. Avast, set sail on the digital seas with yer media ship well-equipped! 🏴‍☠️

## Treasure Map 🗺️

- **Gluetun**: Secure VPN routing with WireGuard or OpenVPN. [More info](https://github.com/qdm12/gluetun)
- **FlareSolverr**: Bypass pesky web protections. [More info](https://github.com/FlareSolverr/FlareSolverr)
- **Prowlarr**: Indexer manager for the 'arr' apps. [More info](https://github.com/Prowlarr/Prowlarr)
- **qBittorrent**: Torrent management extraordinaire. [More info](https://github.com/qbittorrent/qBittorrent)
- **Radarr**: Manage yer movies. [More info](https://github.com/Radarr/Radarr)
- **Sonarr**: Manage yer TV shows. [More info](https://github.com/Sonarr/Sonarr)
- **Bazarr**: Subtitle matey for movies and TV. [More info](https://github.com/morpheus65535/bazarr)
- **Readarr**: Keep yer ebooks in order. [More info](https://github.com/Readarr/Readarr)

## Hoist the Sails ⚓️

Manage Docker configuration environment variables in the [`.env`](./.env) file. Override these variables easily on the command line when startin' the Docker Compose stack:

```bash
# Hoist the Jolly Roger and clone the repository
git clone git@github.com:scottgigawatt/plundarr.git
cd plundarr

# Weigh anchor and start the container
make
```

Adjust the values of these environment variables to yer requirements.

## Ship's Log 🏝️

Plundarr has been tested on macOS Sonoma 14.5. But fear not, me hearties! It should work on other lands as well.

## Articles of Agreement ⚖️

Licensed under the Apache 2 License - see [LICENSE](./LICENSE) for details.

---

Contribute or provide feedback to improve Plundarr. Arrr, happy sailing! 🏴‍☠️
