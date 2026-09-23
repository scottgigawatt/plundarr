# qBittorrent service chart ⚓

Adds the torrent downloader behind Gluetun. Maraudarr also adds its exposed ports and PIA port-forwarding commands to the generated Gluetun service.

The application waits for a healthy Gluetun service and follows explicit Compose-managed Gluetun restarts and updates through `depends_on.restart: true`. Automatic tunnel recovery keeps both containers running; it does not trigger this restart dependency.
