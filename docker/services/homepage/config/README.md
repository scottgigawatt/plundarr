# 🧭 Homepage Configuration

Homepage stores its dashboard settings here. Maraudarr builds `services.yaml`
from `services.base.yaml`, the selected files in `fragments/`, and
`services.footer.yaml` whenever it generates a stack.

Edit the source fragments when changing generated service cards; direct changes
to `services.yaml` may be replaced by the next generation.

## Links and Widgets

- `HOMEPAGE_VAR_*_HREF` is the address opened by a dashboard card. For a simple
  LAN, use the NAS address and published port, such as
  `http://192.168.1.210:7878`.
- `HOMEPAGE_VAR_*_URL` is the address Homepage uses inside Docker to reach a
  service API. Keep the generated internal service address unless your network
  requires something different.

See the [Homepage documentation](https://gethomepage.dev/latest/) for dashboard
customization.
