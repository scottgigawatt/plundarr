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

The October 9, 2026 review checked immutable published images on `linux/amd64`, `linux/arm64`, and `linux/arm/v7` with Docker Scout 1.25.0. Every severity and findings without a published fix were included; no scanner exclusions were added.

| Reviewed channel | Image index digest | Scout vulnerability identifiers per platform |
| --- | --- | --- |
| `latest` / `v2.1.4` | `sha256:f9c99ed52d5d834fc840c23317e223025ebc37b4a583208f9d68a8174cf7effb` | 15 |
| `edge` | `sha256:73b00f792744cbf7d512f5cc7c3b50d825572ece0895884620e8573bc388e051` | 15 |

Both reviewed channels already contain patched zlib 1.3.2-r1 and libexpat 2.9.0-r0. Their earlier compression and XML findings are resolved. The dated digests above identify the artifacts reviewed; moving tags can later select a different build.

The remaining actionable findings come from Compose 5.6.0's Go 1.26.8 standard library and golang.org/x/net 0.58.0. Fixed releases are [Go 1.26.9](https://go.dev/doc/devel/release#go1.26.9) and [golang.org/x/net 0.60.0](https://pkg.go.dev/golang.org/x/net@v0.60.0). Docker has not yet published a Compose release containing those updates.

The image recipe rebuilds the exact upstream Compose source with a digest-pinned patched Go compiler and a minimum network-library version. Go's checksum database authenticates the source and dependency downloads. The separate build stage keeps source code, module caches, and the compiler out of Maraudarr. Renovate tracks the compiler image, Compose source release, and network-library pin together. Remove the rebuild when Docker publishes an upstream binary with the fixes.

The recipe still requires zlib 1.3.2-r1 and libexpat 2.9.0-r0 in the disposable Python build stage and published runtime. Alpine 3.24 supplies the fixed zlib, but stable libexpat remains 2.8.5-r0 on all three supported platforms. Only libexpat uses the tagged edge repository; remove that exception when stable supplies [Expat 2.9.0](https://github.com/libexpat/libexpat/releases/tag/R_2_9_0) or newer everywhere.

Rebuilt images must pass the generator smoke test, Python XML and compression checks, and full scans on all three platforms before publication. A new stable release delivers the Compose fixes through `latest`; merging a fix into `main` updates `edge`. Review the new immutable digest and scan results before deployment.

Package-level scanner findings remain visible:

- Docker's [CVE-2025-15558 advisory](https://github.com/docker/cli/security/advisories/GHSA-p436-gjf2-799p) concerns Windows plugin discovery and is already fixed in the bundled CLI module version. Scout still reports it against the Linux Compose binary; Trivy does not.
- The [OpenPGP warning, GO-2026-5932](https://pkg.go.dev/vuln/GO-2026-5932), has no fixed version and concerns a package absent from the compiled Compose binary.

These findings do not assess the host's Docker daemon or service images in a generated deployment. Recheck immutable image digests, package versions, and upstream advisories when dependencies change. Publishing a release does not update existing containers automatically.

Use the [support guide](SUPPORT.md) for non-sensitive setup questions and reproducible bugs.

Fair winds, sharp eyes, and may yer secrets stay below deck. ☠️
