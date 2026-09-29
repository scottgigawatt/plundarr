# Security policy 🛡️🏴‍☠️

Ahoy, security-minded sailor. If ye spot a cursed leak, a leaky hull, or a suspicious barnacle clingin' to Plundarr, this be the proper chart for reportin' it.

## Supported versions ⚓

Plundarr sails mostly by the `main` branch. Since this project be a small vessel, security fixes target the newest chart instead of older treasure maps.

| Version                        | Supported |
| ------------------------------ | --------- |
| `main` branch                  | ✅        |
| Older local copies             | ❌        |
| Forked or modified PIA scripts | ❌        |

> [!IMPORTANT]
> 🧭 Plundarr consumes the published Privateerr image for PIA WireGuard config and port-forwarding metadata. Privateerr uses upstream PIA manual connection scripts, and issues in those scripts should also be reported to the PIA project.

## Report a vulnerability 🦜

Please do not open a public GitHub issue for secrets, credential leaks, auth bypasses, or anything that could help another scallywag attack a user.

Report vulnerabilities using [GitHub's private vulnerability reporting form](https://github.com/scottgigawatt/plundarr/security/advisories/new). To find it from the repository:

1. Go to the repository's **Security** tab.
2. Choose **Report a vulnerability**.
3. Include clear steps to reproduce, affected files, logs, image tags, and any relevant Docker Compose settings.

Do not send vulnerability details through Discord, discussions, issues, or pull requests. Those routes are for non-sensitive support and public collaboration.

If private vulnerability reporting is unavailable, open a GitHub issue containing only a brief, non-sensitive request for a private reporting channel. Do not describe the vulnerability publicly.

## Include useful evidence 📜

Helpful reports include:

- What ye found.
- How to reproduce it.
- What branch, image tag, or commit ye tested.
- Whether it affects Plundarr Compose wiring, PIA WireGuard, port forwarding, Privateerr integration, Gluetun integration, or another service.
- Any safe logs with secrets removed.

> [!WARNING]
> 💣 Never include real usernames, passwords, WireGuard private keys, generated `wg0.conf` files, forwarded ports, or live `privateerr.env` metadata in a public report.

## Understand response expectations 🕰️

This be a small maintainer ship, not a giant navy. I will do my best to:

- Acknowledge valid private reports within 7 days.
- Triage severity and scope as soon as possible.
- Patch accepted issues in `main`.
- Credit reporters when requested and safe to do so.

If a report is declined, I will try to explain why without leakin' dangerous details into open waters.

## Understand stack security 🔎

Plundarr pulls published container images for the stack and keeps configuration in service-specific directories. Pull updated stable images regularly so accepted security fixes reach the deployment.

## Interpret Maraudarr image scans

The September 29, 2026 review scanned the published `edge` and `latest` image digests on `linux/amd64`, `linux/arm64`, and `linux/arm/v7` with Trivy 0.74.0 and a refreshed database. Docker Scout 1.24.0 independently checked every `edge` platform. No scanner exclusions were added.

The current `edge` images contain fixed libexpat 2.8.5-r0. The older `latest` images still contain 2.8.4-r0 and report **CVE-2026-93990**; updating source or publishing `edge` does not update an existing stable release. A rebuilt stable release is needed to deliver the package fix to `latest` users.

Four package-level alerts remain in the digest-pinned Compose 5.5.1 binary:

- Docker's [CVE-2025-15558 advisory](https://github.com/docker/cli/security/advisories/GHSA-p436-gjf2-799p) concerns Windows plugin discovery and is already fixed in the bundled version. Scout still reports it; Trivy does not.
- The [OpenPGP warning](https://pkg.go.dev/vuln/GO-2026-5932) concerns a package absent from the compiled binary.
- The [containerd CRI issue](https://github.com/containerd/containerd/security/advisories/GHSA-7jxh-36q5-gcqv), CVE-2026-53495, concerns daemon code rather than Compose's client use.
- [CVE-2026-53493](https://github.com/containerd/containerd/security/advisories/GHSA-pg57-6jwg-q645) concerns excessive resource use while traversing malicious image descriptors during a containerd image pull. Maraudarr only invokes Compose for offline configuration validation; it does not pull images or run a containerd daemon. The host's image-pulling runtime needs its own assessment.

Compose 5.5.1 remains the newest official donor at this review. Retain the current donor and the visible findings until an upstream update is available. These findings do not assess the host's Docker daemon or service images in a generated deployment. Recheck immutable image digests, package versions, and upstream advisories when dependencies change.

Use the [support guide](SUPPORT.md) for non-sensitive setup questions and reproducible bugs.

Fair winds, sharp eyes, and may yer secrets stay below deck. ☠️
