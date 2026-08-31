# Test Maraudarr 🧪

Choose the smallest validation that proves the changed boundary, then broaden for Compose-generation, image, workflow, or documentation changes.

## Run unit tests

> [!TIP]
>
> ```sh
> make test-unit
> ```

The Python suite checks catalog resolution, comment preservation, environment state, first-run secrets, Homepage composition, healthcheck form, and safe config seeding. Tests run directly from `docker/src` so packaging mistakes do not hide source behavior.

## Run the generation matrix

> [!TIP]
>
> ```sh
> make test
> ```

This includes unit tests, packaged-image fallback checks, all product presets, Boudoirr's optional media-server combinations, torrent-only, Usenet-only, and combined downloader modes, the opt-in Lidarr and Recyclarr pair, the Duplex core/default split, Calibre-Web Automated both standalone and removed from Plundarr, plus default, opt-in, and standalone Watchtower placements. It also tests the compact Compose status, one-shot Watchtower, Overlay Reset, and Recyclarr commands, and secret-safe PIA preflight helpers. The matrix generates all eight presets beneath one `dist/` root. Every generated Compose/environment pair is inspected by Docker Compose without starting application containers. Unit coverage also keeps preset project names, Docker networks, project/service/tag container names, published ports, conditional Homepage integrations, and regeneration-safe configuration seeds correct.

## Check workflow helpers

> [!TIP]
>
> ```sh
> make test-workflows
> ```

This offline suite validates annotated release tags and main-branch ancestry, randomized build and documentation Discord payloads, both short and long command-line flags, registry tag mirroring, and cross-registry digest comparison. It uses fixture repositories, dry-run payloads, and a local Skopeo stub, so it never contacts Discord or either container registry.

The same target enforces synchronized SHA-256 build pins across Dockerfiles, the root example environment, and the build workflow. Every Docker metadata block must also expose the canonical `latest`, `edge`, `sha-...`, exact SemVer, minor, and stable-major channels. Disposable negative fixtures prove the checks reject drift rather than merely accepting the current repository.

## Validate image builds

> [!TIP]
>
> ```sh
> make build
> make test-image
> make build-platforms
> ```

The first command builds the production image shape. The image test runs the terminal UI tests with the image's exact dependencies, including Rich presentation, then applies Maraudarr's read-only, networkless runtime controls, generates one deployment in a disposable directory, and validates it with Docker Compose. The final command verifies every published CPU architecture: `linux/amd64`, `linux/arm64`, and `linux/arm/v7`.

## Validate documentation

Build the warning-free site or start a local preview:

> [!TIP]
>
> ```sh
> make docs
> make docs-serve
> ```

Both targets create `.venv-docs/` and install the pinned tools from `requirements-docs.txt` when needed. No separate MkDocs setup step is required. The documentation toolchain requires Python 3.14.7 and selects `python3.14` by default. Set `DOCS_PYTHON_BIN` to the exact interpreter path when it uses a different executable name. A virtual environment created by another Python release is disposable and is recreated automatically before dependency install. The generated `site/` directory is disposable and ignored by Git. CI performs the same strict build and publishes a fresh artifact from `main`.

## Check repository policy

Finish with:

> [!IMPORTANT]
>
> ```sh
> pre-commit run --all-files
> git diff --check
> ```

These checks cover secret detection, file hygiene, TOML/YAML syntax, workflow linting, shell correctness, synchronized build pins, and image-tag policy. Real VPN or downloader E2E tests require local credentials and should never expose `.env`, WireGuard state, or application databases in logs or commits.
