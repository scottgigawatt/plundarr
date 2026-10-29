# Radarr configuration 🎥

Radarr stores its database, settings, and credentials here. Configure its movie root and download categories after launch.

## Configure downloads and movie imports 📦

Radarr sees qBittorrent and SABnzbd downloads at `/downloads` and your movie library at `/movies`. In Plundarr, `/downloads` maps to `HOST_DOWNLOADS_PATH`, while qBittorrent writes under `/downloads/torrents` and SABnzbd writes under `/downloads/usenet`.

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
