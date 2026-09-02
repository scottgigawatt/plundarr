# Recyclarr configuration ♻️

`recyclarr.yml` is a conservative starter configuration for the Radarr and Sonarr services in the same generated stack. It reads service URLs and API keys from `.env` through Recyclarr's `!env_var` directive.

Maraudarr seeds the file only when it does not already exist, so later stack regeneration preserves your synchronization rules. Use `make recyclarr-preview PRESET=plundarr` before every deliberate sync.
