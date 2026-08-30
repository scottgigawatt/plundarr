# Kometa Overlay Reset Service Chart ⚠️

Provides Kometa Overlay Reset as a profile-gated, disposable recovery tool. Normal `make up` runs do not start it. Invoke it explicitly with:

```sh
make kometa-overlay-reset PRESET=duplex
```

> [!CAUTION]
> Overlay Reset is destructive and has no undo. Its generated default is `OVERLAY_RESET_DRY_RUN=True`; inspect that dry-run output before deliberately setting the value to `False` and running the command again.

The tool reads Plex connection values from the generated deployment's private `.env` and mounts the external Kometa checkout read-only at `/kometa`. See the [official Overlay Reset guide](https://kometa.wiki/en/latest/kometa/scripts/overlay-reset/).
