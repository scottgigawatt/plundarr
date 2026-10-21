# Themerr for Plex and Jellyfin 🎵

Give the library a soundtrack. Duplex includes one required Themerr instance alongside Kometa and ImageMaid. PATTRMM and Notifiarr remain removable defaults. The same Themerr instance connects to both Plex and Jellyfin, including servers deployed in separate Compose projects. It does not deploy either media server itself.

Run generation examples from the repository root with `MARAUDARR_IMAGE` set to the [source-built generator](../development/maraudarr/index.md#choose-the-generator-revision) for this checkout.

## Generate the service

```sh
make ship PRESET=duplex
```

Themerr is also an optional addition to standalone Jellyfin, Boudoirr, or another preset:

```sh
make ship PRESET=jellyfin ADD_SERVICES=themerr
```

Review these values in the generated `.env`:

| Setting | Default in Duplex | Purpose |
| --- | --- | --- |
| `THEMERR_TAG` | `latest` | Official stable upstream image channel |
| `THEMERR_WEBUI_PORT` | `9494` | HTTPS administrator UI |
| `THEMERR_CONNECTOR_PORT` | `9495` | HTTP Jellyfin connector repository, not the admin UI |
| `THEMERR_CONFIG_PATH` | `./config/themerr` | Writable application settings, database, logs, and certificates |
| `THEMERR_TOKEN_KEY_PATH` | `./config/secrets/themerr-tokens.key` | Private persistent credential-encryption key outside application state |

Other presets apply their normal host-port offsets. Standalone Jellyfin uses `29494` and `29495`; Boudoirr uses `19494` and `19495`. Homepage gets an HTTPS link when both services are selected. Themerr currently publishes amd64 and arm64 images; an arm/v7 host cannot run this service image.

Maraudarr creates the managed key once with owner-only permissions. Regeneration preserves its exact bytes, existing settings, and inactive service environment values. Existing managed application state without its key stops regeneration so you can restore the original key. Keep the key and the Themerr state together in backups; losing the key requires reconnecting servers. External configuration or key paths are operator-owned: prepare both before launch, and keep the matching key with its application-state backup. [Upstream Docker guidance](https://docs.lizardbyte.dev/projects/themerr/latest/about/docker.html) describes the key format and binds.

The configured `DEFAULT_PUID` and `DEFAULT_PGID` run Themerr directly through Compose's `user` setting. The image's runtime `PUID`/`PGID` environment variables alone do not remap its build-time user. Ensure that UID can write the config directory and read the private key; a rootless generator cannot repair ownership for a different host UID. Run generation as the intended host user or adjust ownership deliberately before startup. `HOME=/tmp` keeps temporary caches writable while Docker mode stores application state in `/config`.

## Complete administrator setup

Start the generated stack after preparing its other required paths:

```sh
make up PRESET=duplex
```

Open `https://HOST:9494`, using your chosen host port. The initial certificate is self-signed; verify the host and handle trust in your browser. Read the first-run administrator setup link locally in the Themerr container logs and create a password of at least 12 characters. The administrator account is separate from Plex sign-in. Do not publish the setup link or logs containing it.

On **Servers**, add Plex through its sign-in flow and Jellyfin using its server address and API key. Use server-to-server reachable addresses including scheme and published port. Containers in separate preset networks cannot resolve each other's Compose service names. A LAN host address works across those projects; `localhost` inside Jellyfin refers to Jellyfin itself. Confirm reachability in both directions before processing.

The seeded `config.ini` turns Plex cleanup and Plex-provided theme replacement off. Jellyfin uses `AUTO_RESTART=False` and `REMOVE_LEGACY_PLUGIN=False`, with user-theme replacement also disabled. Existing configurations retain their operator values. Review each server's effective preferences in the UI before the first run. Theme downloading needs outbound access to the theme database and YouTube. Optional YouTube cookies can be uploaded through Themerr and are encrypted; add them only if extraction needs them.

## Connect Jellyfin 12.2

Themerr's stable release reviewed October 13, 2026 bundles a connector supporting Jellyfin 12.1 through the 12.x line, including 12.2. Use the connector bundled with the selected Themerr version. [Upstream connector policy](https://docs.lizardbyte.dev/projects/themerr/latest/contributing/media_servers.html#jellyfin-connector) explains version matching.

Set Themerr's reachable connector address on the Servers page. With the default self-signed admin certificate, use `http://HOST:9495`, adjusted for the published connector port. That HTTP listener serves connector files only. Themerr can install its matching connector automatically; review this setting before connecting. Automatic Jellyfin restarts are disabled in fresh generated settings. Restart Jellyfin manually after installing the connector, then confirm it is active. If you enable automatic restarts later, retain **Wait for playback to finish**; paused streams also defer a restart. Retain the seeded `REMOVE_LEGACY_PLUGIN=False` preference.

Jellyfin must have write access to its media folders and each movie should have its own directory. The existing generated Jellyfin `/data` mount is writable. Themerr itself does not need the media bind: its connector performs writes through Jellyfin. Enable **Theme songs** in each supported client's Display settings and test one item first. Browser CSS themes and media theme songs are separate features; Vue or native-client support needs its own playback check.

## Connect Plex and avoid unnecessary cleanup

Plex Movie and Plex Series agents provide the supported matching identifiers. Theme uploads use the server API, so this chart does not mount Plex application metadata or configure SSH cleanup. Keep cleanup disabled unless you deliberately configure the separate writable metadata or SSH access upstream requires. ImageMaid already has its own cleanup boundary in Duplex; avoid overlapping destructive schedules. Review **Prefer MP4A AAC Codec** if a theme fails on an Apple client; the reviewed upstream default already enables it.

## Expectations for adult libraries

Themerr's theme database primarily matches TMDb and IMDb identifiers. Adult scenes identified only through TPDB or StashDB may have few matching themes; deploying the service does not create coverage for them. Start with one recognizable movie and one scene, inspect unmatched items, and keep hand-authored local theme files protected. Jellyfin user-theme replacement stays off by default. A missing theme should remain a library-quality issue, not a reason to replace good local metadata.

Back up the application database, settings, certificates, and separate key as one recovery set. `THEMERR_TAG` selects the runtime image; check its connector requirements for the selected servers. The project does not connect your servers, install production plugins, or submit account credentials automatically. [Upstream usage](https://docs.lizardbyte.dev/projects/themerr/latest/about/usage.html) covers processing, connection preferences, and recovery.
