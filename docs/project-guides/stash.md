# Add Stash to a shared media library

Use Stash to identify, catalog, and play shared adult media.

## Before you start

Use Docker Compose or DSM 7.4 with Synology Container Manager, following the [main setup guide](../setup.md). Have the media available on the deployment host, sufficient space for previews and cache, and a host user/group with the required media and application-state permissions. Back up existing application settings before changing integrations. StashDB identification needs an account and API key; Stash can scan and play files before that connection is configured.

The chart uses the official stable `stashapp/stash:latest` image. Confirm architecture support for the selected tag before deploying. No GPU access is configured. Preview generation and simultaneous transcoding can compete with Jellyfin for CPU, memory, and disk access; start with a small library and schedule bulk processing during idle time.

## Select or omit Stash

Boudoirr includes Stash, Jellyfin, and Cruisarr as independently removable defaults. The interactive `make configure` picker starts all three checked. For non-interactive generation:

```sh
make ship PRESET=boudoirr
```

To omit Stash while retaining Jellyfin and Cruisarr:

```sh
make ship PRESET=boudoirr REMOVE_SERVICES=stash
```

To use Stash with an existing Jellyfin server, omit the local Jellyfin service:

```sh
make ship PRESET=boudoirr REMOVE_SERVICES=jellyfin
```

Other presets can add Stash with `ADD_SERVICES=stash`. Repeat the complete intended service selection whenever you regenerate. Omitting a service preserves its settings and files but does not stop a container already running from the previous chart. Stop that service before regenerating if you are retiring it.

## Review storage and ports

Edit `dist/boudoirr/.env` before launch. Keep `STASH_DATA_PATH` and `JELLYFIN_DATA_PATH` pointed at the same host media root when using local Jellyfin. Both expose it as `/data`. Review the read-only and writable mounts below before enabling file changes in Stash. Existing path overrides are preserved rather than synchronized automatically.

| Setting | Boudoirr default | Review |
| --- | --- | --- |
| `STASH_WEBUI_PORT` | `19999` | Change for a host-port conflict; container port remains `9999` |
| `STASH_DATA_PATH` | `/volume1/jellyfin` | Shared media root; read-only |
| `STASH_CREATORS_PATH` | `/volume1/jellyfin/scenes/creators` | Writable mount at `/data/scenes/creators`; use the matching child of the shared root |
| `STASH_CONFIG_PATH` | `./config/stash/config` | Configuration, database, plugins, and scrapers |
| `STASH_METADATA_PATH` | `./config/stash/metadata` | Metadata exports and application backups |
| `STASH_CACHE_PATH` | `./config/stash/cache` | Processing and streaming cache |
| `STASH_BLOBS_PATH` | `./config/stash/blobs` | Images when filesystem blob storage is selected |
| `STASH_GENERATED_PATH` | `./config/stash/generated` | Previews, sprites, and transcodes |

Stash runs as the configured `DEFAULT_PUID:DEFAULT_PGID`, with `DEFAULT_GROUP`. Prepare host bind sources and grant that identity the access listed above. `STASH_CREATORS_PATH` must refer to the same physical directory as `STASH_DATA_PATH/scenes/creators`, so both applications see the same files. This bind source must exist before launch. The container does not repair ownership. If a bind source is outside the generated config tree, create it yourself and include durable external state in backups. Do not share Stash's database or config directory with Jellyfin or Whisparr.

## Start and identify media

1. Launch the generated project using the [main launch procedure](../setup.md#launch-with-docker-compose). Open your deployment host on port `19999`, adjusted for `STASH_WEBUI_PORT`, and complete Stash's setup wizard. Set a username and password before granting access to other users or exposing the service through a reverse proxy.
2. Retain `/config/config.yml` and the database under `/config`. Use `/generated`, `/metadata`, `/cache`, and `/blobs` for their corresponding storage settings. Image blobs may be kept in the database; `/blobs` is available when you choose filesystem storage.
3. Under **Settings > Library**, add the individual directories you want cataloged as video-only paths. Match your intended Jellyfin selection and omit staging and recycling directories. Selecting a parent includes its subdirectories. Exclude images so existing artwork does not become separate gallery items.
4. Scan a small folder first. Confirm the expected scene count, open an item, and test playback. A healthy container only confirms its heartbeat; it does not establish successful scanning or matching.
5. Follow [Accessing StashDB](https://guidelines.stashdb.org/docs/faq_getting-started/stashdb/accessing-stashdb/) to obtain an API key. Add `https://stashdb.org/graphql` under Stash's **Settings > Metadata Providers > Stash-box Endpoints**, then use the [scene tagger](https://docs.stashapp.cc/in-app-manual/tagger/) to identify a sample. Review the match before saving or processing the rest of the library.

Stash maintains its own metadata; enabling this service does not import existing NFO files. Configure optional providers and plugins in Stash using their upstream instructions, such as [FansDB](https://docs.fansdb.cc/guides/scraping-scenes-from-fansdb/) and [mcMetadata](https://github.com/carrotwaxr/stash-plugins/blob/main/plugins/mcMetadata/README.md). Limit file-changing plugins to writable paths and review a dry run before enabling changes.

## Connect Jellyfin deliberately

If using [DirtyRacer's Stash plugin](https://github.com/DirtyRacer1337/Jellyfin.Plugin.Stash), verify that its release supports your installed Jellyfin version. Maraudarr installs no plugins automatically.

1. In the plugin settings, use `http://stash:9999` when Jellyfin and Stash are in this generated project. Supply an API key generated by your local Stash application. An external Jellyfin needs a reachable host address or HTTPS proxy, not the Compose hostname.
2. Keep the same media paths in Jellyfin and Stash for the plugin's default full-path matching. For example, both should see a main-library scene as `/data/scenes/main/FILE.mp4`. Filename matching is available when paths differ, but duplicate filenames can be ambiguous.
3. Refresh one test item and confirm the intended metadata and playback before refreshing the rest of the library.

## Account for Whisparr path differences

The generated main Whisparr instance maps host `movies/main` and `scenes/main` to `/data/movies` and `/data/scenes`. Jellyfin and Stash mount the parent media root, so they see `/data/movies/main` and `/data/scenes/main`. Whisparr Alt similarly maps its `alt` directories. Confirm your actual overrides before configuring notifications.

Whisparr's Stash connection sends folder paths for scans and cleanup. Its single **Map Paths From / To** prefix pair cannot translate both default movie and scene roots at once. This chart does not configure that connection. Scan the relevant library again in Stash after Whisparr imports, upgrades, or renames files; do not enable automatic cleanup with an unverified mapping. After media is moved or removed, review Stash's scan and cleanup results before bulk operations.

## Back up and recover

Stash state and the original media need separate backups. Configuration, a Stash-created database backup, image storage, and metadata exports form the durable application recovery set. Cache and generated previews can be rebuilt. The default `make backup` archive includes all of `config/`, including previews and other applications; it excludes `.env`, original media, and external bind sources. A host archive does not replace Stash's database backup task.

1. In Stash, open **Settings > System** and set **Backup directory path** to `/metadata/backups`. Open **Settings > Tasks**, select **Backup**, and save a database backup to that directory. Include blobs if you want image data in the database backup. Confirm the backup task succeeds and the backup file exists before continuing. Follow [Stash's database backup procedure](https://docs.stashapp.cc/guides/backup-and-restore-database/) for its current options.
2. Stop Stash before archiving the surrounding application state:

    ```sh
    docker compose --project-directory dist/boudoirr stop stash
    ```

3. Archive the generated config tree:

    ```sh
    make backup PRESET=boudoirr
    ```

4. Back up any overridden durable state paths outside that tree separately. Store `.env` separately. Verify that the archive contains the Stash-created database backup, configuration, and any separate image storage; retain an off-host copy and record the selected image tag. Start Stash again:

    ```sh
    docker compose --project-directory dist/boudoirr start stash
    ```

5. For recovery, keep Stash stopped and restore configuration and separate image storage into fresh host directories writable by the configured identity. Restore the Stash-created database backup as `stash-go.sqlite` under the configured database directory, with no old `-shm`, `-wal`, or journal files beside it. Point the generated `.env` paths at the restored directories, restore matching media paths, and recreate only Stash:

    ```sh
    docker compose --project-directory dist/boudoirr up -d stash
    ```

6. Confirm account login, scene counts, identified metadata, images, and playback on a sample before resuming bulk tasks. If recovery fails, retain the original backup and inspect logs before retrying. Stopping Stash does not make another application's database backup consistent.

Deselecting Stash, `make down`, and `make nuke` preserve its bind-mounted state. `make delete-config` is destructive and removes Stash data inside the selected config tree; it is not a service-removal step.
