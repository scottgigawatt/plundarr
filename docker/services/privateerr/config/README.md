# Privateerr configuration 🕵️

Privateerr keeps its logs and service state in this directory. It writes the files Gluetun consumes to `../gluetun/wireguard/`:

- `wg0.conf` contains the generated PIA WireGuard configuration.
- `privateerr.env` contains the selected PIA server and port-forwarding metadata.

For a generated deployment, set `PIA_USER` and `PIA_PASS` in `dist/<preset>/.env`, run `make up PRESET=<preset>`, and wait for both files to appear before diagnosing Gluetun startup.

> [!WARNING]
> Generated WireGuard configuration and port-forwarding metadata can expose live VPN details. Keep the whole generated config tree out of source control and redact it from support logs.
