# Plundarr script hold 🏴‍☠️

These documented AWK programs and host helpers support generated Compose projects, Linux hosts, and Synology DiskStations. Pick the smallest tool for the job and review its header before running it with elevated privileges.

Run Make examples from the repository root and replace `YOUR-PRESET` with the selected catalog preset ID, such as `boudoirr`.

## Find a script 🧭

| Hold       | Script                                                                                                                                         | Purpose                                                            |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| 🧮 AWK     | [`awk/collect-dockerfile-base-images.awk`](https://github.com/scottgigawatt/plundarr/blob/main/scripts/awk/collect-dockerfile-base-images.awk) | Resolve declared external Dockerfile base-image references         |
| 🧮 AWK     | [`awk/format-compose-status.awk`](https://github.com/scottgigawatt/plundarr/blob/main/scripts/awk/format-compose-status.awk)                   | Align Compose status rows and stack distinct published ports       |
| 🧮 AWK     | [`awk/order-environment.awk`](https://github.com/scottgigawatt/plundarr/blob/main/scripts/awk/order-environment.awk)                           | Order resolved values like the selected preset environment file    |
| 🧮 AWK     | [`awk/strip-comments.awk`](https://github.com/scottgigawatt/plundarr/blob/main/scripts/awk/strip-comments.awk)                                 | Remove comments and blank lines from raw configuration output      |
| 🐳 Compose | [`compose/backup.sh`](https://github.com/scottgigawatt/plundarr/blob/main/scripts/compose/backup.sh)                                           | Archive one preset's config without replacing an existing backup   |
| 🐳 Compose | [`compose/check-pia-credentials.sh`](https://github.com/scottgigawatt/plundarr/blob/main/scripts/compose/check-pia-credentials.sh)             | Report missing or example PIA credentials before Privateerr starts |
| 🐳 Compose | [`compose/nuke.sh`](https://github.com/scottgigawatt/plundarr/blob/main/scripts/compose/nuke.sh)                                               | Remove resources owned by one selected Compose project             |
| 🐳 Compose | [`compose/preset_examples.py`](https://github.com/scottgigawatt/plundarr/blob/main/scripts/compose/preset_examples.py) | Generate or check public preset references with a local Maraudarr image |
| 🐳 Compose | [`compose/ps.sh`](https://github.com/scottgigawatt/plundarr/blob/main/scripts/compose/ps.sh)                                                   | Print a compact status table for one generated project             |
| 🐳 Compose | [`compose/restart.sh`](https://github.com/scottgigawatt/plundarr/blob/main/scripts/compose/restart.sh)                                         | Wait for Docker, stop a project safely, and start it again         |
| 📚 Docs    | [`docs/prepare-python.sh`](https://github.com/scottgigawatt/plundarr/blob/main/scripts/docs/prepare-python.sh)                                 | Prepare the exact Python environment used to build documentation   |
| 🐧 Linux   | [`linux/set-inotify-limits.sh`](https://github.com/scottgigawatt/plundarr/blob/main/scripts/linux/set-inotify-limits.sh)                       | Raise inotify limits for large Plex libraries                      |
| ⚓ Synology | [`synology/docker-socket.sh`](https://github.com/scottgigawatt/plundarr/blob/main/scripts/synology/docker-socket.sh)                           | Restore trusted `docker` group access to the Docker socket         |
| ⚓ Synology | [`synology/entware.sh`](https://github.com/scottgigawatt/plundarr/blob/main/scripts/synology/entware.sh)                                       | Mount Entware, start its services, and upgrade its packages        |
| ⚓ Synology | [`synology/tun.sh`](https://github.com/scottgigawatt/plundarr/blob/main/scripts/synology/tun.sh)                                               | Ensure `/dev/net/tun` exists for VPN containers                    |

> [!IMPORTANT]
> Scripts under `scripts/synology/` run directly on a Synology NAS. They are maintained against DSM 7.4; review paths and privileges before using them on another DSM release or Linux host.

## Create a Synology boot task

Host-script commands below use `/volume1/docker/plundarr` as an example location for a Plundarr repository checkout on your NAS, with generated projects under `dist/<preset>/`. Replace the checkout prefix and generated-project path with your actual locations. Generating a deployment with the published Maraudarr image does not copy these host scripts into the generated project. Keep the checkout and any required shared folders available when the NAS boots.

Use this shared procedure for the five boot-task examples below on DSM 7.4. Create only the tasks your host needs; Entware is optional. Sign in to DSM as an administrator, review the selected script's requirements and effects, and use the **User** account specified in its description. Root tasks can change the NAS itself; keep the scripts and their parent directories writable only by trusted administrators.

1. Open **Control Panel → Task Scheduler**. Select **Create → Triggered Task → User-defined script**.
2. On **General**, enter a descriptive task name, select the required **User**, set **Event** to **Boot-up**, and keep **Enabled** selected.
3. On **Task Settings**, find **Run command → User-defined script** and paste the command from the selected script's section below. Replace the example checkout path before saving.
4. Select **OK** to save the task.
5. On the Task Scheduler main page, open **Settings**, select **Save output results**, and choose a shared folder for the results.
6. When the script's documented effects are acceptable, select its task and choose **Run** to check it before the next reboot. A stack restart interrupts its applications; the Entware task also upgrades installed packages.
7. Open **Action → View Result** and check the output against the expected result below. Correct any error before relying on the next boot. To stop future boot runs, clear the task's **Enabled** checkbox and select **Apply**.

If a stack restart depends on another helper, trigger the first preparation task at **Boot-up**, then select the preparation task(s) as the restart task's pre-tasks under **General**. Use DSM's task dependencies to order multiple prerequisites; independent Boot-up tasks and task names alone do not establish that order. Complete required TUN setup and inotify changes before restarting services; complete socket permissions first when the restart runs as a Docker-group user. A pre-task orders completion, so still inspect its output for errors. Compose's service dependencies order containers after `restart.sh` starts the project; they do not run these host-preparation tasks.

See Synology's [Task Scheduler instructions](https://kb.synology.com/en-uk/DSM/help/DSM/AdminCenter/system_taskscheduler) for task dependencies, output, and controls, and its [script-writing tips](https://kb.synology.com/en-af/DSM/tutorial/common_mistake_in_task_scheduler_script) for execution-account and path requirements.

## AWK programs 🧮

Make invokes these helpers automatically. Review each script header for its interface. Resolved environment/configuration commands can print credentials; inspect them privately and share only sanitized excerpts. Base-image collection supports best-effort cleanup of unused owned resources without force-removing shared or in-use images.

## Compose helpers 🐳

### `compose/backup.sh`

Archives one generated preset's complete config directory with a timestamped name. An incrementing suffix prevents a same-second backup from replacing an existing archive. Before a file-copy archive, stop affected applications cleanly and prepare application-consistent exports; the helper does not pause writers or snapshot databases. Then use `make backup PRESET=YOUR-PRESET`. This archives host config files only, excluding the deployment `.env`, external configuration trees, and named-volume databases. Keep [Tracearr exports](https://scottgigawatt.github.io/plundarr/project-guides/monitoring/#back-up-and-update), external state, and matching encryption keys in the recovery set and verify an off-host copy.

### `compose/check-pia-credentials.sh`

Reads resolved Compose environment values from standard input and fails when a Privateerr deployment would start without real `PIA_USER` and `PIA_PASS` values. Invalid credentials produce a color-aware diagnostic with a corrective action; redirected output remains plain text and `NO_COLOR` disables terminal color. `make up`, `make test-e2e`, and `make test-stack` call it automatically.

### `compose/nuke.sh`

Validates one selected Compose model before deleting anything, captures its service images, runs project-scoped teardown of containers, networks, and service images while preserving application volumes, then removes explicitly supplied local image references and one named Buildx builder. Plundarr calls the same helper separately for the generated project and the explicitly named `maraudarr` Compose project that runs Maraudarr.

Repeated `--dockerfile` and `--additional-image` arguments avoid shell command evaluation. Missing resources are harmless; unexpected Compose, Docker, or builder failures stop the helper. Repository files, `.env`, bind-mounted config, and host backups remain Make's protected responsibility. All application volumes and internal backups are preserved. The explicitly supplied Buildx builder owns disposable build cache only. Make fixes deployment teardown flags; customize its timeout with `COMPOSE_DOWN_TIMEOUT`.

### `compose/ps.sh`

Resolves the selected Compose project and prints only its containers in a terminal-friendly status table. Equivalent IPv4 and IPv6 wildcard bindings are collapsed, and each distinct published port receives an aligned continuation line. `make ps PRESET=YOUR-PRESET` is the normal entry point.

### `compose/restart.sh`

Waits up to 60 seconds for Docker, then runs Compose `down --remove-orphans` followed by `up -d` in the supplied project directory. This interrupts the selected stack and removes its orphaned containers while preserving volumes and application state. The generated Compose dependencies control startup order, including waiting for Privateerr and Gluetun health where declared.

Use the [shared boot-task setup](#create-a-synology-boot-task). Select `root` when combining this restart with root-only preparation tasks; otherwise, a trusted user with Docker socket access and read access to the project can run it. Prepare any required host settings first. The script detects `docker compose` or `docker-compose`. Compose still applies the project's image pull policy: generated charts use `pull_policy: always`, so a boot task can download updated images and recreate containers. Review image-update requirements and backups before enabling scheduled startup.

```sh
sh /volume1/docker/plundarr/scripts/compose/restart.sh /volume1/docker/plundarr/dist/plundarr
```

The second path is the generated Compose project containing `docker-compose.yml` and `.env`; change `dist/plundarr` for another preset. Confirm the output ends with `'plundarr' stack restarted successfully.`, then check container health in Container Manager. If Docker is unavailable for 60 seconds, the script exits with an error instead of restarting the stack.

## Documentation helpers 📚

### `docs/prepare-python.sh`

Validates the exact supported Python patch release, safely replaces an absent or incompatible documentation virtual environment, and writes the versioned stamp consumed by Make. `make docs` is the normal entry point and passes every path through explicit long options.

## Linux helpers 🐧

### `linux/set-inotify-limits.sh`

Raises Linux inotify limits so Plex can monitor large media libraries without running out of watches. It applies and verifies the kernel values immediately, and writes `/etc/sysctl.d/99-plundarr-inotify.conf` when `/etc/sysctl.d` exists. Review its defaults for your host before enabling a boot task.

Use the [shared boot-task setup](#create-a-synology-boot-task) with **User** set to `root`. Complete this task before a dependent Plex restart.

```sh
sh /volume1/docker/plundarr/scripts/linux/set-inotify-limits.sh
```

Check **View Result** for the final watch, instance, and queue limits. A failed value check stops the script with an error.

## Synology helpers ⚓

### `synology/tun.sh`

Creates `/dev/net/tun` when missing and attempts to load `/lib/modules/tun.ko` when the TUN module is not loaded. Gluetun needs the device before starting its VPN tunnel.

Use the [shared boot-task setup](#create-a-synology-boot-task) with **User** set to `root`, because creating a device node and loading a kernel module require host privileges. Complete this task before a dependent VPN-stack restart.

```sh
sh /volume1/docker/plundarr/scripts/synology/tun.sh
```

Check **View Result** for the device and module results, including any `Failed to load tun module.` message. The final `Script execution completed.` line alone does not establish success.

### `synology/entware.sh`

Requires an existing Entware installation at `/volume1/@Entware/opt`. It bind-mounts that directory at `/opt`, starts Entware services through `rc.unslung`, and adds the Entware profile to `/etc/profile` when absent. It also runs `opkg update` and `opkg upgrade`, so every task run can upgrade installed Entware packages; review and back up any affected application settings first.

Use the [shared boot-task setup](#create-a-synology-boot-task) with **User** set to `root` for the mount and system-profile changes. Configure this as a pre-task only for tasks that actually require Entware.

```sh
sh /volume1/docker/plundarr/scripts/synology/entware.sh
```

Check **View Result** for mount, service-start, and package errors; a successful final package command does not prove that the earlier mount succeeded.

### `synology/docker-socket.sh`

Waits for Container Manager to create `/var/run/docker.sock`, then grants the `docker` group read/write access. Membership in this group grants root-level control of the NAS through Docker.

Create a `docker` group in **Control Panel → User & Group → Group** and add only trusted Docker users. Use the [shared boot-task setup](#create-a-synology-boot-task) with **User** set to `root`. The script waits up to 120 seconds for the socket, then sets its owner/group to `root:docker` and permissions to `0660`.

```sh
sh /volume1/docker/plundarr/scripts/synology/docker-socket.sh
```

Confirm **View Result** contains `Docker socket permissions configured successfully.`. A missing group or socket timeout produces an error. Complete this task before starting a task that accesses Docker as a member of that group.
