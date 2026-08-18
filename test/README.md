# Testing Plundarr 🧪🏴‍☠️

Generator checks are safe and credential-free. Runtime VPN checks can start
real containers and use the PIA credentials in `.env`.

## Generator Checks

Run this after changing presets, service charts, config seeds, or Maraudarr:

```bash
make test-maraudarr
```

It runs the Python unit suite, image-resolution tests, representative stack
generation, and real `docker compose config` validation without starting the
generated application containers.

## Runtime Checks

| Command           | What It Tests                                          |
| ----------------- | ------------------------------------------------------ |
| `make test-vpn`   | Privateerr output, Gluetun health, and port forwarding |
| `make test-e2e`   | VPN services plus rendered download clients            |
| `make test-stack` | Every service in the generated stack                   |
| `make test-down`  | Stops test containers and restores example VPN files   |

`make test-e2e` discovers qBittorrent, SABnzbd, and NZBGet from the generated
Compose file. Generate the desired downloader first:

```bash
make ship REMOVE_SERVICES=qbittorrent,cleanuparr ADD_SERVICES=sabnzbd
make test-e2e
```

Successful `test-stack` runs leave the stack running. Failed runs print Compose
status and recent logs before restoring the example VPN files.

> [!WARNING]
> Never commit `.env`, live PIA credentials, generated `wg0.conf`,
> `privateerr.env`, forwarded ports, application databases, or runtime logs.

## Example and Cleanup Files

Safe reset fixtures live under [`examples/`](examples/):

- [`example-wg0.conf`](examples/example-wg0.conf)
- [`example-privateerr.env`](examples/example-privateerr.env)

Useful cleanup commands:

```bash
make test-down
make reset-config
make nuke
```

> [!CAUTION]
> `make nuke` removes generated files, containers, volumes, and images. Review
> the target before using it on a deployment with data you need to keep.
