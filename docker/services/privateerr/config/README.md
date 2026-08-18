# ☠️ Privateerr Configuration

Privateerr uses the PIA credentials in the root `.env` file to generate Gluetun's
WireGuard configuration and port-forwarding metadata. Its own logs and state are
stored here; generated VPN files are stored under `config/gluetun/wireguard`.

> [!IMPORTANT]
> The root `.env` and generated WireGuard files contain sensitive VPN details.
> Keep them private and include them in secure backups.
