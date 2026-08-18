# Plundarr Script Hold 🏴‍☠️

This directory keeps host-side helper scripts for Plundarr.

## Structure 🧭

- [`compose-restart.sh`](compose-restart.sh) is a generic Docker Compose helper.
- [`linux/`](linux/) contains Linux host maintenance scripts that are not Synology-specific.
- [`synology/`](synology/) contains scripts intended to run directly on Synology NAS through Task Scheduler or an interactive admin shell.

> [!IMPORTANT]
> The scripts under `scripts/synology/` are written for direct Synology NAS use. Review paths before running them on a different Linux host.

## Generic Scripts ⚙️

### `compose-restart.sh`

Waits for Docker, stops a Compose project while preserving named volumes, and
starts the stack again in detached mode.

Run manually or at boot:

```sh
sh /volume1/docker/plundarr/scripts/compose-restart.sh /volume1/docker/plundarr
```

## Linux Scripts 🐧

### `linux/set-inotify-limits.sh`

Raises Linux inotify limits so Plex can monitor large media libraries without running out of watches.

Run as root at boot or manually:

```sh
sh /volume1/docker/plundarr/scripts/linux/set-inotify-limits.sh
```

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

### `synology/docker-socket.sh`

Waits for Container Manager to create `/var/run/docker.sock`, then grants the `docker` group read/write access so trusted group members can run Docker commands without `sudo`.

Before using the script, create a `docker` group in **DSM → Control Panel → User & Group → Group** and add each trusted Docker user to it. Membership in this group grants root-level control of the NAS through Docker.

Create a boot-up task in Synology Task Scheduler, select `root` as the task user, and use this command:

```sh
sh /volume1/docker/plundarr/scripts/synology/docker-socket.sh
```
