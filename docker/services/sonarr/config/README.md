# 📺 Sonarr Configuration

Sonarr stores its settings here, sees downloads at `/downloads`, and manages the
TV library at `/tv`. Use these download-client categories:

```text
qBittorrent: sonarr -> /downloads/torrents/tv
SABnzbd: sonarr -> /downloads/usenet/tv
NZBGet: sonarr -> /downloads/usenet/complete/tv
```

The shared `/downloads` path avoids remote path mappings and permits hardlinks
when the host filesystem supports them. Leave torrent payloads there while
seeding.
