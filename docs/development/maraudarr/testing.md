# Testing Maraudarr 🧪

Choose the smallest validation that proves the changed boundary, then broaden
for generator, image, workflow, or documentation changes.

## Unit Tests

```bash
make test-maraudarr-unit
```

The Python suite checks catalog resolution, comment preservation, environment
state, first-run secrets, Homepage composition, healthcheck form, and safe
config seeding. Tests run directly from `docker/src` so packaging mistakes do
not hide source behavior.

## Generation Matrix

```bash
make test-maraudarr
```

This includes unit tests, packaged-image fallback checks, all product presets,
Boudoirr's optional media-server combinations, torrent-only, Usenet-only, and
combined downloader modes, plus opt-in Watchtower. The matrix also generates
all five presets beneath one `dist/` root. Every generated Compose/environment
pair is inspected by Docker Compose without starting application containers.
Unit coverage also keeps preset project names, Docker networks,
project/service/tag container names, and published ports collision-free.

## Image Builds

```bash
make build-maraudarr
make build-multiarch
```

The first command builds the production image shape. The second verifies every
published CPU architecture: `linux/amd64`, `linux/arm64`, and `linux/arm/v7`.

## Documentation

Install the isolated documentation toolchain once:

```bash
python3 -m pip install --requirement requirements-docs.txt
```

Build the warning-free site or start a local preview:

```bash
make docs
make docs-serve
```

The generated `site/` directory is disposable and ignored by Git. CI performs
the same strict build and publishes a fresh artifact from `main`.

## Repository Policy

Finish with:

```bash
pre-commit run --all-files
git diff --check
```

These checks cover secret detection, file hygiene, TOML/YAML syntax, workflow
linting, and shell correctness. Real VPN or downloader E2E tests require local
credentials and should never expose `.env`, WireGuard state, or application
databases in logs or commits.
