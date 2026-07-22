# Maraudarr Python Package ⚒️

This package owns catalog loading, dependency resolution, comment-preserving
rendering, config seeding, and the terminal interface.

| Module | Responsibility |
|:--|:--|
| `catalog.py` | Loads and validates services and presets |
| `models.py` | Immutable catalog and plan models |
| `render.py` | Writes Compose, `.env`, and selected config seeds |
| `text.py` | Preserves comments while extracting source fragments |
| `ui.py` | Rich and plain terminal presentation |
| `cli.py` | Public command parsing and orchestration |

Run the package tests from the repository root with `make test-maraudarr`.
