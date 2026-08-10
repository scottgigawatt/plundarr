# Maraudarr Developer Overview ⚒️

Maraudarr is the short-lived Python application that assembles a selected
Plundarr stack. It reads project-owned catalog and template sources, resolves
service dependencies, preserves existing environment values, validates the
result with Docker Compose, and writes the final deployment atomically.

## Responsibilities

Maraudarr owns:

- Loading services and presets from `docker/catalog/catalog.toml`.
- Resolving required services into deterministic output order.
- Extracting service definitions without discarding handwritten comments.
- Rendering the complete `docker-compose.yml`, `.env`, and `example.env`.
- Generating first-run application secrets without replacing existing values.
- Seeding selected `config/` directories without overwriting application state.
- Validating the generated Compose and environment pair when Docker is present.
- Presenting interactive Rich output and dependency-free plain output.

Maraudarr does **not** start the generated stack, manage long-running service
state, resolve Compose variables into the generated chart, or delete existing
configuration.

## Source Map

| Module | Responsibility |
|:--|:--|
| `catalog.py` | Load, validate, and resolve services and presets |
| `models.py` | Store immutable catalog and resolved-plan data |
| `render.py` | Render and atomically write deployment artifacts |
| `text.py` | Extract and format text while preserving comments |
| `ui.py` | Present rich and plain terminal experiences |
| `cli.py` | Parse commands and orchestrate one generator run |

The package uses the conventional `docker/src/maraudarr/` layout. Runtime
dependencies and build metadata remain under `docker/` because that directory
is the complete Maraudarr image context.

## Public and Private Interfaces

The [Python reference](reference/index.md) is generated from public classes,
methods, and functions. Names beginning with `_` are intentionally excluded
because they are implementation details rather than compatibility promises.
Private helpers still carry concise source documentation and targeted comments
where their transformations are not obvious.

Continue with the [architecture chart](architecture.md) to follow a complete
generation voyage.
