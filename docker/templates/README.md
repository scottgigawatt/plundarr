# Shared chart timber 🪵

These files contain the common pieces wrapped around every generated Plundarr stack:

| Scroll            | Purpose                                                                |
| :---------------- | :--------------------------------------------------------------------- |
| `compose.yml`     | Shared YAML anchors, the `services:` opening, and network footer       |
| `environment.env` | Project, path, permission, healthcheck, logging, and timezone defaults |

Selectable service definitions belong under [`../services/`](../services/), not in these shared foundations.

`security-hardening` contains the shared `cap_drop: [ALL]` and `no-new-privileges:true` settings. Apprise, Jellyfin Vue, Privateerr, Themerr, and Velvarr merge it alongside their existing container defaults. The block merge list preserves both anchors without duplicate YAML merge keys. It does not change the image user, filesystem access, healthchecks, or startup settings. Other services keep their existing capability policies.

Maraudarr retains this anchor only when a selected service references it. Privateerr continues to use its upstream root identity with all capabilities dropped; Jellyfin Vue continues to use its image-defined nginx identity.

Application-specific anchors follow `default-healthcheck-settings`, immediately before the service section:

| Anchor | Selected services | Shared settings |
| --- | --- | --- |
| `wait-for-prowlarr` | Radarr, Lidarr, Sonarr, Sonarr Anime, Whisparr, Whisparr Alt | Required healthy Prowlarr dependency |
| `sonarr-healthcheck` | Sonarr and Sonarr Anime | Direct `wget` ping probe at internal port `8989`, with default timing |
| `whisparr-runtime` | Whisparr and Whisparr Alt | A 1 MiB writable `/data` parent and direct `wget` ping probe at internal port `6969`, with default timing |

Instance-specific ports, persistent mounts, image tags, and environment values stay in each service chart. Maintenance profiles and restart policies remain explicit in the tool charts. Keep each foundation anchor in one contiguous block so comment-preserving pruning retains its entire definition and indirect dependencies.
