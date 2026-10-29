# Sonarr Anime configuration 📺

This independent Sonarr instance keeps its own database, settings, port, and anime library. Keep its managed root separate from the primary instance.

## Configure downloads and anime imports 📦

Sonarr Anime sees download clients at `/downloads` and imports finished anime into `/tv`. In Plundarr, `/tv` maps to `HOST_ANIME_TV_PATH` for this service only.

Use a separate root folder from the main Sonarr service. Mixing both captains into the same root can confuse imports, monitoring, and library cleanup.

Use these download client categories:

```text
qBittorrent category: sonarr-anime
qBittorrent category save path: /downloads/torrents/anime-tv

SABnzbd category: sonarr-anime
SABnzbd category folder/path: anime-tv
```

For Usenet, point SABnzbd completed jobs at `/downloads/usenet` and temporary jobs at `/downloads/usenet/incomplete`; the `sonarr-anime` category then lands episode jobs in `/downloads/usenet/anime-tv`.

Render the service into the final chart:

```sh
make ship ADD_SERVICES=sonarr-anime
```
