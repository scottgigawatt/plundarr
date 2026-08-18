# 🎥 Radarr Configuration

Radarr stores its settings here, sees downloads at `/downloads`, and manages the
movie library at `/movies`. Use these download-client categories:

```text
qBittorrent: radarr -> /downloads/torrents/movies
SABnzbd: radarr -> /downloads/usenet/movies
NZBGet: radarr -> /downloads/usenet/complete/movies
```

The shared `/downloads` path avoids remote path mappings and permits hardlinks
when the host filesystem supports them. Leave torrent payloads there while
seeding.
