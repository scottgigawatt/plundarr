# 🏴‍☠️ Privateerr Configuration ☠️

Greetings, swashbucklers! This be the config directory for **Privateerr**, the service that generates Private Internet Access WireGuard config and port-forwarding metadata for Gluetun in Plundarr.

## Purpose 🦜⚓️

> [!NOTE]
> 🏴‍☠️ Plundarr pulls the published Privateerr image from GHCR. The PIA manual connection scripts live upstream in Privateerr, not in this repo.

Privateerr generates [`../gluetun/wireguard/wg0.conf`](../gluetun/wireguard/wg0.conf) and [`../gluetun/wireguard/privateerr.env`](../gluetun/wireguard/privateerr.env). Gluetun consumes both files when the stack starts so PIA WireGuard and port forwarding can sail together.

> [!IMPORTANT]
> ⚓️ The generated `wg0.conf` and `privateerr.env` can contain live VPN and port-forwarding details. Guard them like yer finest loot.

## Instructions 🗺️

> [!WARNING]
> ☠️ Mess up the steps below an’ ye might find yerself driftin’ without VPN cover.

To use this directory in a default Plundarr voyage:

1. Run `make ship PRESET=plundarr`.
2. Set yer PIA values in `dist/plundarr/.env`.
3. Run `make up PRESET=plundarr`.
4. Wait for Privateerr to update [`../gluetun/wireguard/wg0.conf`](../gluetun/wireguard/wg0.conf) and [`../gluetun/wireguard/privateerr.env`](../gluetun/wireguard/privateerr.env).

The files in this directory are for Privateerr logs and service state. The WireGuard treasure map and port-forwarding metadata land under `config/gluetun/wireguard`.

> [!CAUTION]
> 🏴‍☠️⚠️ Forgettin’ to check the generated config file could leave yer ship exposed to unwanted eyes!

Smooth sailin' and safe voyages, me hearties! 🌊🏴‍☠️
