# Configure VPN regions and recovery 🧭

## Choose a VPN region

Deployments containing Privateerr include these controls in the generated `.env`:

| Setting | Default | Behavior |
| --- | --- | --- |
| `PIA_AUTOCONNECT` | `true` | Select the lowest-latency eligible region; `false` uses the preferred region. |
| `PIA_PREFERRED_REGION` | `ca` | PIA region ID to use when automatic selection is disabled. |
| `PIA_PF` | `true` | Filter automatic selection to regions that advertise port forwarding. |

To select Montreal, change `PIA_AUTOCONNECT` to `false`. To choose another region, also edit `PIA_PREFERRED_REGION`; Canadian alternatives include `ca_toronto` (Toronto), `ca_vancouver`, and `ca_ontario`. Set `PIA_AUTOCONNECT` back to `true` to resume automatic selection; the saved preferred region is ignored until you disable it again. Dedicated-IP deployments use `PIA_DIP_TOKEN` instead of region selection.

Apply changes by recreating the complete selected stack. Replace `YOUR-PRESET` with your generated preset name:

```sh
make up PRESET=YOUR-PRESET
```

For a deployment managed directly with Docker Compose, run this from its generated project directory:

```sh
docker compose up --detach --force-recreate
```

In Synology Container Manager, rebuild the existing project using its updated `.env`. A container restart alone does not reload environment changes. Recreate the complete project so Gluetun and applications sharing its network are recreated together. Privateerr generates fresh WireGuard configuration and metadata before Gluetun starts; keep the generated Compose mappings in place.

Check Privateerr's logs for the selected region and Gluetun's logs for successful port forwarding. PIA's advertised forwarding support does not guarantee its forwarding API is currently available. If a region's API fails, choose another forwarding-capable region in `.env` and recreate the project. No manual Compose edits are needed. Steer around the storm, captain.

## Recover stale connections automatically 🛟

Generated deployments enable `PRIVATEERR_AUTO_RECOVER=true` whenever the resolved selection includes both Privateerr and Gluetun. This includes the Plundarr and Boudoirr core services, custom VPN selections, and download clients that add both services as dependencies. Privateerr on its own keeps recovery disabled; presets without Privateerr gain no recovery settings.

Maraudarr generates one random `PRIVATEERR_GLUETUN_API_KEY` in the deployment's private `.env` and supplies it to both containers. Regeneration preserves that key and your timing settings. The generated `example.env` leaves the key empty and contains no deployment credentials.

After a sustained tunnel outage, Privateerr registers fresh PIA WireGuard settings and applies them through Gluetun's authenticated control API. Gluetun restarts its internal tunnel while its container and shared network namespace stay in place. Privateerr saves the replacement files only after the settings match and the tunnel is healthy. No extra service or Docker socket is required.

The bundled wrapper lets Privateerr reach Gluetun's health listener over the shared Docker network and creates a temporary authentication role with only the recovery routes. Neither the health port nor the control API is published to the host. While recovery is enabled, the wrapper disables Gluetun's competing health-triggered restarts. Gluetun still owns the tunnel, firewall, and port forwarding, including qBittorrent's port-update hooks.

| Setting | Default | Purpose |
| --- | --- | --- |
| `PRIVATEERR_AUTO_RECOVER` | `true` with both services | Enable the recovery monitor. |
| `PRIVATEERR_RECOVERY_INTERVAL_SECONDS` | `30` | Seconds between health probes. |
| `PRIVATEERR_RECOVERY_FAILURE_SECONDS` | `120` | Startup grace and continuous failure threshold, in seconds. |
| `PRIVATEERR_RECOVERY_COOLDOWN_SECONDS` | `300` | Initial retry delay in seconds; failed attempts back off up to one hour. |
| `PRIVATEERR_GENERATION_TIMEOUT_SECONDS` | `180` | Maximum seconds for each PIA configuration generation. |

To disable recovery, set `PRIVATEERR_AUTO_RECOVER=false` in the generated `.env` and recreate the complete stack with `make up PRESET=YOUR-PRESET`. The wrapper then uses your normal `GLUETUN_HEALTH_RESTART_VPN` setting. A manually stopped VPN pauses automatic recovery; an unreachable or unauthorized control API does not trigger repeated PIA registrations. A port-forwarding-only failure does not rotate a healthy tunnel.

Recovery respects `PIA_AUTOCONNECT`, `PIA_PREFERRED_REGION`, and `PIA_PF`. A selected region stays pinned during recovery. See [Privateerr's recovery guide](https://github.com/scottgigawatt/privateerr/blob/main/docs/automatic-recovery.md) for the full sequence, authentication routes, and limits.

### Update an existing deployment

Use a Privateerr release that includes automatic Gluetun recovery before applying these settings. A saved `PRIVATEERR_TAG` pin remains unchanged during regeneration. Pull the updated Maraudarr generator and regenerate your selected preset:

```sh
make pull-image
make ship PRESET=YOUR-PRESET
```

Regeneration adds missing recovery settings and generates the shared key. It upgrades the unchanged previous bundled Gluetun wrapper, while preserving WireGuard state, application data, existing keys, and an explicit recovery opt-out.

> [!IMPORTANT]
> Customized, symlinked, or older unrecognized wrappers remain untouched. Before recreating such a deployment, update the script selected by `GLUETUN_WRAPPER_SCRIPT_PATH` using the [current wrapper](https://github.com/scottgigawatt/plundarr/blob/main/docker/services/gluetun/config/scripts/gluetun-entrypoint-wrapper.sh), or set `PRIVATEERR_AUTO_RECOVER=false`. If you maintain `/gluetun/auth/config.toml` yourself, add Privateerr's recovery role with the same shared key; the wrapper preserves that file.

Then recreate the complete stack with `make up PRESET=YOUR-PRESET`. In Synology Container Manager, rebuild the project using its regenerated Compose file and updated `.env`. Check Privateerr's logs for automatic recovery being enabled and Gluetun's logs for the tunnel becoming healthy. Keep the API key and VPN configuration out of support reports.
