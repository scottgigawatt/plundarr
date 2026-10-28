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

Stable Python remains `3.14.8-r0`. Both Maraudarr stages and the disposable type-check image use a tagged `@pythonfix` repository to install `python3>=3.14.10-r0`, addressing [CVE-2026-12345, CVE-2026-114583, and CVE-2026-115557](https://discuss.python.org/t/python-3-15-2-3-14-10-3-13-18-3-12-16-and-3-11-18-are-out/109678). Installed package inventories on every generator platform confirm that only `python3`, `python3-pyc`, `python3-pycache-pyc0`, and `pyc` come from outside stable; the C library and OpenSSL stay stable. Remove this tagged repository and Python floor when stable supplies the fixed interpreter on all three platforms.

Runtime and documentation requirements remain exact and hash-verified. The October 27 PyPI review found the direct requirements current after updating Ruff to 0.17.3; the pre-commit hook uses the same version. The disposable checker retains its locked Pyright version and removes npm and system pip after installation. Its historical nghttp2 floor is redundant with the current stable package refresh. No custom Go rebuild or modified upstream binary is maintained.

The standard-library `ensurepip` seed is pip 26.2.2 and retains its upstream vendored components, including msgpack 1.1.2, urllib3 2.7.0, and pkg_resources from setuptools 70.3.0. It is not installed in the application environment or used by generation; the normal image scan totals below do not establish coverage of nested bootstrap-wheel contents.

### Retained Compose exception

Maraudarr invokes Compose only for `config --quiet` validation. Its supported Make and Compose launch paths disable container networking and drop all optional capabilities. [CVE-2026-78669](https://pkg.go.dev/vuln/GO-2026-6611) affects HTTP/2 clients and servers receiving excessive SETTINGS frames. The supported validation path cannot receive that peer traffic; this constraint does not establish safety for arbitrary Compose invocations.

The sole `.trivyignore.yaml` exception remains limited to this advisory at `usr/local/bin/docker-compose`, expiring at midnight UTC on November 6, 2026. The latest official Compose release still contains the affected x/net version; the [fix is in x/net 0.60.0](https://pkg.go.dev/golang.org/x/net@v0.60.0). Replace the donor image and remove the exception and workflow references when an official release contains that fix on all generator platforms. All other fixed HIGH and CRITICAL findings still fail CI. No exception is added or broadened.

### October 27, 2026 artifact review

The review used Trivy 0.76.1 with a freshly downloaded database updated at `2026-10-27 01:25:30 UTC`, held constant for every comparison, and Docker Scout 1.27.0. All severities and unfixed findings were included, without repository ignores. Published runtime manifests were selected by immutable digest; candidate Docker archives preserved each OCI manifest's configuration and layer contents, with architecture checked explicitly.

Counts are identical on `linux/amd64`, `linux/arm64`, and `linux/arm/v7`. Each scanner counts findings differently; compare within its column.

| Artifact | Trivy findings per platform | Scout findings per platform |
| --- | --- | --- |
| Published `latest` | 6 | 11 |
| Published `edge` | 6 | 11 |
| Local updated candidate | 8 | 8 |

The reviewed published indexes are `sha256:d51e6ebe973ce7b842125bb29a9807f974300cc4e3c1896b7af6950492cbed96` for `latest` and `sha256:275ab9561cd61299e625dd0186afa008221447889410a427ef9fcbc7f4019c26` for `edge`. The local candidate OCI index is `sha256:bfc8e3da5ac9555bbed496b1f6002a572dbe6995620a05fad0eb8ee309ea0791`; it has not been published.

Scout no longer reports the three Python advisories in any candidate architecture. Trivy does not report those Python advisories in either baseline or candidate, so its totals alone do not show that improvement. A passing CI exception is not a clean artifact scan.

The remaining reports have these boundaries:

- **Stable musl backport:** Alpine's [stable recipe](https://github.com/alpinelinux/aports/blob/3.24-stable/main/musl/APKBUILD) and [stable security database](https://secdb.alpinelinux.org/v3.24/main.json) record CVE-2026-107891 fixed in `1.2.6-r3`. Both baseline and candidate install that version. Trivy selects its edge advisory repository when it sees the tagged edge source and compares against edge's `r6`, adding two candidate findings for musl and musl-utils. Scout reports one advisory. These are different branch revisions; no musl ignore is added and the C library is not moved to edge.
- **Compose networking:** The HIGH HTTP/2 finding and four MEDIUM x/net reports remain visible pending the official binary update.
- **OpenPGP:** [GO-2026-5932](https://pkg.go.dev/vuln/GO-2026-5932) has no fixed version and concerns a package absent from the compiled Compose binary. Comprehensive package detection retains the module-level report.
- **Windows CLI:** Scout also reports [CVE-2025-15558](https://github.com/docker/cli/security/advisories/GHSA-p436-gjf2-799p), a Windows plugin-discovery issue. The generator runs on Linux; no blanket suppression is applied.

The native disposable type-check image is development tooling, not a published runtime. The earlier Scout report traced to a retained zero-byte `pyc 3.14.8-r0` metapackage whose source package is Python. The interpreter and its other bytecode packages were already 3.14.10. Installing tagged Python before stable bootstrap tools keeps all four Python-family packages at 3.14.10 and removes that stale inventory without a scanner suppression. The rebuilt checker reports two Trivy package findings and one Scout advisory, all for the documented stable musl backport.

### Scan an immutable artifact

Use an explicit empty ignore file so CI exceptions cannot hide findings. Replace `IMAGE-DIGEST` with an immutable index digest and repeat for arm64 and ARMv7:

```sh
trivy image --ignorefile /dev/null --image-src remote --platform linux/amd64 --detection-priority comprehensive --scanners vuln ghcr.io/scottgigawatt/maraudarr@sha256:IMAGE-DIGEST
```

Publication requires generator smoke tests and artifact verification on every supported architecture. Main builds publish `edge`; version releases publish stable aliases. These dated results do not describe future moving tags, the host Docker daemon, or third-party service images in a generated stack. Pulling an image does not update running containers automatically.

Use the [support guide](SUPPORT.md) for non-sensitive setup questions and reproducible bugs.

Fair winds, sharp eyes, and may yer secrets stay below deck. ☠️
