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

The `latest` channel identifies a stable release, `edge` identifies a successful `main` build, and a release/revision reference identifies the selected published source. Use documentation matching that source. A checkout build packages the catalog and seeds from its `docker/` directory.

Use `maraudarr:local` to keep checkout builds separate from published images. Export it, build the checkout, and use it for all generation commands in that shell:

```sh
export MARAUDARR_IMAGE=maraudarr:local
make build
make presets
make configure
```

For non-interactive generation, use `make ship PRESET=boudoirr` with the exported image reference and the complete intended additions/removals. `make build` packages the checkout into the configured local image. To select a published generator, set `MARAUDARR_IMAGE` to a verified version or digest and use its matching documentation; `make pull-image` pulls that configured reference.

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
