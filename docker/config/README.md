# Generated configuration hold ⚓

Maraudarr copies this README into every generated `dist/<preset>/config/` directory. That hold keeps persistent configuration for the services selected in the voyage, including PIA WireGuard and port-forwarding files.

> [!IMPORTANT]
> Every selected service has its own subfolder in `config/`. The root repository `config/` directory is not used by normal generated deployments.

## Find service configuration 🗺️

| Service                | Purpose                                                  |
| ---------------------- | -------------------------------------------------------- |
| 🏴‍☠️ `bazarr`          | Manages subtitles for movie and television libraries     |
| 🧹 `cleanuparr`        | Removes unwanted or blocked download files               |
| 💾 `duplicati`         | Backs up operator-selected data                          |
| 🌩️ `flaresolverr`      | Provides a proxy for supported challenge-protected sites |
| 🛡️ `gluetun`           | PIA WireGuard tunnel and port-forwarding quartermaster   |
| 🗺️ `homepage`          | Provides a dashboard for selected services               |
| 🎞️ `jellyfin`          | Open media server for movies, television, and anime      |
| 🎬 `plex`              | Containerized Plex Media Server option                   |
| 📜 `seerr`             | Manages media requests                                   |
| 🕵️‍♂️ `privateerr`        | PIA WireGuard and port-forwarding mapmaker for Gluetun   |
| 🧭 `prowlarr`          | Manages indexers for automation services                 |
| ⚓ `qbittorrent`       | Downloads and seeds torrents                             |
| 📰 `sabnzbd`           | Downloads, repairs, and extracts Usenet jobs             |
| 🎬 `radarr`            | Automates movie libraries                                |
| 📺 `sonarr`            | Automates television libraries                           |
| 🍜 `sonarr-anime`      | Optional anime TV captain with its own library hold      |
| 🌬️ `speedtest-tracker` | Measure the wind in yer sails (or yer bandwidth)         |
| 🔔 `apprise`           | Delivers notification cargo to supported services        |
| 🔞 `whisparr`          | Adult media automation for the Boudoirr voyage           |
| 🔭 `watchtower`        | Optional or standalone container image updater           |

Each folder follows the same general format: configuration files go in and persistent state stays. Docker Compose maps these directories automatically.

## Back up or reset the hold 🧽

To archive the selected config hold before a reset, run:

```sh
make backup PRESET=<preset>
```

To deliberately remove that generated config tree, run `make delete-config PRESET=<preset>`. The next `make ship PRESET=<preset>` voyage recreates only the directories and seed files needed by its selected services.

> [!CAUTION]
> Do not commit API keys, passwords, VPN credentials, generated WireGuard configuration, or other private application state.
