# Shared chart timber 🪵

These files contain the common pieces wrapped around every generated Plundarr stack:

| Scroll            | Purpose                                                                |
| :---------------- | :--------------------------------------------------------------------- |
| `compose.yml`     | Shared YAML anchors, the `services:` opening, and network footer       |
| `environment.env` | Project, path, permission, healthcheck, logging, and timezone defaults |

Selectable service definitions belong under [`../services/`](../services/), not in these shared foundations.
