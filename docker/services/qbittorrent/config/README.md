# qBittorrent configuration ⚓

qBittorrent keeps its database and settings here; preserve them during regeneration and include them in consistent backups.

## Configure torrent download paths 📦

qBittorrent writes downloads under `/downloads/torrents` inside the container. In Plundarr, that path maps to `HOST_TORRENTS_DOWNLOADS_PATH` on the host. Radarr and Sonarr mount the broader `HOST_DOWNLOADS_PATH` at `/downloads`, so they see the same completed torrent files at `/downloads/torrents/...`.

Keep qBittorrent, Radarr, and Sonarr aligned under `/downloads`. If qBittorrent saves to a different path that Radarr or Sonarr cannot see, imports can fail or copy files instead of using hardlinks.

With SABnzbd aboard, keep torrent cargo in its own lane:

```text
Default Save Path: /downloads/torrents
Keep incomplete torrents in: /downloads/torrents/incomplete
```

Create qBittorrent categories so Radarr and Sonarr can sort downloads by library type:

```text
Category: radarr
Save path: /downloads/torrents/movies

Category: sonarr
Save path: /downloads/torrents/tv
```

Then set the qBittorrent download client category in Radarr to `radarr` and in Sonarr to `sonarr`.

## Preserve seeding and imports ⚓

If you seed torrents, qBittorrent needs the original downloaded payload to remain under `/downloads/torrents`. Radarr and Sonarr can import media into `/movies` or `/tv` while qBittorrent keeps seeding from `/downloads/torrents`.

If you do not plan to seed, configure qBittorrent, Radarr, and Sonarr cleanup behavior intentionally so completed torrents do not pile up in the download hold after import.

## Enable port forwarding 🧭

Gluetun updates qBittorrent's listening port when PIA assigns a forwarded port. For that local API call to work, enable qBittorrent's Web UI setting to bypass authentication for clients on localhost.

When the port-forwarding script runs, it sets qBittorrent to:

- Listen on Gluetun's forwarded port.
- Bind to Gluetun's VPN interface.
- Disable random ports.
- Disable UPnP port mapping.

## Understand the seeded configuration 🗺️

The seeded `qBittorrent.conf` stays data-only. qBittorrent stores settings with Qt's INI-backed configuration format and may rewrite the file, so this README keeps the explanations durable instead of relying on inline comments that could disappear after the first application save.

| Section | Settings | Why Plundarr seeds them |
| --- | --- | --- |
| `[AutoRun]` | `enabled`, `program` | Disables arbitrary program execution after torrent events. |
| `[BitTorrent]` | save path, temporary path, listen port, queueing, share action | Keeps completed and incomplete torrents under `/downloads/torrents`. |
| `[LegalNotice]` | `Accepted` | Records the initial notice acknowledgement so the service can start unattended. |
| `[Meta]` | `MigrationVersion` | Tracks qBittorrent's internal configuration version. |
| `[Network]` | cookies, proxy profiles, port forwarding | Leaves VPN routing to Gluetun and prevents application-level port forwarding. |
| `[Preferences]` | Web UI access, download paths, UPnP, port range | Permits localhost-only automation while the Gluetun hook updates the listening port safely. |
