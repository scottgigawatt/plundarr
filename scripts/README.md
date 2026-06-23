# Plundarr Script Hold 🏴‍☠️

This directory keeps host-side helper scripts for Plundarr.

## Structure 🧭

- [`synology/`](synology/) contains scripts intended to run directly on Synology NAS through Task Scheduler or an interactive admin shell.

> [!IMPORTANT]
> The scripts under `scripts/synology/` are written for direct Synology NAS use. Review paths before running them on a different Linux host.

## Synology Scripts ⚓

### `synology/tun.sh`

Ensures `/dev/net/tun` exists for Gluetun and other VPN containers.

Run at boot with Synology Task Scheduler:

```sh
sh /volume1/docker/plundarr/scripts/synology/tun.sh
```

### `synology/entware.sh`

Mounts and starts Entware at boot, adds the Entware profile to `/etc/profile`, and updates the package list.

Run at boot with Synology Task Scheduler:

```sh
sh /volume1/docker/plundarr/scripts/synology/entware.sh
```

### `synology/compose-restart.sh`

Waits for Docker, stops a Compose project, removes volumes, and starts the stack again in detached mode.

Run manually or at boot:

```sh
sh /volume1/docker/plundarr/scripts/synology/compose-restart.sh /volume1/docker/plundarr
```

### `synology/set-inotify-limits.sh`

Raises Linux inotify limits so Plex can monitor large media libraries without running out of watches.

Run at boot with Synology Task Scheduler:

```sh
sh /volume1/docker/plundarr/scripts/synology/set-inotify-limits.sh
```
