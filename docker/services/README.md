# Maraudarr service charts 🧩🏴‍☠️

Every selectable Plundarr service owns one directory in this hold. There are no separate core, extra, or addon charts.

Each service directory contains:

| File or folder    | Purpose                                                  |
| ----------------- | -------------------------------------------------------- |
| `compose.yml`     | One logical selection with one or more commented Compose definitions          |
| `environment.env` | Variables owned by that service                          |
| `config/`         | Optional files seeded into generated `config/<service>/` |
| `README.md`       | Human maintenance notes for the module                   |

A logical group such as Tracearr keeps its application, database, and Redis definitions in one chart and one picker choice. Declare their ordered keys through `compose_services` in the catalog; internal containers do not become separate selectable services.

Cross-service dependencies and final output order live in [`../catalog/catalog.toml`](../catalog/catalog.toml). Downloader ports and qBittorrent's Gluetun forwarding hooks are assembled by Maraudarr only when their matching services are selected.

> [!TIP]
> Add a new service by creating one directory with this shape, documenting its catalog entry, then extending the unit and Compose matrix tests.
