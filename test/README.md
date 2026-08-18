# Plundarr Test Hold 🧪🏴‍☠️

Welcome to the test hold, where Plundarr checks that Privateerr and Gluetun left the PIA WireGuard and port-forwarding voyage in a usable state.

## What Gets Tested 🦜

The VPN test script does not use a throwaway test image. It validates the actual Privateerr, Gluetun, and qBittorrent Compose containers:

- Privateerr generated PIA WireGuard `wg0.conf`.
- Privateerr generated PIA port-forwarding metadata in `privateerr.env`.
- Privateerr and Gluetun containers are running and healthy.
- Gluetun is reachable through its unauthenticated health endpoint from inside the Gluetun container.
- PIA port-forwarding produced a usable forwarded port when required.
- qBittorrent listens on Gluetun's forwarded port when qBittorrent validation is enabled.

## Test Voyages 🧭

### Maraudarr Generator Checks

Use the complete Maraudarr test target while changing image resolution,
presets, service charts, or generated config seeds:

```bash
make test-maraudarr
```

These checks simulate local-image discovery, a successful GHCR pull, a local
fallback build, and a complete retrieval failure without contacting a registry.
They also run the Python unit suite and generate representative Compose charts.

### Running Stack Check

Use this when the full Plundarr stack is already running:

```bash
make test-vpn
```

This checks the existing Privateerr and Gluetun containers, then verifies generated files and port forwarding.

### Privateerr + Gluetun + Download E2E

Use this when ye want `Make` to launch only the VPN pair plus download clients, validate it, then clean up:

```bash
make test-e2e
```

This target:

1. Restores example config.
2. Starts only `privateerr`, `gluetun`, and selected download services with Docker Compose.
3. Waits for those services to report healthy.
4. Runs `test/plundarr-vpn-test.sh`.
5. Brings the Compose stack down.
6. Restores example config again.

Generate the desired download mates first; the E2E target discovers them from
the rendered Compose chart:

```bash
make ship REMOVE_SERVICES=qbittorrent,cleanuparr ADD_SERVICES=sabnzbd
make test-e2e
```

Chart the same E2E voyage with NZBGet instead:

```bash
make ship REMOVE_SERVICES=qbittorrent,cleanuparr ADD_SERVICES=nzbget
make test-e2e
```

### Full Stack Test

Use this when ye want Make to launch every service, wait for health, and validate the full port-forwarding chain:

```bash
make test-stack
```

This target:

1. Restores example config.
2. Starts every Compose service.
3. Waits for healthcheck-enabled containers to report healthy.
4. Verifies Privateerr output, Gluetun health, Gluetun forwarded port, and qBittorrent port sync.
5. Leaves the stack running on success.
6. Prints Compose status and recent logs on failure.
7. Restores example config after validation.

> [!WARNING]
> 🧨 VPN tests can involve real PIA credentials in `.env`. 🧨
>
> Do not commit live credentials, generated WireGuard VPN configs, forwarded ports, or logs from yer secret treasure chest. 🪎

## Example Files 📜

The [examples](examples/) directory stores example files used to reset the repo after a live run:

- [examples/example-wg0.conf](examples/example-wg0.conf)
- [examples/example-privateerr.env](examples/example-privateerr.env)

These files match the Privateerr examples exactly. Cleanup targets copy them back into `config/gluetun/wireguard/` so live secrets do not accidentally sneak into Git.

Useful cleanup commands:

```bash
make test-down
make reset-config
make nuke
```

> [!TIP]
> 🏴‍☠️ Run cleanup before committing after any real VPN voyage. _Future ye will thank past ye!_
