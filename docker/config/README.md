# Generated configuration hold ⚓

Maraudarr copies this README into every generated `dist/<preset>/config/` directory. That hold keeps persistent configuration for the services selected in the voyage, including PIA WireGuard and port-forwarding files.

Services with managed seed files receive subfolders in `config/`. External operator-owned paths and named Docker volumes have separate storage boundaries. The root repository `config/` directory is not used by normal generated deployments.

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
| 📚 `calibre-web-automated` | Serves and automatically ingests a Calibre ebook library |
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
| 🚢 `portainer`         | Optional or standalone Docker management interface      |

Each folder follows the same general format: configuration files go in and persistent state stays. Docker Compose maps these directories automatically.

## Back up or reset the hold 🧽

From the repository root, replace `YOUR-PRESET` with the selected preset ID, such as `boudoirr`, and archive its config before a reset:

```sh
make backup PRESET=YOUR-PRESET
```

The archive does not include the deployment's `.env`, external Kometa checkout, or named-volume databases. Export application backups as needed, retain matching encryption keys and private settings separately, and verify an off-host recovery copy.

> [!CAUTION]
> `make delete-config` irreversibly deletes the selected host config tree and any backups stored inside it. Stop affected services and verify a recoverable backup before proceeding. Named-volume data requires separate management.

Only after reviewing that risk, use `make delete-config PRESET=YOUR-PRESET`. The next `make ship PRESET=YOUR-PRESET` voyage recreates missing seed files for the complete selection you specify; it does not restore databases, secrets, external state, or operator edits.

> [!CAUTION]
> Do not commit API keys, passwords, VPN credentials, generated WireGuard configuration, or other private application state.
