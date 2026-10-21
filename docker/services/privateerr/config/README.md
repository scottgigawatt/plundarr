# Privateerr configuration 🕵️

Privateerr keeps its logs and service state in this directory. It writes the files Gluetun consumes to `../gluetun/wireguard/`:

- `wg0.conf` contains the generated PIA WireGuard configuration.
- `privateerr.env` contains the selected PIA server and port-forwarding metadata.

From the repository root, replace `YOUR-PRESET` with the generated preset ID, such as `boudoirr`. Set `PIA_USER` and `PIA_PASS` in `dist/YOUR-PRESET/.env`, run `make up PRESET=YOUR-PRESET`, and wait for both files to appear before diagnosing Gluetun startup.

> [!WARNING]
> Generated WireGuard configuration and port-forwarding metadata can expose live VPN details. Keep the whole generated config tree out of source control and redact it from support logs.
