# Recyclarr service chart ♻️

Provides Recyclarr as a profile-gated, disposable synchronization tool. Its catalog dependencies add Radarr and Sonarr, matching the generated starter configuration. Normal `make up` runs do not start it. Preview and apply the selected configuration explicitly with:

```sh
make recyclarr-preview PRESET=plundarr
make recyclarr-sync PRESET=plundarr
```

> [!CAUTION]
> A sync changes the configured Radarr and Sonarr instances. Put their API keys in the generated `.env`, review `config/recyclarr/recyclarr.yml`, and run the preview target before applying it.

The generated starter configuration syncs only the upstream quality-size definitions and does not delete old custom formats. Maraudarr seeds it once and preserves operator changes during later regeneration. See the official [Recyclarr features](https://recyclarr.dev/guide/features/) and [`sync` command](https://recyclarr.dev/cli/sync/) references before extending it.
