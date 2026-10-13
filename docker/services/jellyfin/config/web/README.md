# Jellyfin Web customization 🎨

Maraudarr seeds `config.json`, `privacy-config.json`, and `custom/boudoirr.css` once. Regeneration preserves each existing file. These settings target the built-in Jellyfin Web client, not Jellyfin Vue or native clients. The JSON files retain the functional defaults of [Jellyfin Web v12.2](https://github.com/jellyfin/jellyfin-web/blob/v12.2/src/config.json), with an optional privacy variant excluding Chromecast and YouTube players. The `$comment` property records project provenance and does not change client behavior.

`JELLYFIN_WEB_CONFIG_PATH` selects the existing JSON file bound read-only to `/jellyfin/jellyfin-web/config.json`. `JELLYFIN_WEB_CUSTOM_PATH` selects the directory served under `/web/custom/`. Defaults point to this generated directory. External paths remain operator-managed; Maraudarr does not create or replace those external files. Missing bind sources fail startup instead of becoming directories. Validate edited JSON before restarting the service.

To choose the privacy variant, set this value in the deployment's `.env` and recreate Jellyfin:

```dotenv
JELLYFIN_WEB_CONFIG_PATH="./config/jellyfin/web/privacy-config.json"
```

Keep the floating `JELLYFIN_TAG=latest` channel if desired, but compare your mounted JSON with the new image's bundled defaults on upgrades. Existing files never refresh automatically, because they may contain operator menu links and settings. A file bind can retain the old inode after an editor replaces the file; recreate the Jellyfin container after changing the JSON or its selected path.

To enable the local theme, choose the **Dark** display theme and enter this line in **Dashboard > Branding > Custom CSS**, then save and reload. Individual users can apply it through **Settings > Display > Custom CSS** instead:

```css
@import url("custom/boudoirr.css");
```

The relative URL keeps the stylesheet on the same origin and follows a configured server base path. Test it from the Web client, including the login page, library, detail page, and player. CSS does not style every native app or the Jellyfin 12 admin dashboard. Clear the import to restore the standard appearance. Edit `custom/boudoirr.css` to change the palette; no external fonts, images, JavaScript injector, or plugin is required.

Custom links belong in `menuLinks` in the selected JSON file. Useful choices are **Requests** pointing to your Velvarr URL, **Jellyfin Vue** pointing to its separate frontend, and **Help** pointing to your own server guide. Use real browser-accessible URLs and keep administrative applications out of shared user menus. Menu links are navigation, not access control.
