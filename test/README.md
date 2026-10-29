# Test Plundarr deployments 🧪🏴‍☠️

Use the [developer testing guide](https://github.com/scottgigawatt/plundarr/blob/main/docs/development/maraudarr/testing.md) for unit, strict type, helper, workflow, image, generation-matrix, and documentation checks. This page covers optional live deployment tests and their recovery boundaries.

## Find a test

| Directory | Responsibility |
| --- | --- |
| `generator/` | Image resolution, hardened generator smoke checks, and real Compose syntax matrix |
| `helpers/` | Offline Make/workflow/policy and cleanup-ownership fixtures |
| `policy/` | Build-pin synchronization and image-channel rules |
| `runtime/` | Live stack health, VPN/port forwarding, and isolated cleanup acceptance |
| `stubs/` | Deterministic command substitutes used only by offline tests |
| `examples/` | Secret-free WireGuard/forwarding fixtures used by disposable live tests |

Make targets are the normal interface; individual scripts are for focused diagnosis. Stub results do not prove real container health.

## Prepare an isolated live test

Replace `YOUR-PRESET` with one catalog ID and use it consistently. Run mutating tests only with disposable bind-mounted config, media, and downloads on an isolated Docker test daemon, preferably a disposable host or VM. Watchtower and Portainer may access the Docker socket; it must belong to the test environment. Different checkout, project, preset, or Docker context names alone do not isolate host data or sockets.

> [!CAUTION]
> `make test-e2e` and `make test-stack` replace selected WireGuard and forwarding files with examples before and after validation and can interrupt services. Back up disposable test state and protect credentials. Interrupted commands can leave services or sensitive state behind; inspect before recovery. Never use these targets to diagnose an operator deployment.

The [generator revision guide](https://github.com/scottgigawatt/plundarr/blob/main/docs/development/maraudarr/index.md#choose-the-generator-revision) explains selecting the source-built image. Generate the full desired selection before live tests. Supply test credentials privately; never publish `.env`, `wg0.conf`, `privateerr.env`, application databases, or raw private logs.

## Check an already-running test stack

```sh
make test-vpn PRESET=YOUR-PRESET
```

This inspects actual Privateerr/Gluetun containers, generated files, tunnel health, and PIA forwarding. When qBittorrent validation is enabled it also checks that its listening port matches the forwarded port. Syntax validation alone proves none of these runtime properties.

## Start and test VPN/download services

```sh
make test-e2e PRESET=YOUR-PRESET
```

This restores fixtures, starts the VPN pair and selected download clients, waits for health, validates the forwarding chain, brings the stack down, and restores fixtures again. Generate the intended downloader selection first; for example, Usenet-only uses `REMOVE_SERVICES=qbittorrent,cleanuparr ADD_SERVICES=sabnzbd`. Use `nzbget` instead for NZBGet, or add either without removal to test combined modes.

## Start and test the full stack

```sh
make test-stack PRESET=YOUR-PRESET
```

This restores fixtures, starts all services, waits for configured healthchecks, and validates VPN/forwarding state. It leaves the stack running on success, prints status/recent logs on failure, and restores fixtures after validation. It is a mutating development test, not a routine health check.

## Validate lifecycle cleanup ownership

After lifecycle-helper changes, use the explicitly isolated acceptance test:

```sh
test/runtime/test-compose-cleanup-live.sh
```

It creates uniquely named projects and unrelated sentinels, proves `down` retains images/volumes, then checks scoped `nuke` cleanup and restarts to verify retained data. It uses no `dist/`, repository `.env`, or PIA credentials. Test teardown deletes only volumes recorded as created by that run, with matching project/run labels; rejected ownership or cleanup failure retains the ledger and fails the test. Never use global pruning.

## Restore example files 📜

The following commands stop or reset only the explicitly selected disposable test deployment:

> [!CAUTION]
> `make clean-test` stops the selected stack and replaces its VPN files with examples. `make restore-test-config` replaces those files even while services run, potentially breaking VPN operation. Confirm the preset and isolation before running either.

```sh
make clean-test PRESET=YOUR-PRESET
make restore-test-config PRESET=YOUR-PRESET
```

`clean-test` uses volume-preserving `down`. `make clean` removes disposable repository artifacts only. `make nuke` also stops services and removes scoped containers, networks, eligible images, the separate Maraudarr project, and repository-owned build cache; it preserves application volumes, deployment `.env`, persistent config, and backups. `make delete-config` is a separate destructive host-config deletion and is not part of routine cleanup. Keep exported backups off-host; named-volume application backups need their own export procedure.
