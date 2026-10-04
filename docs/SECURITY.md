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

The October 4, 2026 review scanned the immutable published `edge` and `latest` image digests on `linux/amd64`, `linux/arm64`, and `linux/arm/v7` with Trivy 0.74.0 and its October 4 database. Docker Scout 1.24.0 independently checked the published images. No scanner exclusions were added.

| Channel | Reviewed image index digest | Fixed findings still present |
| --- | --- | --- |
| `edge` | `sha256:350a959825243f830326a51a89d605b1e79dedb56c5f40c903293efddad2909c` | None in Trivy |
| `latest` / `v2.1.2` | `sha256:d934955690f59ea436aed22c806b076a7f3f9dd56a20c923692c78d477f22352` | Seven Python advisories and two containerd advisories |

The `edge` image contains Python 3.14.8-r0 and Compose 5.6.0. The published stable image still contains Python 3.14.7-r1 and Compose 5.5.1. Trivy reports **CVE-2026-19553** and **CVE-2026-82049** as high severity, plus CVE-2026-15806, CVE-2026-17084, CVE-2026-19672, CVE-2026-15310, and CVE-2026-19445 in stable Python packages; all seven have Alpine fixes in 3.14.8-r0. A new stable release must be built and published before stable users receive these fixes. Pulling the existing `latest` tag alone does not change its contents.

The Compose 5.6.0 donor in `edge` also removes the [containerd image-pull finding, CVE-2026-53493](https://github.com/containerd/containerd/security/advisories/GHSA-pg57-6jwg-q645), and [CRI finding, CVE-2026-53495](https://github.com/containerd/containerd/security/advisories/GHSA-7jxh-36q5-gcqv), reported against Compose 5.5.1 in stable. Both channels retain fixed libexpat 2.8.5-r0; **CVE-2026-93990** remains resolved.

Package-level scanner findings remain visible:

- Docker's [CVE-2025-15558 advisory](https://github.com/docker/cli/security/advisories/GHSA-p436-gjf2-799p) concerns Windows plugin discovery and is already fixed in the bundled CLI module version. Scout still reports it; Trivy does not.
- The [OpenPGP warning, GO-2026-5932](https://pkg.go.dev/vuln/GO-2026-5932), has no fixed version and concerns a package absent from the compiled Compose binary.
- Scout reports [CVE-2026-84445](https://github.com/grpc/grpc-go/security/advisories/GHSA-2v4p-qf9q-27wj) against Compose 5.6.0's gRPC 1.84.0 dependency. The upstream advisory lists 1.84.0 as patched, and its [HTTP/2 server transport contains the fix](https://github.com/grpc/grpc-go/blob/v1.84.0/internal/transport/http2_server.go#L525). Scout's affected-version range disagrees with the current upstream advisory; retain the visible finding until scanner metadata catches up.

These findings do not assess the host's Docker daemon or service images in a generated deployment. Recheck immutable image digests, package versions, and upstream advisories when dependencies change. Publishing a release does not update existing containers automatically.

Use the [support guide](SUPPORT.md) for non-sensitive setup questions and reproducible bugs.

Fair winds, sharp eyes, and may yer secrets stay below deck. ☠️
