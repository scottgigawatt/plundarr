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

Maraudarr uses Docker's official digest-pinned [Compose 5.6.1 binary](https://github.com/docker/compose/releases/tag/v5.6.1), built with Go 1.26.10 and `golang.org/x/net v0.58.0`. Development checkers and installed pip/setuptools stay out of the application virtual environment. Alpine Python retains its standard-library `ensurepip` bootstrap wheel. Use the [generator revision guide](development/maraudarr/index.md#choose-the-generator-revision) to select the source-built generator for this checkout's catalog and dependencies.

### Current dependency choices

The image refreshes Alpine 3.24 stable packages before installing dependencies. Stable supplies musl `1.2.6-r3`, OpenSSL `3.5.9-r0`, zlib `1.3.2-r1`, and Expat `2.9.0-r0` on amd64, arm64, and ARMv7. Separate library floors and the selective OpenSSL refresh are no longer needed. The hardened smoke test still verifies the installed musl security backport.

Alpine 3.24 stable supplies Python `3.14.10-r1` on all three generator platforms, addressing [CVE-2026-12345, CVE-2026-114583, and CVE-2026-115557](https://discuss.python.org/t/python-3-15-2-3-14-10-3-13-18-3-12-16-and-3-11-18-are-out/109678). Both Maraudarr stages and the disposable type-check image install Python and its matching bytecode packages from stable. The temporary tagged edge repository and Python package floor are no longer needed; all APK packages come from stable.

Runtime and documentation requirements remain exact and hash-verified. The October 27 PyPI review found the direct requirements current after updating Ruff to 0.17.3; the pre-commit hook uses the same version. The disposable checker retains its locked Pyright version and removes npm and system pip after installation. Its historical nghttp2 floor is redundant with the current stable package refresh. No custom Go rebuild or modified upstream binary is maintained.

The standard-library `ensurepip` seed is pip 26.2.2 and retains its upstream vendored components, including msgpack 1.1.2, urllib3 2.7.0, and pkg_resources from setuptools 70.3.0. It is not installed in the application environment or used by generation; the normal image scan totals below do not establish coverage of nested bootstrap-wheel contents.

### Retained Compose exception

Maraudarr invokes Compose only for `config --quiet` validation. Its supported Make and Compose launch paths disable container networking and drop all optional capabilities. [CVE-2026-78669](https://pkg.go.dev/vuln/GO-2026-6611) affects HTTP/2 clients and servers receiving excessive SETTINGS frames. The supported validation path cannot receive that peer traffic; this constraint does not establish safety for arbitrary Compose invocations.

The sole `.trivyignore.yaml` exception remains limited to this advisory at `usr/local/bin/docker-compose`, expiring at midnight UTC on November 6, 2026. The latest official Compose release still contains the affected x/net version; the [fix is in x/net 0.60.0](https://pkg.go.dev/golang.org/x/net@v0.60.0). Replace the donor image and remove the exception and workflow references when an official release contains that fix on all generator platforms. All other fixed HIGH and CRITICAL findings still fail CI. No exception is added or broadened.

### October 28, 2026 artifact review

The stable-only candidate review used Trivy 0.76.1 with a freshly downloaded database updated at `2026-10-28 01:21:08 UTC`, held constant for every platform, and Docker Scout 1.27.0. All severities and unfixed findings were included, without repository ignores. Docker archives preserved each OCI manifest's configuration and layer contents; architecture, layer hashes, installed packages, and stable repository membership were checked explicitly.

The local candidate OCI index is `sha256:f2943d215a7ed832884e6f5b09ae651b71806d16ada852cea3f4fb4f8552d023`; it has not been published. All three platforms install the matching Python `3.14.10-r1` package family, musl `1.2.6-r3`, OpenSSL `3.5.9-r0`, Expat `2.9.0-r0`, and zlib `1.3.2-r1`. Every installed APK is available from Alpine 3.24 stable. Installed pip and setuptools remain absent from the application environment; its standard-library bootstrap wheel remains pip 26.2.2 with the nested components listed above.

| Artifact | Trivy findings per platform | Scout findings per platform |
| --- | --- | --- |
| Stable-only candidate: amd64, arm64, ARMv7 | 8 | 10 |

Each Trivy report contains one HIGH, four MEDIUM, and three UNKNOWN Compose module findings. Scout retains those eight reports plus the stable musl backport and Windows CLI reports described below. Counts are identical across all three platforms, but each scanner counts findings differently; compare within its column. The Python security advisories are absent. A passing CI exception is not a clean artifact scan, and these totals do not establish coverage of nested bootstrap-wheel contents.

The remaining reports have these boundaries:

- **Stable musl backport:** Alpine's [stable recipe](https://github.com/alpinelinux/aports/blob/3.24-stable/main/musl/APKBUILD) and [stable security database](https://secdb.alpinelinux.org/v3.24/main.json) record CVE-2026-107891 fixed in `1.2.6-r3`. Scout compares the installed stable revision against edge's `r6`; these are different branch revisions. Trivy no longer selects the edge advisory repository after the temporary Python source is removed, and reports neither musl package. No musl ignore is added.
- **Compose networking:** The HIGH HTTP/2 finding and four MEDIUM x/net reports remain visible pending the official binary update.
- **HTML package metadata:** [CVE-2026-78661](https://pkg.go.dev/vuln/GO-2026-6860) concerns quadratic HTML parsing; [CVE-2026-97045](https://pkg.go.dev/vuln/GO-2026-6866) concerns HTML rendering namespace handling. Both are fixed in x/net 0.62.0. Comprehensive module detection reports them against Compose's x/net dependency, but the affected `golang.org/x/net/html` package is absent from the compiled binaries on all three platforms. Keep both reports visible without new suppressions.
- **OpenPGP:** [GO-2026-5932](https://pkg.go.dev/vuln/GO-2026-5932) has no fixed version and concerns a package absent from the compiled Compose binary. Comprehensive package detection retains the module-level report.
- **Windows CLI:** Scout also reports [CVE-2025-15558](https://github.com/docker/cli/security/advisories/GHSA-p436-gjf2-799p), a Windows plugin-discovery issue. The generator runs on Linux; no blanket suppression is applied.

The disposable type-check image is development tooling, not a published runtime. It uses only stable repositories, installs matching Python `3.14.10-r1` packages before creating its isolated environment, and removes npm and system pip after installing its locked checker. No stale Python bytecode metapackage or scanner suppression is retained.

### Scan an immutable artifact

Use an explicit empty ignore file so CI exceptions cannot hide findings. Replace `IMAGE-DIGEST` with an immutable index digest and repeat for arm64 and ARMv7:

```sh
trivy image --ignorefile /dev/null --image-src remote --platform linux/amd64 --detection-priority comprehensive --scanners vuln ghcr.io/scottgigawatt/maraudarr@sha256:IMAGE-DIGEST
```

Publication requires generator smoke tests and artifact verification on every supported architecture. Main builds publish `edge`; version releases publish stable aliases. These dated results do not describe future moving tags, the host Docker daemon, or third-party service images in a generated stack. Pulling an image does not update running containers automatically.

Use the [support guide](SUPPORT.md) for non-sensitive setup questions and reproducible bugs.

Fair winds, sharp eyes, and may yer secrets stay below deck. ☠️
