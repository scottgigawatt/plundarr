# Maraudarr Python package ⚒️

This package owns catalog loading, dependency resolution, comment-preserving rendering, config seeding, and the terminal interface.

| Module       | Responsibility                                       |
| :----------- | :--------------------------------------------------- |
| `catalog.py` | Loads and validates services and presets             |
| `models.py`  | Immutable catalog and plan models                    |
| `render.py`  | Writes Compose, `.env`, and selected config seeds    |
| `text.py`    | Preserves comments while extracting source fragments |
| `ui.py`      | Rich and plain terminal presentation                 |
| `cli.py`     | Public command parsing and orchestration             |

Run the package tests from the repository root with `make test`.

The [Maraudarr developer guide](../../../docs/development/maraudarr/index.md) explains the complete generation flow. Public Python interfaces are rendered from their source docstrings in the [generated API reference](../../../docs/development/maraudarr/reference/index.md).
