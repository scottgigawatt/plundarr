# 📰 SABnzbd Configuration

SABnzbd stores its settings here and downloads into `/downloads/usenet`. Its
traffic travels through Gluetun. Add your Usenet provider during SABnzbd's
first-run wizard.

Recommended paths and categories:

```text
Temporary downloads: /downloads/usenet/incomplete
Completed downloads: /downloads/usenet
radarr: movies
sonarr: tv
whisparr: movies
```

When connecting Radarr or Sonarr, use host `gluetun` and internal port `8085`.
The published `SABNZBD_WEBUI_PORT` is only for browsers outside Docker.

Copy SABnzbd's API key to `HOMEPAGE_VAR_SABNZBD_KEY` in `.env` if you want its
Homepage widget.
