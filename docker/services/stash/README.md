# Stash service chart

This chart gives Stash read-only access to the same `/data` media root used by Jellyfin. Boudoirr selects it by default; remove it with `REMOVE_SERVICES=stash`, deselect it in the picker, or select it elsewhere with `ADD_SERVICES=stash`. It has no required companion services or startup dependencies.

## Container and storage contract

The official `stashapp/stash` image uses `STASH_TAG`, defaulting to the stable `latest` channel. Stash runs as `DEFAULT_PUID:DEFAULT_PGID`, with `DEFAULT_GROUP`, dropped capabilities, and `no-new-privileges`. `STASH_CONFIG_FILE=/config/config.yml` avoids the upstream image's root-owned configuration path. `USER=stash` supplies the name required by Go user lookup when the configured numeric UID has no image account; it does not change the Compose process identity. Bind sources must be accessible to that identity; startup does not repair host ownership.

`STASH_WEBUI_PORT` defaults to `9999` before preset offsets: Boudoirr publishes `19999`, standalone Jellyfin with Stash publishes `29999`, and Custom publishes `39999`. Internal clients use `http://stash:9999`; the `/healthz` heartbeat verifies the listener without credentials, not completed setup or library health.

| Host setting | Container path | Access and purpose |
| --- | --- | --- |
| `STASH_DATA_PATH` | `/data` | Read-only media; defaults to the preset media root |
| `STASH_CONFIG_PATH` | `/config` | Writable configuration, SQLite database, plugins, and scrapers |
| `STASH_METADATA_PATH` | `/metadata` | Writable metadata exports and application backups |
| `STASH_CACHE_PATH` | `/cache` | Writable processing and streaming cache |
| `STASH_BLOBS_PATH` | `/blobs` | Writable image storage when filesystem blob storage is selected |
| `STASH_GENERATED_PATH` | `/generated` | Writable previews, sprites, and transcodes |

The five writable defaults live beneath `./config/stash/` in the generated project. Maraudarr seeds their directories and README, preserving existing files during regeneration and deselection. External path overrides remain operator-managed. Original media is not copied. No host networking, hardware devices, Docker socket, or VPN dependency is required.

Complete account creation and choose video-only library roots in Stash before scanning. Keep Whisparr responsible for media names and NFO files. The chart does not register application connections, install plugins, or configure StashDB credentials. Follow the [Stash setup and recovery guide](https://github.com/scottgigawatt/plundarr/blob/main/docs/project-guides/stash.md) for the supported reader journey and integration limits.
