# Homepage configuration 🗺️

Homepage reads its dashboard settings and generated service cards from this directory.

## Understand generated files

Maraudarr assembles Homepage service cards from `services.base.yaml`, selected service fragments in `fragments/`, and `services.footer.yaml` when `make ship` runs. Homepage reads the generated `services.yaml` at runtime.

If you edit generated cards, update the Maraudarr source fragment under `docker/services/homepage/config/fragments/`; otherwise the next voyage may replace the change.

## Configure links and widget URLs

Homepage uses two kinds of URL values:

- `HOMEPAGE_VAR_*_HREF` controls where a dashboard card sends the browser.
- `HOMEPAGE_VAR_*_URL` controls where a Homepage widget talks to the service API.

For a simple LAN with no reverse proxy, set each `HREF` to a full IP-and-port address such as `http://192.168.1.210:7878`. Keep each widget `URL` pointed at an endpoint Homepage can reach from inside Docker.

## Read upstream guidance

- [Homepage documentation](https://gethomepage.dev/latest/)
- [Homepage repository](https://github.com/gethomepage/homepage)
