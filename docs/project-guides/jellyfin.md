# Jellyfin clients and customization 🎞️

Add an alternative browser client, keep Web settings on the host, and give your library a little velvet. Plundarr deploys the stack; Maraudarr generates its Compose chart, environment, and safe configuration seeds. These instructions target the official Jellyfin image and Jellyfin Server/Web 12.2, while retaining the floating `latest` image default.

## Choose the client

Jellyfin Web is bundled with the server and supports `config.json`, custom menu links, and Branding CSS. [Jellyfin Vue](https://jellyfin.org/docs/general/clients/jellyfin-vue/) is an experimental separate browser client with its own configuration. Neither Web settings nor the Boudoirr CSS theme customize Vue or every native client.

Generate either supported combination:

```sh
make ship PRESET=boudoirr ADD_SERVICES=jellyfin-vue
make ship PRESET=jellyfin ADD_SERVICES=jellyfin-vue
```

Vue stays opt-in for every preset. Select it in Maraudarr's service picker or add `jellyfin-vue` on the command line. It recommends Jellyfin without deploying another server automatically. To use an existing server with Boudoirr:

```sh
make ship PRESET=boudoirr REMOVE_SERVICES=jellyfin ADD_SERVICES=jellyfin-vue
```

Fresh deployment ports are:

| Preset | Jellyfin Web | Jellyfin Vue |
| --- | --- | --- |
| `boudoirr` | `18096` | `18082` |
| `jellyfin` | `28096` | `28082` |

Open Vue at its host port and enter the Jellyfin URL, including scheme and server host port. You can prefill one or more comma-separated URLs with `JELLYFIN_VUE_DEFAULT_SERVERS` in the deployment's `.env`. Leave it empty for manual selection. Keep `JELLYFIN_VUE_DISABLE_SERVER_SELECTION=0` until the configured server works; hiding selection without a reachable default leaves the client loading indefinitely. `JELLYFIN_VUE_HISTORY_ROUTER_MODE=1` uses the upstream nginx history-routing setup; `0` uses hash routing.

> [!IMPORTANT]
> The browser connects directly to Jellyfin. Use an address reachable from each client device, not Docker's `http://jellyfin:8096` or a loopback address. An HTTPS frontend requires an HTTPS Jellyfin URL to avoid mixed-content blocking. Vue currently publishes `linux/amd64` and `linux/arm64`, not `linux/arm/v7`.

Vue retains its image's nginx user and writable startup configuration. It needs no media mounts, API keys, persistent database, or server startup dependency. Its healthcheck tests the static frontend. Its supported image channel is `unstable`; existing Watchtower policy controls unattended updates. Read the [Vue chart](https://github.com/scottgigawatt/plundarr/blob/main/docker/services/jellyfin-vue/README.md) for the container boundary.

## Select your Web configuration

When Jellyfin is selected, Maraudarr seeds these files beneath `dist/YOUR-PRESET/config/jellyfin/web/`:

- `config.json`: Jellyfin Web 12.2 settings retaining the normal player and theme defaults.
- `privacy-config.json`: The same settings without the Chromecast and YouTube players.
- `custom/boudoirr.css`: A local plum, velvet pink, and warm gold stylesheet.

Replace `YOUR-PRESET` with `boudoirr` or `jellyfin`. Regeneration creates missing seeds and preserves existing JSON, CSS, environment values, and server state. The mounts are read-only inside Jellyfin; edit their host files. `JELLYFIN_WEB_CONFIG_PATH` selects the existing JSON file, while `JELLYFIN_WEB_CUSTOM_PATH` selects the local CSS/image directory. The generator does not create files at operator-selected external paths.

To choose the privacy example, set this assignment in the deployment's `.env`:

```dotenv
JELLYFIN_WEB_CONFIG_PATH="./config/jellyfin/web/privacy-config.json"
```

This removes the two external player integrations described in [Jellyfin's privacy guidance](https://jellyfin.org/docs/general/clients/web-config/#privacy-focused-changes). It does not disable server metadata providers or remove remote images from library metadata. Jellyfin 12.2 uses player names such as `chromecastPlayer/plugin` in its JSON list; edit the actual list rather than copying older examples containing a `plugins/` prefix.

Validate your selected file, then recreate Jellyfin. This Boudoirr example assumes the default file path; change the JSON path when selecting another file:

```sh
python3 -m json.tool dist/boudoirr/config/jellyfin/web/config.json >/dev/null
make up PRESET=boudoirr
```

Compose applies changed mount paths when recreating the container. If the path is unchanged and an editor replaced the file inode, explicitly recreate only Jellyfin:

```sh
docker compose --env-file dist/boudoirr/.env -f dist/boudoirr/docker-compose.yml up -d --force-recreate jellyfin
```

Missing bind sources fail startup rather than becoming directories that hide the image's `config.json`. For older generated deployments, regenerate before launch to create the new seeds. A mounted config also hides newer image defaults: compare your file with the bundled `config.json` whenever `latest` moves to a new release, then merge desired changes manually. Your menu links and edits always remain authoritative. [Upstream Web configuration](https://jellyfin.org/docs/general/clients/web-config/) explains the mount target.

## Enable the Boudoirr theme

Choose **Dark** in the client's display settings. In **Dashboard > Branding > Custom CSS**, add this import, save, and reload:

```css
@import url("custom/boudoirr.css");
```

For an individual account, use **Settings > Display > Custom CSS**. When choosing a different personal theme, enable **Disable server-provided custom CSS code** to prevent the global theme from stacking with it. The relative asset URL stays on your Jellyfin origin and follows a server base path. Open the stylesheet from the Web client to confirm it loads. Edit `dist/YOUR-PRESET/config/jellyfin/web/custom/boudoirr.css` to change the palette, then reload with the browser cache bypassed.

The theme targets Jellyfin 12.2's `--jf-palette-*` variables, React/MUI navigation classes, and existing Web card classes. It adds plum surfaces, pink actions, gold progress and focus outlines, and softly rounded artwork. It retains normal hit targets, playback controls, keyboard focus, and reduced-motion preferences. It imports no external fonts, images, or scripts. The JSON mount does not enable CSS by itself; Branding chooses the stylesheet separately. The Jellyfin 12 admin dashboard and native clients may keep their own appearance.

Clear the CSS import to restore the normal Web appearance. Regeneration preserves theme edits, so changing the project seed will not replace a deployed theme. Verify login, library browsing, item details, playback controls, mobile layout, and keyboard focus after each Web upgrade. [Custom CSS documentation](https://jellyfin.org/docs/general/clients/css-customization/) explains global and per-user settings.

[Jellyfish](https://github.com/n00bcodr/Jellyfish) is a broader alternative whose current source explicitly supports Jellyfin 12's modern layout. Choose one main theme at a time; stacking unrelated themes can produce conflicting rules. The bundled Boudoirr theme keeps its assets local and its changes smaller.

## Choose from six local styles

The original Boudoirr theme has five additional companions. These are original styles adapted around the tested Jellyfin Web 12.2 base, with research inspiration from the community projects below. Each option changes its palette and visual treatment, rather than merely changing the accent color. They require no external fonts, background downloads, JavaScript injection, or additional plugins.

| Local style | Design direction | Community inspiration | Import in Custom CSS |
| --- | --- | --- | --- |
| Boudoirr | Plum, velvet pink, warm gold | Original Plundarr theme | `@import url("custom/boudoirr.css");` |
| Oceanic | Deep navy, seafoam, coral, sharp artwork frames | [Scyfin](https://github.com/loof2736/scyfin) | `@import url("custom/oceanic.css");` |
| Noir cinema | Near-black cinema chrome, soft red, angular posters | [Finimalism](https://github.com/tedhinklater/finimalism) | `@import url("custom/noir-cinema.css");` |
| Aurora glass | Frosted violet/mint navigation, generous corner rounding | [Abyss](https://github.com/AumGupta/abyss-jellyfin) | `@import url("custom/aurora-glass.css");` |
| Rose editorial | Warm rose, serif section headings, fine gold borders | [ElegantFin](https://github.com/lscambo13/ElegantFin) and its [12-modern companion](https://github.com/mihaif7/elegantfin-jf12) | `@import url("custom/rose-editorial.css");` |
| Emerald lounge | Jewel green surfaces, gold details, rounded actions | [Jellyfish](https://github.com/n00bcodr/Jellyfish) | `@import url("custom/emerald-lounge.css");` |

Select **Dark** in Display settings and use one import from the table. Replace the previous theme import rather than layering themes. Every option is served locally from the generated `web/custom/` directory and remains editable. The five companions load `theme-base.css` from the same directory; preserve that file alongside them if moving assets to an external path.

The community projects have different compatibility and dependency requirements. ElegantFin's upstream documentation currently asks Jellyfin 12 users to use Legacy display mode, while its companion targets Modern mode. The local Rose editorial option uses modern Jellyfin variables and keeps the current layout. The local styles borrow design ideas rather than bundling upstream CSS, so their behavior and updates are controlled by this project. Test login, navigation, library/details, player controls, mobile layout, and keyboard focus on the specific clients you use. Compatibility checks cover Web 12.2; future floating-image releases require another review.

## Add useful menu links

Edit `menuLinks` in the selected `config.json`. Good shared-user choices are **Requests** for Velvarr, **Jellyfin Vue** for the alternative client, and **Help** for your own server instructions. Replace the example URLs with addresses your users can reach:

```json
"menuLinks": [
    {
        "name": "Requests",
        "icon": "movie",
        "url": "https://requests.example.com"
    },
    {
        "name": "Jellyfin Vue",
        "icon": "play_circle",
        "url": "https://vue.example.com"
    },
    {
        "name": "Help",
        "icon": "help",
        "url": "https://help.example.com"
    }
]
```

This is one property inside the existing object, not a replacement file. Vue is a separate origin/client and may require a separate login. Keep Whisparr, download clients, Portainer, and NAS administration out of shared user menus. A visible menu link does not grant access or enforce authentication. Use icons documented by [Jellyfin's menu-link reference](https://jellyfin.org/docs/general/clients/web-config/#custom-menu-links).

## Customize an adult-media library

Start with the built-in features before adding plugins:

- Create separate movie and scene libraries, with clear names and dedicated library images. Match their paths to the generated Whisparr instance roots beneath `/data/movies/` and `/data/scenes/`.
- Use performer favorites, studio/performer collections, and consistent genres and tags. Existing metadata quality determines how useful these views become.
- Enable native Trickplay thumbnails and chapter-image extraction for quick scene navigation. Schedule extraction during idle time and start with a small library subset to measure CPU and disk cost. Jellyfin already provides Trickplay; Jellyscrub is unnecessary for this feature.
- Customize the login disclaimer in Branding, user avatars, and library artwork. Restrict each user's library access through server permissions; hiding a card with CSS does not restrict access.
- Keep Whisparr-owned NFO files authoritative while leaving remote metadata available for items without NFOs. Avoid enabling Jellyfin's NFO saver on those same folders. Review [local NFO behavior](https://jellyfin.org/docs/general/server/metadata/nfo/) and confirm a refresh on one managed item before bulk changes.

## Choose plugins deliberately

The following review checked upstream repositories and published compatibility manifests on **October 13, 2026**. A declared target ABI is evidence of intended server compatibility, not proof that every feature works with your library. Jellyfin's [official plugin catalog](https://jellyfin.org/docs/general/server/plugins/) and third-party repositories are separate sources. Nothing in this deployment installs plugins or changes existing plugin settings automatically.

| Plugin | Source | Published target | Recommendation for Boudoirr |
| --- | --- | --- | --- |
| [Reports](https://github.com/jellyfin/jellyfin-plugin-reports) | Official | `12.0.0.0` | Useful first install for auditing library metadata and organization. |
| [Webhook](https://github.com/jellyfin/jellyfin-plugin-webhook) | Official | `12.0.0.0` | Useful for intentional server notifications. Keep adult titles and playback events out of broad public channels. |
| [Subtitle Extract](https://github.com/jellyfin/jellyfin-plugin-subtitleextract) | Official | `12.0.0.0` | Optional if embedded subtitles cause playback delays. |
| [Local Intros](https://github.com/jellyfin/jellyfin-plugin-local-intros) | Official | `12.0.0.0` | Fun optional local pre-roll; it adds an intro before playback. |
| [Playback Reporting](https://github.com/jellyfin/jellyfin-plugin-playbackreporting) | Official | `12.0.0.0` | Optional detailed viewing statistics. Consider whether you want extra watch-history retention alongside Tracearr. |
| [SmartLists](https://github.com/jyourstone/jellyfin-smartlists-plugin) | Third party | `12.0.0.0` | Strong fit for dynamic performer, studio, genre, and tag collections/playlists. |
| [Media Preview](https://github.com/spkesDE/jellyfin-media-preview-plugin) | Third party | `12.1.0.0` | Strong fit for Web hover previews using native Trickplay or local trailers. Start with local previews and verify its injection-helper setup. |
| [Jellyfin Enhanced](https://github.com/n00bcodr/Jellyfin-Enhanced) | Third party | `12.0.0.0` | Optional Web shortcuts and usability improvements. Enable only useful modules; its Seerr integration does not replace Velvarr's adult requests. |
| [ThePornDB](https://github.com/ThePornDatabase/Jellyfin.Plugin.ThePornDB) | Third party | Latest listed build targets `10.11.0.0` | Hold for 12.2. No published 12-target build was found in its manifest. Useful adult metadata provider once compatibility is established, especially for unmanaged items. |
| [Stash](https://github.com/DirtyRacer1337/Jellyfin.Plugin.Stash) | Third party | Latest listed build targets `10.11.0.0` | Hold for 12.2 and consider only if you actually run a Stash server. |
| [PhoenixAdult](https://github.com/DirtyRacer1337/Jellyfin.Plugin.PhoenixAdult) | Third party | Older release line | Skip for this deployment; the upstream repository has not been updated since 2024 and no 12.2 support was established. |
| [Skin Manager](https://github.com/danieladov/jellyfin-plugin-skin-manager) | Third party | Not validated for this review | Unnecessary for the bundled local theme; direct CSS keeps the setup simpler. |

Trakt scrobbling, Discord rich presence, generic trailer downloads, anime metadata providers, and TV integrations are low-priority choices for this server. They either serve a different library type or add external sharing/integrations without improving adult-media organization. Keep them optional.

## Install a reviewed plugin

Use **Dashboard > Plugins > Catalog** for official plugins. For a selected third-party plugin, use **Dashboard > Plugins > Repositories**, add its documented manifest URL, then return to the catalog. These are the reviewed optional repositories:

| Repository | Manifest URL |
| --- | --- |
| SmartLists | `https://raw.githubusercontent.com/jyourstone/jellyfin-plugin-manifest/main/manifest.json` |
| Media Preview | `https://raw.githubusercontent.com/spkesDE/jellyfin-media-preview-plugin/main/manifest.json` |
| Jellyfin Enhanced | `https://raw.githubusercontent.com/n00bcodr/jellyfin-plugins/main/manifest.json` |

Back up Jellyfin's config first, install one compatible plugin, and restart Jellyfin before testing it. Confirm its version targets the current server and that it appears active. For Web enhancements, test the built-in Web client; do not assume Vue or a native app consumes injected Web scripts. For metadata providers, test a small unmanaged subset and keep valid Whisparr NFOs authoritative.

An initial trial of **Reports**, then **SmartLists**, provides the most useful organization improvements. Add native Trickplay next, followed by **Media Preview** if you want hover previews. Keep **Jellyfin Enhanced** as an optional usability layer and revisit ThePornDB/Stash when their published manifests include a compatible 12 build. Your server can stay fabulous without loading every plugin in the harbor.
