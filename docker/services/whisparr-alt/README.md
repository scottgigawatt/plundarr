# Whisparr Alt service chart 🔞

Runs an optional second Whisparr v3 instance with its own database, settings, API key, port, and managed library. It starts unchecked in Maraudarr and is absent from every preset's defaults. A little extra cargo, only when you invite it aboard.

The primary `whisparr` service keeps its existing name and configuration paths. Main uses Whisparr's upstream **TMDB** movie default for collection support. Use Alt as the **TPDB** fallback for movies main cannot match: choose **TPDB** under **Settings → General → Movie metadata source** before importing. A fresh Alt instance also starts with upstream TMDB until you change that setting; host directory names do not configure it. Scene lookups use StashDB in both instances. This chart uses hotio's floating `v3` channel, matching the primary instance.

## Select the second instance

From the repository root, generate Boudoirr with the optional instance:

```sh
make ship PRESET=boudoirr ADD_SERVICES=whisparr-alt
```

Or run `make configure`, choose Boudoirr, and check **Whisparr Alt** in **Media automation**. Custom and other presets can also select it. It brings the shared Prowlarr and FlareSolverr services through catalog dependencies; it does not require the primary Whisparr. Both Whisparr instances wait for Prowlarr to be healthy during Compose startup.

Include your complete service selection when regenerating an existing project. Omitting `whisparr-alt` removes it from the generated chart while retaining its environment assignments and application state. Regeneration does not stop a previously running container; review Compose orphans before removing one.

## Review paths and ports

Edit `dist/boudoirr/.env` before starting the instance. Fresh `.env` and `example.env` files use these defaults:

| Setting | Boudoirr default | Purpose |
| --- | --- | --- |
| `WHISPARR_ALT_TAG` | `v3` | Supported floating Whisparr channel |
| `WHISPARR_ALT_WEBUI_PORT` | `16970` | Host port; the container listens on `6969` |
| `WHISPARR_ALT_CONFIG_PATH` | `./config/whisparr-alt` | Separate database and settings mounted at `/config` |
| `WHISPARR_ALT_IMPORT_PATH` | `/volume1/jellyfin/import` | Shared staging mounted at `/data/import` |
| `WHISPARR_ALT_MOVIES_PATH` | `/volume1/jellyfin/movies/tpdb` | Movie library mounted at `/data/movies` |
| `WHISPARR_ALT_SCENES_PATH` | `/volume1/jellyfin/scenes/alt` | Separate scene library mounted at `/data/scenes` |
| `WHISPARR_ALT_RECYCLE_PATH` | `/volume1/jellyfin/recycle/alt` | Private recycling bin mounted at `/data/recycle` |

The base port is `6970`, with Boudoirr's usual `10000` offset. Staging and library defaults follow the preset's media root. Set the paths for your host in `.env`; operator values survive regeneration.

Both instances receive only their configured child directories under `/data`. Main defaults to `movies/tmdb` and `scenes/main`; Alt defaults to `movies/tpdb` and `scenes/alt`. Their recycling directories are `recycle/main` and `recycle/alt`. Both share the `import` directory but use separate recycling bins. Alt's scene directory is available if you choose to manage scenes there; it does not expose main's scene library. Provider selection remains independent of these host directory names. Regeneration preserves existing `.env` paths, databases, and provider settings; it does not move existing libraries or change their metadata source.

A 1 MiB temporary filesystem provides a writable `/data` parent owned by the configured user/group. All four child bind mounts persist. Use `/data` as the root folder and keep naming prefixes at `movies/` and `scenes/`. Put durable files in the mounted children; files written directly to the parent disappear when the container is recreated. See the [main Whisparr mount and import guide](../whisparr/README.md) for naming and import behavior.

> [!IMPORTANT]
> Keep config paths, managed host libraries, recycling bins, and download-client categories separate for the two instances. Set **Scene Import Folder Format** to `import` and **Recycling Bin** to `/data/recycle` in each instance. Process shared import staging through only one instance at a time.

## Connect the second instance

1. Start the generated stack with `make up PRESET=boudoirr`, then open your host address on port `16970`.
2. Set **Settings → General → Movie metadata source** to **TPDB** before adding or importing fallback movies. Changing this setting does not convert existing TMDB records to TPDB; refresh follows each record's stored provider. See Whisparr's [search routing](https://github.com/Whisparr/Whisparr-Eros/blob/eros-develop/src/NzbDrone.Core/MetadataSource/SkyHook/SkyHookProxy.cs) and [refresh behavior](https://github.com/Whisparr/Whisparr-Eros/blob/eros-develop/src/NzbDrone.Core/Movies/RefreshMovieService.cs).
3. Add `/data` as Alt's root folder, use the `movies/` folder-format prefix, and choose quality profiles. Set the import and recycling fields as described above. Configure the shared download client with a distinct category such as `whisparr-alt`.
4. In Prowlarr, add a separate Whisparr application using `http://whisparr-alt:6969` and Alt's own API key from **Settings → General**. Use `http://prowlarr:9696` as the Prowlarr server URL inside this project. Test and sync the connection independently of the primary instance.
5. Add the corresponding folder to Jellyfin. With the Boudoirr defaults, Alt's `/data/movies` corresponds to Jellyfin's `/data/movies/tpdb`. Alt's `/data/scenes` similarly corresponds to Jellyfin's `/data/scenes/alt`. Do not add staging or recycling directories as media libraries.

The official Velvarr image selected by default connects to one Whisparr endpoint for TPDB movies and StashDB scenes. If Alt fulfills Velvarr requests, connect Velvarr to `http://whisparr-alt:6969` with Alt's API key and map Alt's `/data/movies` to Jellyfin's matching host-library view, `/data/movies/tpdb` with the defaults. Choose the appropriate movie provider before importing; the directory name does not select it. Adjust that mapping when you change host mounts. For an image with TMDB and multiple-instance support, configure main for TMDB movies and default scenes, and Alt for TPDB movies; see the [Velvarr setup guide](../../../docs/project-guides/velvarr.md).

When Homepage is selected too, Maraudarr adds a **Whisparr Alt** browser link and container status card. Set `HOMEPAGE_VAR_WHISPARR_ALT_HREF` to your host or reverse-proxy URL in `.env`. When the primary instance is selected too, Homepage shows separate **Whisparr** and **Whisparr Alt** cards, each pointing to its own port and container.

Verify that both Whisparr containers are healthy with `make ps PRESET=boudoirr`, test Prowlarr's two application connections, and confirm a download lands only in its intended library.

## Preserve application state

The database and settings use a host bind mount; no separate database container or named volume is needed. Use Whisparr's built-in backup export and keep a copy outside the config directory. Stop Alt before making a raw copy of its entire config directory so SQLite files are consistent. Keep backups for the two instances separate.

Regeneration and deployment cleanup preserve application state. Host config deletion is a separate destructive operation; review `make delete-config` before using it.
