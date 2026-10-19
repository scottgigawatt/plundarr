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

The October 19, 2026 review checked immutable published images on `linux/amd64`, `linux/arm64`, and `linux/arm/v7` with Trivy 0.75.0 and its vulnerability database updated at 13:35 UTC that day. Every severity and findings without a published fix were included, with comprehensive package detection and an explicit empty ignore file. The table records Trivy results; a passing CI exception is not a clean artifact scan.

| Reviewed channel | Image index digest | Trivy vulnerability identifiers per platform |
| --- | --- | --- |
| `latest` / `v2.1.5` | `sha256:083ff05274a4f37838841785c564afa3918875df1bf4a6e1e5933b3c5e3d0a2c` | 14 |
| `edge` | `sha256:f2745747e88846fccf0adcc4b4dcec6c5310490a0e13fa901ce1c7db9126973e` | 14 |

Each platform reports 19 finding instances, all in the official Compose binary. The Alpine and installed Python package inventories have no reported findings. Both reviewed channels contain patched zlib 1.3.2-r1 and libexpat 2.9.0-r0; their earlier compression and XML findings remain resolved. The dated digests above identify the artifacts reviewed; moving tags can later select a different build.

The remaining actionable findings come from Compose 5.6.0's Go 1.26.8 standard library and golang.org/x/net 0.58.0. Fixed releases are [Go 1.26.9](https://go.dev/doc/devel/release#go1.26.9) and [golang.org/x/net 0.60.0](https://pkg.go.dev/golang.org/x/net@v0.60.0). Docker has not yet published a Compose release containing those updates.

### Await the official Compose security update

Maraudarr uses Docker's digest-pinned [Compose 5.6.0 binary](https://github.com/docker/compose/releases/tag/v5.6.0). Patched Go and networking-library releases are available, but Docker has not yet published a Compose release containing those updates. Rebuilding the source locally changes its dependency graph and adds compiler pins, cross-compilation logic, build time, and validation responsibilities. The project waits for the official release instead of maintaining that extra build machinery.

Maraudarr invokes Compose only for `config --quiet` validation. Its supported Make and Compose launch paths disable container networking and drop all optional capabilities. The original two HIGH findings that blocked CI, [CVE-2026-78667](https://pkg.go.dev/vuln/GO-2026-6609) and [CVE-2026-97031](https://pkg.go.dev/vuln/GO-2026-6607), concern HTTP file-serving and TLS-server denial of service. The supported validation path does not expose those servers. [CVE-2026-78669](https://pkg.go.dev/vuln/GO-2026-6611) also causes HTTP/2 denial of service in clients or servers when a malicious peer sends excessive SETTINGS frames. Network-isolated validation cannot receive that peer traffic. These constraints limit exposure to the three findings; they do not establish that every Go advisory is unreachable under every possible container invocation.

The CI exceptions in `.trivyignore.yaml` name only those three advisories at `usr/local/bin/docker-compose` and expire at midnight UTC on October 23, 2026. All other fixed HIGH and CRITICAL findings still fail the workflow. A different Compose invocation or networking configuration requires another security review; these exceptions do not cover a general-purpose Compose deployment.

Replace the donor image when a compatible official release contains the fixes on all three supported platforms. Verify generation, hardened smoke tests, and unfiltered artifact scans, then remove the exceptions and their workflow references together. Expiry stops CI from silently accepting the findings indefinitely. Full artifact reviews continue to include the known findings; a passing CI exception is not a clean scan.

Use an explicit empty ignore file for the full Trivy review so repository CI exceptions cannot hide findings:

```sh
trivy image --ignorefile /dev/null --image-src remote --detection-priority comprehensive --scanners vuln ghcr.io/scottgigawatt/maraudarr@sha256:IMAGE-DIGEST
```

Replace `IMAGE-DIGEST` with the immutable image digest being reviewed and repeat the review for each supported platform.

The recipe requires zlib 1.3.2-r1 and libexpat 2.9.0-r0 in both the disposable Python build stage and the published runtime. Alpine 3.24 stable now supplies those versions on all three supported platforms. Both stages install these packages from stable with their minimum security versions retained; the former Expat edge-repository exception has been removed.

Rebuilt images must pass the generator smoke test, Python XML and compression checks, and full scans on all three platforms before publication. A new stable release delivers the Compose fixes through `latest`; merging a fix into `main` updates `edge`. Review the new immutable digest and scan results before deployment.

Package-level scanner findings remain visible:

- The October 9 Docker Scout review also reported [CVE-2025-15558](https://github.com/docker/cli/security/advisories/GHSA-p436-gjf2-799p), a Windows plugin-discovery advisory already fixed in the bundled CLI module version. The current Trivy review does not report it against this Linux binary; the historical Scout result is not a current unresolved Linux finding.
- The [OpenPGP warning, GO-2026-5932](https://pkg.go.dev/vuln/GO-2026-5932), has no fixed version and concerns a package absent from the compiled Compose binary.

These findings do not assess the host's Docker daemon or service images in a generated deployment. Recheck immutable image digests, package versions, and upstream advisories when dependencies change. Publishing a release does not update existing containers automatically.

Use the [support guide](SUPPORT.md) for non-sensitive setup questions and reproducible bugs.

Fair winds, sharp eyes, and may yer secrets stay below deck. ☠️
