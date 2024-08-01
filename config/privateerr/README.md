# 🏴‍☠️ Privateerr Configuration ☠️

Greetings, swashbucklers! This be the config directory for **Privateerr**, yer trusty Docker Compose setup for Private Internet Access VPN connections with WireGuard.

## Purpose 🦜⚓️

Privateerr be a Docker Compose configuration fer buildin' Private Internet Access manual connection scripts into a Docker image with the required WireGuard tools. It also generates a configuration file for native WireGuard connections. Hoist the sails and set yer course for secure VPN connections, crew!

This repo includes the [PIA manual-connections](https://github.com/pia-foss/manual-connections) repository as a submodule at `config/privateerr/docker/pia`, so it be included in the image build.

Ye can use the output WireGuard configuration file to configure a VPN client like Gluetun for secure connections.

## Instructions 🗺️

To use this directory:

1. Run Privateerr and start the container.
2. Wait for the setup to complete and the [`config/gluetun/wireguard/wg0.conf`](../gluetun/wireguard/wg0.conf) file to be updated with the new configuration.
3. Find yer treasure map in this directory.

Ye can then use this file to configure a VPN client like Gluetun for secure connections.

Smooth sailin' and safe voyages, me hearties! 🌊🏴‍☠️
