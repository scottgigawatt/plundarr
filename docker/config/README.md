# ⚓️ Config Booty

Ahoy, ye scurvy devils! This README is copied into every generated
`dist/<preset>/config/` directory. That hold keeps configuration maps for the
services selected in that voyage, including PIA WireGuard and port-forwarding
scrolls. 🏴‍☠️

> [!IMPORTANT]
> Every selected tool has its own subfolder in `config/`, ready to drop anchor
> with persistent volumes. The root repository `config/` directory is not used
> by normal generated deployments.

## 🗺️ Tools in the Plundarr Fleet

| Tool Name              | Purpose on the High Seas                                 |
| ---------------------- | -------------------------------------------------------- |
| 🏴‍☠️ `bazarr`            | Subtitle swabbie, makin' sure ye always read what's said |
| 🧹 `cleanuparr`        | Cleans up the seas of orphaned files and debris          |
| 💾 `duplicati`         | Backup ye booty — protect it from Davy Jones             |
| 🌩️ `flaresolverr`      | Bypasses cloudflare storms to get yer bounty             |
| 🛡️ `gluetun`           | PIA WireGuard tunnel and port-forwarding quartermaster   |
| 🗺️ `homepage`          | Central map to all yer ports — a true dashboard          |
| 🎞️ `jellyfin`          | Open media server for movies, television, and anime      |
| 🎬 `plex`              | Containerized Plex Media Server option                   |
| 📜 `seerr`             | Request board for new treasures — media requests ahoy    |
| 🕵️‍♂️ `privateerr`        | PIA WireGuard and port-forwarding mapmaker for Gluetun   |
| 🧭 `prowlarr`          | Jack of all trackers, finder of torrents                 |
| ⚓ `qbittorrent`       | Torrentin' machine — yer cargo hauler                    |
| 📰 `sabnzbd`           | Usenet download runner for NZB treasure                  |
| 🎬 `radarr`            | Movies! Add ‘em, find ‘em, automate ‘em                  |
| 📺 `sonarr`            | TV shows, season packs, binge treasures                  |
| 🍜 `sonarr-anime`      | Optional anime TV captain with its own library hold      |
| 🌬️ `speedtest-tracker` | Measure the wind in yer sails (or yer bandwidth)         |
| 🔔 `apprise`           | Delivers notification cargo to supported services        |
| 🔞 `whisparr`          | Adult media automation for the Boudoirr voyage           |
| 🔭 `watchtower`        | Optional container image update lookout                  |

> [!TIP]
> Each folder follows the same general format. Config files go in, persistent storage stays. If ye be usin' `docker-compose`, these mounts be auto-mapped for ye.

## Reset the Hold 🧽

To archive the selected config hold before a reset, run:

```sh
make backup-config PRESET=<preset>
```

To deliberately remove that generated config tree, run
`make clean-config PRESET=<preset>`. The next `make ship PRESET=<preset>`
voyage recreates only the directories and seed files needed by its selected
services.

> [!CAUTION]
> Don't commit any sensitive keys, secrets, or VPN credentials to this here public code — or the sharks'll be on ye in no time.

---

Happy plunderin' and may yer logs be ever green! ☠️⚓️
