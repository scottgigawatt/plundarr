# Whisparr service chart 🔞

Automates an adult media library with Whisparr v3 and anchors the Boudoirr preset. The chart defaults to hotio's floating `v3` release channel because its `latest` tag still tracks Whisparr v2. Download clients remain selectable; tags below v3 are unsupported. Keep the cargo sorted before setting sail.

For a second independent library with its own metadata-provider choice, select the optional [Whisparr Alt service](../whisparr-alt/README.md). It is not selected by default. Both instances wait for Prowlarr to be healthy during Compose startup.

## Review the selective mounts

The chart mounts manual-import staging, movies, scenes, and its recycling bin separately. It does not expose the whole host media root. Edit the generated preset's `.env` before launch; Boudoirr uses these defaults:

| Setting | Boudoirr default | Container path |
| --- | --- | --- |
| `WHISPARR_CONFIG_PATH` | `./config/whisparr` | `/config` |
| `WHISPARR_IMPORT_PATH` | `/volume1/jellyfin/import` | `/data/import` |
| `WHISPARR_MOVIES_PATH` | `/volume1/jellyfin/movies` | `/data/movies` |
| `WHISPARR_SCENES_PATH` | `/volume1/jellyfin/scenes` | `/data/scenes` |
| `WHISPARR_RECYCLE_PATH` | `/volume1/jellyfin/recycle` | `/data/recycle` |

Other presets use the same directory names beneath their media root. The shared arr settings supply host user/group IDs, timezone, container hardening, and `${HOST_DOWNLOADS_PATH}` mounted at `/downloads`.

A 1 MiB temporary filesystem supplies the writable `/data` parent with the configured user/group ownership. Import, movie, scene, and recycle files live in the persistent child bind mounts. Put application data only in those mounted children; files written directly to the temporary parent disappear when the container is recreated. The root-folder space display reflects the temporary parent; check the persistent library mount for usable media capacity.

## Configure roots, naming, and imports

1. Create or confirm the host directories and grant the configured user/group read/write access.
2. Add `/data` as Whisparr's root folder. Under **Settings → Media Management**, use `movies/` as the leading directory in **Movie Folder Format** and `scenes/` in **Scene Folder Format**, retaining your naming tokens after each prefix. Whisparr chooses the format from the matched item's scene/movie type; root folders have no provider designation.
3. Set **Scene Import Folder Format** to `import`. Whisparr resolves this relative to `/data`, scanning `/data/import`. Use the corresponding movie or scene import screen and select the intended files. Process shared staging through one instance at a time.
4. Set **Recycling Bin** to `/data/recycle` and review the cleanup interval. The mount alone does not enable recycling. Use a different host recycle directory for each instance so one instance's cleanup does not remove the other's files.
5. Choose **Settings → General → Movie metadata source** before adding or importing movies. Host directory names do not select a metadata provider. Configure Prowlarr with this instance's own API key and use distinct download-client categories for the two instances.

Whisparr's import operation moves matched files into their generated library folders; it does not require hardlinks. Transfers across separate mounts can copy and then remove the source rather than perform an atomic rename. Allow enough destination space and verify the imported file before clearing staging. See the upstream [import operation](https://github.com/Whisparr/Whisparr-Eros/blob/v3.6.4-release.1865/src/Whisparr.Api.V3/Movies/MovieImportController.cs) and [relative import-folder resolution](https://github.com/Whisparr/Whisparr-Eros/blob/v3.6.4-release.1865/src/NzbDrone.Core/RootFolders/RootFolderService.cs).

The stable container prefixes allow hyphenated host directories such as Alt's `movies-alt` without using that name in Whisparr's folder format. Whisparr 3.6.4 requires an alphanumeric first directory in its movie and scene folder formats. Test one import before resuming normal automation.

## Connect Jellyfin, Velvarr, and Homepage

With Jellyfin mounted at `/volume1/jellyfin:/data`, the default main movie and scene paths match Whisparr at `/data/movies` and `/data/scenes`. Alt's `/data/movies` and `/data/scenes` instead map to Jellyfin's `/data/movies-alt` and `/data/scenes-alt`. Review Velvarr mappings whenever you change host paths. Keep the import and recycling directories out of Jellyfin's library selections.

When Homepage is selected, Maraudarr adds a **Whisparr** browser link and container status card. Set `HOMEPAGE_VAR_WHISPARR_HREF` in `.env` to your host or reverse-proxy URL. Selecting both Whisparr instances adds two independent cards.

Back up Whisparr's database and settings through its built-in backup export, with a copy stored outside `/config`. Host media and recycling directories need their own backup policy; they are not included in a config archive.
