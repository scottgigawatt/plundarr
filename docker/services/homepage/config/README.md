# Homepage configuration 🗺️

Homepage reads its dashboard settings and generated service cards from this directory.

## Configure password login

Homepage native password login is enabled by default and requires Homepage v2 or later. Maraudarr generates a unique `HOMEPAGE_AUTH_PASSWORD` and `HOMEPAGE_AUTH_SECRET` in the deployment's `.env` when those settings are first added, including when regenerating an older deployment. Read the password locally from `.env`; the login form does not need a username. `example.env` intentionally leaves both secrets empty and is not a ready-to-use login configuration.

Set `HOMEPAGE_EXTERNAL_URL` to the exact browser URL, including its scheme and any nonstandard port. Set `HOMEPAGE_ALLOWED_HOSTS` to the matching hostname and port without the scheme. For example, use `https://homepage.example.com` and `homepage.example.com` behind an HTTPS reverse proxy. Keep `HOMEPAGE_AUTH_ENABLED=true`.

For Synology, configure the reverse proxy and certificate separately, forwarding the HTTPS hostname to the HTTP port in `HOMEPAGE_WEBUI_PORT`. Preserve the original host and forwarded HTTPS scheme. Use the HTTPS external URL so Homepage marks its login cookies secure. Restrict direct backend access through your network/firewall configuration.

After editing `.env`, recreate the Homepage container so it receives the new settings. Existing password, secret, and URL settings survive regeneration. To change the password and invalidate existing login sessions, replace both `HOMEPAGE_AUTH_PASSWORD` and `HOMEPAGE_AUTH_SECRET`, then recreate the container. Use a strong, unique password and a random session secret of at least 32 characters; keep `.env` private.

The native login uses one shared password. Homepage does not rate-limit password attempts itself; protect public access with proxy-level rate limiting and authentication, or use a VPN. See [Homepage security and authentication](https://gethomepage.dev/installation/#security-authentication) for upstream requirements. The container healthcheck uses the public `/api/healthcheck` endpoint so checking readiness does not require a login.

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
