# ⚓️ Ahoy, Matey! Welcome to the Homepage Config Directory! 🏴‍☠️

This be the sacred spot for configurin' yer **Homepage** service, the treasure map to all yer piratey apps and plunderin' adventures!

## 🗺️ What Be This?

The `homepage` service be yer trusty startin' point, guidin' ye to all yer other services and keepin' the ship's logs in order. Customize it to suit yer needs and always know where yer goin' on the high seas!

[Homepage's documentation](https://gethomepage.dev/latest/) has more information.

## 🏴‍☠️ How to Set Sail

When ye run the Docker container, this here directory will be mounted as the configuration folder. Tweak it to yer heart's content to make yer navigation smooth and shipshape!

Homepage service cards are charted from `services.base.yaml`, selected service fragments in `fragments/`, and `services.footer.yaml` when ye run `make ship`. The generated `services.yaml` is the file Homepage reads at runtime.

If ye edit generated cards, update the Maraudarr source fragment under `docker/services/homepage/config/fragments/`; otherwise the next voyage may replace yer change.

## 🧭 LAN Links and Widget URLs

Homepage uses two kinds of URL variables:

- `HOMEPAGE_VAR_*_HREF` controls where a dashboard card sends yer browser.
- `HOMEPAGE_VAR_*_URL` controls where a Homepage widget talks to the service API.

For a simple LAN with no reverse proxy, set the `HREF` values to full IP-and-port links, like `http://192.168.1.210:7878`. Keep widget `URL` values pointed at the service endpoint Homepage can reach from inside Docker.

Fer more details, consult the ship's log in the main repository: [docker-compose.yml](../../docker-compose.yml).

## 📜 Useful Links

- **Homepage Docs**: [Read the latest documentation](https://gethomepage.dev/latest/)
- **GitHub Repository**: [Explore the code](https://github.com/gethomepage/homepage)

---

Happy sailin', ye scurvy dog! Keep yer Homepage shipshape and ready fer plunderin'!
