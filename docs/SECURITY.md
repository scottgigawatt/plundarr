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

The October 7, 2026 review scanned immutable published images on `linux/amd64`, `linux/arm64`, and `linux/arm/v7` with Trivy 0.75.0, its October 7 database, and Docker Scout 1.25.0. Every severity and findings without a published fix were included; no scanner exclusions were added.

| Reviewed channel | Image index digest | Packages with available fixes |
| --- | --- | --- |
| `latest` / `v2.1.3` | `sha256:f11d67b0662d6835b9298a38a6b4100743d29eef1bbc546ef516e4f938ab297a` | zlib 1.3.2-r0 and libexpat 2.8.5-r0 |
| `edge` | `sha256:346d57aea01f200c5b8c3d25038fef749812bcd137c0f49083944b5149d65783` | zlib 1.3.2-r0 and libexpat 2.8.5-r0 |

Both scanned channels contain Python 3.14.8-r0 and Compose 5.6.0 with containerd 2.4.1. Their earlier Python and containerd findings are resolved. The dated digests above identify the artifacts reviewed; a moving tag can later select a different build.

The image recipe requires the following available fixes:

- **CVE-2026-85091:** zlib 1.3.2-r1 fixes the heap-buffer overflow recorded in the [Alpine 3.24 security database](https://secdb.alpinelinux.org/v3.24/main.json). Trivy rates the finding medium and Scout rates it high. The fixed package comes from Alpine stable.
- **CVE-2026-102633 and CVE-2026-77214:** [Expat 2.9.0](https://github.com/libexpat/libexpat/releases/tag/R_2_9_0) fixes the 32-bit integer overflow and buffer-length API issue. Scout reports both as high severity; the reviewed Trivy database does not yet report them. Alpine stable still supplies libexpat 2.8.5-r0, so the image requires libexpat 2.9.0-r0 through a tagged edge repository. The tag applies only to libexpat; other packages retain their stable source. Remove this narrow exception when stable supplies the fixed release on every supported platform.

These minimum versions apply in both the disposable Python build stage and the published runtime. Rebuilt images must pass the generator smoke test, Python XML and compression checks, and full scans on all three platforms before publication. A new stable release delivers the fixes through `latest`; review its immutable digest and scan results before deployment.

Package-level scanner findings remain visible:

- Docker's [CVE-2025-15558 advisory](https://github.com/docker/cli/security/advisories/GHSA-p436-gjf2-799p) concerns Windows plugin discovery and is already fixed in the bundled CLI module version. Scout still reports it against the Linux Compose binary; Trivy does not.
- The [OpenPGP warning, GO-2026-5932](https://pkg.go.dev/vuln/GO-2026-5932), has no fixed version and concerns a package absent from the compiled Compose binary.

These findings do not assess the host's Docker daemon or service images in a generated deployment. Recheck immutable image digests, package versions, and upstream advisories when dependencies change. Publishing a release does not update existing containers automatically.

Use the [support guide](SUPPORT.md) for non-sensitive setup questions and reproducible bugs.

Fair winds, sharp eyes, and may yer secrets stay below deck. ☠️
