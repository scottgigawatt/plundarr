# Sonarr configuration 📺

Avast, me hearties! This here be the treasure chest where ye store the configuration scrolls fer the **Sonarr** service. These scrolls will be hoisted into the Sonarr container as the service config directory, keepin' yer TV show library in shipshape order.

## Understand the service 🌊

Sonarr be yer trusty mate, helpin' ye manage and organize yer TV show library, makin' sure ye never miss an episode of yer favorite series.

## Configure downloads and television imports 📦

Sonarr sees qBittorrent and SABnzbd downloads at `/downloads` and yer TV library at `/tv`. In Plundarr, `/downloads` maps to `HOST_DOWNLOADS_PATH`, while qBittorrent writes under `/downloads/torrents` and SABnzbd writes under `/downloads/usenet`.

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

For more details, set yer sights on the generated `dist/<preset>/docker-compose.yml` and `.env` files.

May yer TV show library be as vast as the seven seas, with adventures awaitin' at every watch! 📺⚔️
