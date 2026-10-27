# qBittorrent service chart ⚓

Adds the torrent downloader behind Gluetun. Maraudarr also adds its Web UI port and PIA port-forwarding commands to the generated Gluetun service.

The application waits for a healthy Gluetun service and follows explicit Compose-managed Gluetun restarts and updates through `depends_on.restart: true`. Automatic tunnel recovery keeps both containers running; it does not trigger this restart dependency.

`QBITTORRENT_WEBUI_PORT` controls the host mapping, application listener, healthcheck, and default `QBITTORRENT_API_URL` together. Gluetun calls the hook installed by Privateerr with `QBITTORRENT_PORT_SYNC=true`; `QBITTORRENT_API_WAIT_SECONDS=300` bounds its startup wait. Set the sync toggle to `false` to skip hook updates.

PIA's forwarded peer port belongs to the VPN tunnel and needs no host publication. The hook applies that port and VPN interface to qBittorrent and disables random ports and UPnP. The seeded API permits unauthenticated access only from loopback, which is shared by all containers deliberately using Gluetun's network namespace; remote Web UI access still requires authentication. Existing qBittorrent configuration remains operator-owned.
