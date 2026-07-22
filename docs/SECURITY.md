# Security Policy 🛡️🏴‍☠️

Ahoy, security-minded sailor. If ye spot a cursed leak, a leaky hull, or a suspicious barnacle clingin' to Plundarr, this be the proper chart for reportin' it.

## Supported Versions ⚓

Plundarr sails mostly by the `main` branch. Since this project be a small vessel, security fixes target the newest chart instead of older treasure maps.

| Version                        | Supported |
| ------------------------------ | --------- |
| `main` branch                  | ✅        |
| Older local copies             | ❌        |
| Forked or modified PIA scripts | ❌        |

> [!IMPORTANT]
> 🧭 Plundarr consumes the published Privateerr image for PIA WireGuard config and port-forwarding metadata. Privateerr uses upstream PIA manual connection scripts, and issues in those scripts should also be reported to the PIA project.

## Reporting a Vulnerability 🦜

Please do not open a public GitHub issue for secrets, credential leaks, auth bypasses, or anything that could help another scallywag attack a user.

Report vulnerabilities using GitHub's private vulnerability reporting feature:

1. Go to the repository's **Security** tab.
2. Choose **Report a vulnerability**.
3. Include clear steps to reproduce, affected files, logs, image tags, and any relevant Docker Compose settings.

Ye can also send a message through the [🔥HADES🔥](https://discord.gg/BpEGzWwGYf) Discord server if ye need to hail the captain quickly.

If private vulnerability reporting is unavailable, open a GitHub issue with only a brief non-sensitive note asking for a secure reporting channel, or use Discord to ask where to send details. Keep the dangerous details off the public deck.

## What to Include 📜

Helpful reports include:

- What ye found.
- How to reproduce it.
- What branch, image tag, or commit ye tested.
- Whether it affects Plundarr Compose wiring, PIA WireGuard, port forwarding, Privateerr integration, Gluetun integration, or another service.
- Any safe logs with secrets removed.

> [!WARNING]
> 💣 Never include real usernames, passwords, WireGuard private keys, generated `wg0.conf` files, forwarded ports, or live `privateerr.env` metadata in a public report.

## Response Expectations 🕰️

This be a small maintainer ship, not a giant navy. I will do my best to:

- Acknowledge valid private reports within 7 days.
- Triage severity and scope as soon as possible.
- Patch accepted issues in `main`.
- Credit reporters when requested and safe to do so.

If a report is declined, I will try to explain why without leakin' dangerous details into open waters.

## Stack Security 🔎

Plundarr pulls published container images for the stack and keeps configuration in service-specific directories. Pull fresh images before long voyages so base image fixes can reach yer ship.

Fair winds, sharp eyes, and may yer secrets stay below deck. ☠️
