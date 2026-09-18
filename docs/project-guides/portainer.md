# Deploy Portainer 🚢

Generate a standalone Portainer Community Edition server to manage your Docker host:

```sh
make ship PRESET=portainer
```

Review `dist/portainer/.env` before starting it:

| Setting | Default | Purpose |
| --- | --- | --- |
| `PORTAINER_TAG` | `lts` | Official long-term support image channel. |
| `PORTAINER_CONFIG_PATH` | `./config/portainer` | Persistent Portainer database and configuration directory. |
| `PORTAINER_WEB_PORT` | `9443` | Host port for the HTTPS interface. |
| `PORTAINER_EDGE_PORT` | `8888` | Host port mapped to the Edge agent tunnel on container port `8000`. |

Set `PORTAINER_CONFIG_PATH` to an existing Portainer data directory if you intend to reuse it. Stop any other Portainer server using that directory before launching this project, and back up the data before changing versions. The generator does not copy existing data into the new project.

```sh
make up PRESET=portainer
```

Open `https://YOUR-HOST:9443`, substituting your host address and configured HTTPS port. Complete [Portainer's initial setup](https://docs.portainer.io/start/install-ce/server/setup). Portainer uses a self-signed certificate by default; follow the current setup-token instructions if the selected release requests a token. Keep any token private.

The preset starts only Portainer, with no VPN or updater dependency. Portainer receives access to `/var/run/docker.sock` to manage the local Docker environment; restrict access to its management interface accordingly. The Edge port is used for Edge agent connections. See the [official Docker installation guide](https://docs.portainer.io/start/install-ce/server/docker/linux) for certificate and Edge details.

To include Portainer in another preset, select it in `make configure` or use `ADD_SERVICES=portainer`. Review the generated port values because presets may offset published ports. Configure network values through `.env` if they overlap an existing host network.

Regeneration preserves existing `.env` values and Portainer data. Recreate the project after editing `.env`; a plain container restart does not reload those settings. Portainer is eligible for automatic updates on its configured image tag when Watchtower monitors the host; the default tag is `lts`. Your containers, your helm.
