# Plundarr Script Hold 🏴‍☠️

These documented AWK programs and host helpers support generated Compose
projects, Linux hosts, and Synology DiskStations. Pick the smallest tool for
the job and review its header before running it with elevated privileges.

## Script Chart 🧭

| Hold       | Script                                                                 | Purpose                                                            |
| ---------- | ---------------------------------------------------------------------- | ------------------------------------------------------------------ |
| 🧮 AWK     | [`awk/order-environment.awk`](https://github.com/scottgigawatt/plundarr/blob/main/scripts/awk/order-environment.awk)                 | Order resolved values like the selected preset environment file    |
| 🧮 AWK     | [`awk/strip-comments.awk`](https://github.com/scottgigawatt/plundarr/blob/main/scripts/awk/strip-comments.awk)                       | Remove comments and blank lines from raw configuration output      |
| 🐳 Compose | [`compose/backup.sh`](https://github.com/scottgigawatt/plundarr/blob/main/scripts/compose/backup.sh)                                 | Archive one preset's config without replacing an existing backup   |
| 🐳 Compose | [`compose/check-pia-credentials.sh`](https://github.com/scottgigawatt/plundarr/blob/main/scripts/compose/check-pia-credentials.sh) | Report missing or example PIA credentials before Privateerr starts |
| 🐳 Compose | [`compose/ps.sh`](https://github.com/scottgigawatt/plundarr/blob/main/scripts/compose/ps.sh)                                       | Print a compact status table for one generated project             |
| 🐳 Compose | [`compose/restart.sh`](https://github.com/scottgigawatt/plundarr/blob/main/scripts/compose/restart.sh)                             | Wait for Docker, stop a project safely, and start it again         |
| 🐧 Linux   | [`linux/set-inotify-limits.sh`](https://github.com/scottgigawatt/plundarr/blob/main/scripts/linux/set-inotify-limits.sh)           | Raise inotify limits for large Plex libraries                      |
| ⚓ Synology | [`synology/docker-socket.sh`](https://github.com/scottgigawatt/plundarr/blob/main/scripts/synology/docker-socket.sh)               | Restore trusted `docker` group access to the Docker socket         |
| ⚓ Synology | [`synology/entware.sh`](https://github.com/scottgigawatt/plundarr/blob/main/scripts/synology/entware.sh)                           | Mount and start Entware during boot                                |
| ⚓ Synology | [`synology/tun.sh`](https://github.com/scottgigawatt/plundarr/blob/main/scripts/synology/tun.sh)                                   | Ensure `/dev/net/tun` exists for VPN containers                    |

> [!IMPORTANT]
> Scripts under `scripts/synology/` run directly on a Synology NAS. They are
> maintained against DSM 7.4.1-90080; review paths and privileges before using
> them on another DSM release or Linux host.

## AWK Programs 🧮

### `awk/order-environment.awk`

Records resolved Docker Compose environment assignments, then prints only
variables present in the selected preset `.env` file and preserves that file's
order. `make env PRESET=<preset>` supplies both inputs through the centralized
AWK command and option variables in the Makefile.

### `awk/strip-comments.awk`

Removes comments, trailing whitespace, and empty lines from configuration
output. `make print-config` and `make print-env` share this program so both raw
views follow one filtering contract.

## Compose Helpers 🐳

### `compose/backup.sh`

Archives one generated preset's complete config directory with a timestamped
name. An incrementing suffix prevents a same-second backup from replacing an
existing archive. `make backup PRESET=<preset>` is the normal entry point.

### `compose/check-pia-credentials.sh`

Reads resolved Compose environment values from standard input and fails when a
Privateerr deployment would start without real `PIA_USER` and `PIA_PASS`
values. Invalid credentials produce a color-aware diagnostic with a corrective
action; redirected output remains plain text and `NO_COLOR` disables terminal
color. `make up`, `make test-e2e`, and `make test-stack` call it automatically.

### `compose/ps.sh`

Resolves the selected Compose project and prints only its containers in a
terminal-friendly status table. Equivalent IPv4 and IPv6 wildcard bindings are
collapsed, and each distinct published port receives an aligned continuation
line. `make ps PRESET=<preset>` is the normal entry point.

### `compose/restart.sh`

Waits for Docker, stops a Compose project while preserving named volumes, and
starts the project again in detached mode.

> [!TIP]
>
> ```sh
> sh /volume1/docker/plundarr/scripts/compose/restart.sh /volume1/docker/plundarr/dist/plundarr
> ```

## Linux Helpers 🐧

### `linux/set-inotify-limits.sh`

Raises Linux inotify limits so Plex can monitor large media libraries without
running out of watches.

> [!TIP]
>
> ```sh
> sh /volume1/docker/plundarr/scripts/linux/set-inotify-limits.sh
> ```

## Synology Helpers ⚓

### `synology/tun.sh`

Ensures `/dev/net/tun` exists for Gluetun and other VPN containers.

> [!TIP]
>
> ```sh
> sh /volume1/docker/plundarr/scripts/synology/tun.sh
> ```

### `synology/entware.sh`

Mounts and starts Entware at boot, adds its profile to `/etc/profile`, and
updates the package list.

> [!TIP]
>
> ```sh
> sh /volume1/docker/plundarr/scripts/synology/entware.sh
> ```

### `synology/docker-socket.sh`

Waits for Container Manager to create `/var/run/docker.sock`, then grants the
`docker` group read/write access. Membership in this group grants root-level
control of the NAS through Docker.

Create a `docker` group in **DSM → Control Panel → User & Group → Group**, add
only trusted Docker users, and run the boot task as `root`:

> [!TIP]
>
> ```sh
> sh /volume1/docker/plundarr/scripts/synology/docker-socket.sh
> ```
