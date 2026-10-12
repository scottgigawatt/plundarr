# Whisparr Alt service chart 🔞

Runs an optional second Whisparr v3 instance with its own database, settings, API key, port, and managed library. It starts unchecked in Maraudarr and is absent from every preset's defaults. A little extra cargo, only when you invite it aboard.

The existing `whisparr` service stays unchanged. Neither instance is tied to a metadata provider: choose **TMDB** or **TPDB** independently in each instance under **Settings → General → Movie metadata source**. This chart uses hotio's floating `v3` channel, matching the primary instance.

## Select the second instance

From the repository root, generate Boudoirr with the optional instance:

```sh
make ship PRESET=boudoirr ADD_SERVICES=whisparr-alt
```

Or run `make configure`, choose Boudoirr, and check **Whisparr Alt** in **Media automation**. Custom and other presets can also select it. It brings the shared Prowlarr and FlareSolverr services through catalog dependencies; it does not require the primary Whisparr.

Include your complete service selection when regenerating an existing project. Omitting `whisparr-alt` removes it from the generated chart while retaining its environment assignments and application state. Regeneration does not stop a previously running container; review Compose orphans before removing one.

## Review paths and ports

Edit `dist/boudoirr/.env` before starting the instance. Fresh `.env` and `example.env` files use these defaults:

| Setting | Boudoirr default | Purpose |
| --- | --- | --- |
| `WHISPARR_ALT_TAG` | `v3` | Supported floating Whisparr channel |
| `WHISPARR_ALT_WEBUI_PORT` | `16970` | Host port; the container listens on `6969` |
| `WHISPARR_ALT_CONFIG_PATH` | `./config/whisparr-alt` | Separate database and settings mounted at `/config` |
| `WHISPARR_ALT_DATA_PATH` | `/volume1/jellyfin/movies-alt` | Separate managed library mounted at `/data` |

The base port is `6970`, with Boudoirr's usual `10000` offset. The library default follows the preset's media root with `/movies-alt` appended. Both paths and the port can be changed through `.env`; existing values survive regeneration. The shared arr settings supply host user/group IDs, timezone, container hardening, and the download mount at `/downloads`.

> [!IMPORTANT]
> Keep the two instances' managed root folders separate. The primary Whisparr mounts the entire media root, so do not assign its `/data` parent as a managed root when Alt manages a child directory. Configure specific folders such as `/data/movies` and `/data/scenes` in the primary instance, and `/data` in Alt. Use separate config directories and download-client categories for each instance.

## Connect the second instance

1. Start the generated stack with `make up PRESET=boudoirr`, then open your host address on port `16970`.
2. Choose the metadata source before adding or importing movies. Changing this setting does not convert existing TMDB records to TPDB; refresh follows each record's stored provider. See Whisparr's [search routing](https://github.com/Whisparr/Whisparr-Eros/blob/eros-develop/src/NzbDrone.Core/MetadataSource/SkyHook/SkyHookProxy.cs) and [refresh behavior](https://github.com/Whisparr/Whisparr-Eros/blob/eros-develop/src/NzbDrone.Core/Movies/RefreshMovieService.cs).
3. Add `/data` as Alt's root folder, choose quality profiles, and configure the shared download client with a distinct category such as `whisparr-alt`.
4. In Prowlarr, add a separate Whisparr application using `http://whisparr-alt:6969` and Alt's own API key from **Settings → General**. Use `http://prowlarr:9696` as the Prowlarr server URL inside this project. Test and sync the connection independently of the primary instance.
5. Add the corresponding folder to Jellyfin. With the Boudoirr defaults, Alt's `/data` corresponds to Jellyfin's `/data/movies-alt`.

Velvarr currently connects to one Whisparr endpoint. If Alt manages the TPDB library, connect Velvarr to `http://whisparr-alt:6969` with Alt's API key and map Alt's `/data` to Jellyfin's `/data/movies-alt`. Adjust that mapping when you change host mounts. Velvarr cannot combine both Whisparr instances through this chart; see the [Velvarr setup guide](../../../docs/project-guides/velvarr.md).

When Homepage is selected too, Maraudarr adds a **Whisparr Alt** browser link and container status card. Set `HOMEPAGE_VAR_WHISPARR_ALT_HREF` to your host or reverse-proxy URL in `.env`.

Verify that both Whisparr containers are healthy with `make ps PRESET=boudoirr`, test Prowlarr's two application connections, and confirm a download lands only in its intended library.

## Preserve application state

The database and settings use a host bind mount; no separate database container or named volume is needed. Use Whisparr's built-in backup export and keep a copy outside the config directory. Stop Alt before making a raw copy of its entire config directory so SQLite files are consistent. Keep backups for the two instances separate.

Regeneration and deployment cleanup preserve application state. Host config deletion is a separate destructive operation; review `make delete-config` before using it.
