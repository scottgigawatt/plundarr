# NZBGet Downloader Plan 📰⚓️

## Outcome

Add NZBGet as an independently selectable Maraudarr download client without
changing the default cargo for the Plundarr, Boudoirr, or Custom presets.
Maraudarr must continue to generate one complete, commented
`docker-compose.yml`, one matching `.env`, and only the selected configuration
directories for Docker Compose and Synology Container Manager.

## Image Decision

Use `lscr.io/linuxserver/nzbget:${NZBGET_TAG}` with `NZBGET_TAG` defaulting to
`latest`.

This image matches the repository's existing qBittorrent, SABnzbd, and
LinuxServer service conventions:

- `PUID`, `PGID`, `TZ`, and `UMASK` work with the shared arr-stack anchors.
- `/config` stores persistent application state.
- `/downloads` stores download cargo.
- TCP port `6789` serves the Web UI and RPC API.
- Current LinuxServer manifests support `linux/amd64` and `linux/arm64`.

Do not build or publish a Plundarr-owned NZBGet image. Before merging, inspect
the selected tag's manifest and smoke-test its runtime contract so upstream
changes cannot silently invalidate the chart.

## Implementation Plan

### 1. Add One Selectable Service Chart

Create `docker/services/nzbget/` with the same ownership boundary as every
other Maraudarr service:

- `compose.yml` defines exactly one `nzbget` service.
- `environment.env` owns the NZBGet tag, Web UI port, config path, and initial
  control credentials.
- `README.md` explains the chart for maintainers.
- `config/README.md` documents first-run setup, paths, categories, credentials,
  and Radarr/Sonarr integration without seeding or replacing `nzbget.conf`.

The Compose service should:

- inherit `*arr-stack-container`;
- use `lscr.io/linuxserver/nzbget:${NZBGET_TAG}`;
- use `network_mode: service:gluetun`;
- mount `${NZBGET_CONFIG_PATH}` at `/config`;
- mount `${HOST_USENET_DOWNLOADS_PATH}` at `/downloads/usenet`;
- depend on healthy Gluetun;
- use an exec-form healthcheck that verifies the NZBGet server on internal port
  `6789` without requiring shell expansion;
- preserve the established two-space inline-comment spacing and block-local
  comment alignment.

Prefer an NZBGet client status command using `/config/nzbget.conf` for the
healthcheck because the Web UI uses HTTP Basic authentication. Confirm the
exact command against the selected image before committing it.

### 2. Register NZBGet With Maraudarr

Add `services.nzbget` to `docker/catalog/catalog.toml` in the **Download
clients** category, ordered after SABnzbd, with `requires = ["gluetun"]`.

Do not add NZBGet to any preset default. It should appear automatically in
`make services`, the interactive picker, `--add nzbget`, and
`OPTIONAL_SERVICES=nzbget` through the existing catalog-driven interfaces.

Update `docker/src/maraudarr/render.py` to:

- add `${NZBGET_WEBUI_PORT}:6789` to Gluetun only when NZBGet is selected;
- retain or remove the Homepage NZBGet environment group with the service;
- render an NZBGet card in Homepage's Downloads group;
- generate a strong first-run `NZBGET_PASS` while preserving an existing value
  across regeneration.

Update the completion guidance in `docker/src/maraudarr/ui.py` so an NZBGet
voyage reminds the captain to inspect its download and config paths.

### 3. Add Homepage Without New Assets

Add `docker/services/homepage/config/fragments/nzbget.yaml` using Homepage's
built-in `nzbget.svg` icon and `nzbget` widget. The widget needs the internal
URL plus NZBGet's control username and password.

Add the corresponding conditional environment mappings to Homepage's Compose
chart. Reuse `NZBGET_USER` and `NZBGET_PASS` for the widget instead of storing a
second copy of the same credential. No repository-owned icon or raster asset is
needed.

### 4. Keep VPN And Runtime Targets Aware of the Client

Update the Makefile's centralized service variables and optional-service
expressions:

- add `NZBGET_SERVICE`;
- include NZBGet in `E2E_DOWNLOAD_SERVICES` only when selected;
- include the selected host Web UI port in `GLUETUN_DOWNLOADER_PORTS`;
- pass the selected client set into the runtime checks.

Extend the VPN/E2E test path to wait for NZBGet's healthcheck. Keep
qBittorrent-specific PIA forwarded-port assertions scoped to qBittorrent;
NZBGet needs VPN containment and health validation, not torrent port-forwarding
configuration.

### 5. Document the User Journey

Update the root `README.md` service table and examples with a lightly
pirate-themed NZBGet entry. Document these supported shapes:

```sh
make ship PRESET=plundarr OPTIONAL_SERVICES=nzbget
make ship PRESET=plundarr OPTIONAL_SERVICES=sabnzbd,nzbget
make ship PRESET=plundarr OPTIONAL_SERVICES=qbittorrent,sabnzbd,nzbget
```

In `docker/services/nzbget/config/README.md`, document:

- changing the generated initial control password;
- using `/downloads/usenet/incomplete` and `/downloads/usenet/complete`;
- creating `radarr` and `sonarr` categories;
- connecting Radarr and Sonarr to `gluetun:6789`, because NZBGet shares
  Gluetun's network namespace;
- keeping the same `/downloads` path visible to the automation services so
  imports do not require remote path mappings;
- using `NZBGET_WEBUI_PORT` only as the host-side Web UI port.

Update `test/README.md` with an NZBGet E2E example.

### 6. Prove Generation, Preservation, And Runtime Behavior

Extend `docker/tests/test_maraudarr.py` to cover:

- catalog ordering and automatic Gluetun/Privateerr dependencies;
- conditional Gluetun port publication;
- conditional Compose and environment sections;
- secure first-run password generation and existing-value preservation;
- conditional Homepage variables and Downloads card placement;
- selected-only `config/nzbget/` creation;
- comment spacing, shared anchors, and direct healthcheck policy.

Extend `test/test-maraudarr-matrix.sh` with isolated NZBGet-only and
all-download-client voyages. Do not render matrix cases concurrently because
generated output paths are shared unless explicitly isolated.

Run the smallest checks first, then the full repository gates:

```sh
make test-maraudarr-unit
make test-maraudarr
docker compose --env-file .env -f docker-compose.yml config --quiet
make build-maraudarr
make build-multiarch
pre-commit run --all-files
git diff --check
```

When Docker and valid VPN credentials are available, also run an NZBGet-only
runtime voyage:

```sh
make ship PRESET=plundarr OPTIONAL_SERVICES=nzbget
make test-e2e OPTIONAL_SERVICES=nzbget
```

Before any final commit, regenerate the intended default Plundarr artifact and
confirm that adding a selectable option did not silently change preset cargo or
overwrite existing application state.

## Acceptance Criteria

- NZBGet can be selected alone or beside either existing download client.
- Selecting NZBGet automatically includes Privateerr and Gluetun.
- Unselected NZBGet Compose, environment, Homepage, and config content is
  absent from generated output.
- Existing `.env` values and application state survive regeneration.
- The generated deployment remains one Synology-compatible Compose file.
- NZBGet traffic uses Gluetun, its host port is configurable, and its health is
  verified without a shell-only probe.
- Homepage renders the built-in NZBGet card only when both Homepage and NZBGet
  are selected.
- Unit, matrix, Compose, image, pre-commit, and diff checks pass.
