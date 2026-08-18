# 📺 Sonarr Anime Configuration

This optional second Sonarr instance has its own database, port, and anime TV
library. It sees downloads at `/downloads` and maps `HOST_ANIME_TV_PATH` to
`/tv`; do not share that root folder with the main Sonarr instance.

```text
qBittorrent: sonarr-anime -> /downloads/torrents/anime-tv
SABnzbd: sonarr-anime -> /downloads/usenet/anime-tv
NZBGet: sonarr-anime -> /downloads/usenet/complete/anime-tv
```

Add it with `make ship ADD_SERVICES=sonarr-anime`.
