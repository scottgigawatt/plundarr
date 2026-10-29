# Test Maraudarr 🧪

Choose the smallest validation that proves the changed boundary, then broaden for Compose-generation, image, workflow, or documentation changes.

## Run unit tests

```sh
make test-unit
```

The Python suite checks catalog resolution, comment preservation, environment state, first-run secrets, Homepage composition, healthcheck form, and safe config seeding. Tests run directly from `docker/src` so packaging mistakes do not hide source behavior.

## Run the generation matrix

```sh
make test
```

This runs unit tests, strict types, offline Make/workflow helpers, image-resolution fixtures, and a real Compose generation matrix. The matrix covers presets, optional services, downloader modes, environment preservation, config seeds, secrets, and maintenance profiles without starting application containers. Docker and image/tool preparation may need network access.

Use `make test-types` for focused strict Python checks or `make test-make-helpers` for host helper changes. The root Makefile and tests define the exact case inventory.

## Verify public preset references

The [preset reference guide](https://github.com/scottgigawatt/plundarr/blob/main/examples/presets/README.md) describes building the production generator from the source under review, generating public pairs, and comparing them with container output. Use the same explicit source-built image reference for both commands.

Reference generation validates both the generated `.env` and public `example.env` with real Docker Compose, without starting application services. It generates each preset twice and requires byte-identical public files. Only `docker-compose.yml` and secret-free `example.env` are published; deployment credentials and config seeds remain outside the reference tree. The curated custom example deliberately adds services to the otherwise empty custom preset.

## Check workflow helpers

```sh
make test-workflows
```

This offline suite validates annotated release tags and main-branch ancestry, randomized build and documentation Discord payloads, both short and long command-line flags, registry tag mirroring, and cross-registry digest comparison. It uses fixture repositories, dry-run payloads, and a local Skopeo stub, so it never contacts Discord or either container registry.

The same target enforces synchronized SHA-256 build pins across Dockerfiles, the root example environment, and the build workflow. Every Docker metadata block must also expose the canonical `latest`, `edge`, `sha-...`, exact SemVer, minor, and stable-major channels. Disposable negative fixtures prove the checks reject drift rather than merely accepting the current repository.

## Validate image builds

```sh
make build
make test-image
make build-platforms
```

The first command builds the production image shape. The image test runs the terminal UI tests with the image's exact dependencies, including Rich presentation, then applies Maraudarr's read-only, networkless runtime controls, generates one deployment in a disposable directory, and validates it with Docker Compose. The final command verifies every published CPU architecture: `linux/amd64`, `linux/arm64`, and `linux/arm/v7`.

## Validate documentation

Build the warning-free site or start a local preview:

```sh
make docs
make docs-serve
```

Both targets create `.venv-docs/` and install the pinned tools from `requirements-docs.txt` when needed. No separate MkDocs setup step is required. The documentation toolchain requires Python 3.15.2 and selects `python3.15` by default, as declared by `DOCS_PYTHON_VERSION` and `DOCS_PYTHON_BIN` in the root Makefile. Set `DOCS_PYTHON_BIN` to the exact interpreter path when it uses a different executable name. A virtual environment created by another Python release is disposable and is recreated automatically before dependency install. The generated `site/` directory is disposable and ignored by Git. CI performs the same strict build and publishes a fresh artifact from `main`.

## Check repository policy

Finish with:

```sh
pre-commit run --all-files
git diff --check
```

These checks cover secret detection, file hygiene, TOML/YAML syntax, workflow linting, shell correctness, synchronized build pins, and image-tag policy. Real VPN or downloader E2E tests require local credentials and should never expose `.env`, WireGuard state, or application databases in logs or commits.
