# Sonarr configuration 📺

Sonarr stores its database, settings, and credentials here. Configure its television root and download categories after launch.

## Configure downloads and television imports 📦

Sonarr sees qBittorrent and SABnzbd downloads at `/downloads` and your TV library at `/tv`. In Plundarr, `/downloads` maps to `HOST_DOWNLOADS_PATH`, while qBittorrent writes under `/downloads/torrents` and SABnzbd writes under `/downloads/usenet`.

Keep Sonarr's download client paths pointed at `/downloads`. That shared path lets Sonarr import completed episode downloads cleanly and use hardlinks when the host filesystem supports them.

If ye keep seeding, leave the original torrent payload in `/downloads` so qBittorrent can keep sharing it while Sonarr manages the imported episode in `/tv`.

Use these download client categories:

```text
qBittorrent category: sonarr
qBittorrent category save path: /downloads/torrents/tv

SABnzbd category: sonarr
SABnzbd category folder/path: tv
```

For Usenet, point SABnzbd completed jobs at `/downloads/usenet` and temporary jobs at `/downloads/usenet/incomplete`; the `sonarr` category then lands episode jobs in `/downloads/usenet/tv`.
