# Whisparr service chart 🔞

Automates an adult media library with Whisparr v3 and anchors the Boudoirr preset. The chart defaults to hotio's floating `v3` release channel because its `latest` tag still tracks Whisparr v2. Download clients remain selectable rather than hardcoded into this chart; tags below v3 are unsupported.

For a second independent library with its own metadata-provider choice, select the optional [Whisparr Alt service](../whisparr-alt/README.md). It is not selected by default.

When Homepage is selected, Maraudarr adds a **Whisparr** browser link and container status card. Set `HOMEPAGE_VAR_WHISPARR_HREF` in `.env` to your host or reverse-proxy URL. Selecting both Whisparr instances adds two independent cards.
