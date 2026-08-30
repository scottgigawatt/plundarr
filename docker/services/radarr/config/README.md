# Radarr configuration 🎥

Shiver me timbers! This be the treasure chest holdin' the configuration files fer the **Radarr** service. These files will be mounted into the Radarr container as the service config directory, guidin' yer movie collection to safe harbor.

## Understand the service 🌊

Radarr be yer trusty mate, helpin' ye manage and organize yer movie collection, makin' sure ye never miss out on any cinematic treasures.

## Configure downloads and movie imports 📦

Radarr sees qBittorrent and SABnzbd downloads at `/downloads` and yer movie library at `/movies`. In Plundarr, `/downloads` maps to `HOST_DOWNLOADS_PATH`, while qBittorrent writes under `/downloads/torrents` and SABnzbd writes under `/downloads/usenet`.

Keep Radarr's download client paths pointed at `/downloads`. That shared path lets Radarr import completed movie downloads cleanly and use hardlinks when the host filesystem supports them.

If ye keep seeding, leave the original torrent payload in `/downloads` so qBittorrent can keep sharing it while Radarr manages the imported movie in `/movies`.

Use these download client categories:

```text
qBittorrent category: radarr
qBittorrent category save path: /downloads/torrents/movies

SABnzbd category: radarr
SABnzbd category folder/path: movies
```

For Usenet, point SABnzbd completed jobs at `/downloads/usenet` and temporary jobs at `/downloads/usenet/incomplete`; the `radarr` category then lands movie jobs in `/downloads/usenet/movies`.

Fer more details, inspect yer generated `dist/<preset>/docker-compose.yml` and `.env` files.

May yer movie collection be as vast as the seven seas, with hidden treasures awaitin' at every turn! 🌊⚔️
