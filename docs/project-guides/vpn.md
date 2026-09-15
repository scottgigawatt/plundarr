# Choose a VPN region 🧭

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
