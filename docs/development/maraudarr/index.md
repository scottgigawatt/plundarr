---
icon: material/hammer-wrench
---

# Maraudarr developer overview ⚒️

Maraudarr is the short-lived Python application that assembles a selected Plundarr stack. It reads project-owned catalog and template sources, resolves service dependencies, preserves existing environment values, validates the result with Docker Compose, and writes the final deployment atomically.

## Understand responsibilities

Maraudarr owns:

- Loading services and presets from `docker/catalog/catalog.toml`.
- Resolving required services into deterministic output order.
- Extracting service definitions without discarding handwritten comments.
- Rendering each `dist/<preset>/docker-compose.yml`, `.env`, and `example.env`.
- Generating first-run application secrets without replacing existing values.
- Seeding selected `dist/<preset>/config/` directories without overwriting application state.
- Validating the generated Compose and environment pair when Docker is present.
- Presenting interactive Rich output and dependency-free plain output.

Maraudarr does **not** start the generated stack, manage long-running service state, resolve Compose variables into the generated chart, or delete existing configuration.

## Choose the generator revision

`make ship`, `make configure`, `make presets`, and `make services` run the configured `MARAUDARR_IMAGE`, which defaults to `ghcr.io/scottgigawatt/maraudarr:latest`. Make first reuses that exact local reference. If it is absent, Make pulls the configured reference; a failed pull triggers a local build from this checkout. The mounted repository is the output destination, not a live source-code mount into the generator.

A source checkout and a cached or published image can therefore describe different catalogs and seeds. The `latest` channel tracks stable releases, while `edge` tracks successful `main` builds. Features documented on `main` may not be in the latest stable image yet. A mutable channel also may have moved since a cached image was pulled; do not use it as evidence that output matches a particular checkout.

For source development or an unreleased feature, build a distinct local image from the checkout and pass that same reference to every generator command:

```sh
make build MARAUDARR_IMAGE=maraudarr:dev
make presets MARAUDARR_IMAGE=maraudarr:dev
make configure MARAUDARR_IMAGE=maraudarr:dev
```

For non-interactive generation, replace the final command with `make ship MARAUDARR_IMAGE=maraudarr:dev PRESET=boudoirr`, including any intended additions and removals. Rebuild after source changes. To use a published version instead, select a verified release or revision reference through `MARAUDARR_IMAGE`; `make pull-image` refreshes the configured reference without rebuilding this checkout.

## Explore the source map

| Module       | Responsibility                                    |
| :----------- | :------------------------------------------------ |
| `catalog.py` | Load, validate, and resolve services and presets  |
| `models.py`  | Store immutable catalog and resolved-plan data    |
| `render.py`  | Render and atomically write deployment artifacts  |
| `text.py`    | Extract and format text while preserving comments |
| `ui.py`      | Present rich and plain terminal experiences       |
| `cli.py`     | Parse commands and orchestrate one generation run |

The package uses the conventional `docker/src/maraudarr/` layout. Runtime dependencies and build metadata remain under `docker/` because that directory is the complete Maraudarr image context.

## Separate public and private interfaces

The [Python reference](reference/index.md) is generated from public classes, methods, and functions. Names beginning with `_` are intentionally excluded because they are implementation details rather than compatibility promises. Private helpers still carry concise source documentation and targeted comments where their transformations are not obvious.

Continue with the [architecture chart](architecture.md) to follow a complete generation voyage.
