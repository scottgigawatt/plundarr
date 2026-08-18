# ⚓ qBittorrent Configuration

qBittorrent stores its settings here and downloads into `/downloads/torrents`.
Radarr and Sonarr see the same files under `/downloads`, which avoids remote path
mappings and permits hardlinks when the host filesystem supports them.

Recommended paths and categories:

```text
Default save path: /downloads/torrents
Incomplete path: /downloads/torrents/incomplete
radarr: /downloads/torrents/movies
sonarr: /downloads/torrents/tv
whisparr: /downloads/torrents/movies
```

Keep downloaded files while seeding; Radarr and Sonarr manage their imported
copies in `/movies` and `/tv`.

## PIA Port Forwarding

Enable qBittorrent's web UI option to bypass authentication for localhost.
Gluetun uses that local API access to apply PIA's forwarded port, bind to the VPN
interface, and disable random ports and UPnP.
