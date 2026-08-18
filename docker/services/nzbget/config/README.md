# 📰 NZBGet Configuration

NZBGet stores its settings here and downloads into `/downloads/usenet`. Its
traffic travels through Gluetun. Maraudarr generates the web-interface password,
but you must add your Usenet provider in **Settings > News-Servers**.

Recommended paths:

```text
MainDir: /downloads/usenet
InterDir: ${MainDir}/incomplete
DestDir: ${MainDir}/complete
NzbDir: ${MainDir}/nzb
radarr: ${MainDir}/complete/movies
sonarr: ${MainDir}/complete/tv
whisparr: ${MainDir}/complete/movies
```

When connecting Radarr or Sonarr, use host `gluetun`, port `6789`, no SSL, and
the `NZBGET_USER` and `NZBGET_PASS` values from `.env`. The published
`NZBGET_WEBUI_PORT` is only for browsers outside Docker.

> [!IMPORTANT]
> Keep NZBGet's internal port at `6789`; its healthcheck and Gluetun mapping
> depend on it.
