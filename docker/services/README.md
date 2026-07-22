# Maraudarr Service Charts 🧩🏴‍☠️

Every selectable Plundarr service owns one directory in this hold. There are no
separate core, extra, or addon charts.

Each service directory contains:

| File or folder    | Purpose                                                  |
| ----------------- | -------------------------------------------------------- |
| `compose.yml`     | One commented Docker Compose service definition          |
| `environment.env` | Variables owned by that service                          |
| `config/`         | Optional files seeded into generated `config/<service>/` |
| `README.md`       | Human maintenance notes for the module                   |

Cross-service dependencies and final output order live in
[`../catalog/catalog.toml`](../catalog/catalog.toml). Downloader ports and
qBittorrent's Gluetun forwarding hooks are assembled by Maraudarr only when
their matching services are selected.

> [!TIP]
> Add a new service by creating one directory with this shape, documenting its
> catalog entry, then extending the unit and Compose matrix tests.
