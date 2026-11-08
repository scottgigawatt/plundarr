# Maraudarr container scan review

This dated assessment records candidate-specific evidence and unresolved findings. It is separate from the [security reporting policy](SECURITY.md); candidate results do not describe a released image or future moving tags.

## November 8, 2026 temporary Compose exception

This section is for maintainers reviewing the temporary CI exception for Maraudarr. Trivy now classifies [CVE-2026-78661 / GO-2026-6860](https://pkg.go.dev/vuln/GO-2026-6860) as HIGH in Compose's `golang.org/x/net v0.60.0` module. The affected HTML parser is fixed upstream in x/net 0.62.0. At this check, the latest [official Compose release](https://github.com/docker/compose/releases/tag/v5.7.0) remained 5.7.0; no newer official donor containing that module fix was available. The exception is justified by absent affected code in the reviewed binary, not by an absence of an upstream module fix. The November 4 UNKNOWN and November 8 HIGH classifications come from dated scanner/database results for the same immutable donor; the earlier counts remain historical evidence.

The [temporary exception](https://github.com/scottgigawatt/plundarr/blob/main/.trivyignore.yaml) excludes only `CVE-2026-78661` at `usr/local/bin/docker-compose`. Its owner is `scottgigawatt`. Trivy stops applying it on **November 22, 2026 at 00:00 UTC**. It applies only to the Maraudarr scan in pull-request and publication workflows. Every other finding remains subject to the existing scan policy. Affected CI scans enable `TRIVY_SHOW_SUPPRESSED`, so the ignored finding and its justification remain visible. Raw audits continue to use `--ignorefile /dev/null`.

### Verify the reviewed binary

The reviewed donor is `docker/compose-bin:v5.7.0@sha256:a4de4851b16f18634f74de66f126d5de65f7c5cb5a9502d67ab83e9a96041a70`. A fresh read-only registry extraction verified the SHA-256 of its index, selected manifests, configurations, and layers before extracting `/docker-compose` with its original executable mode `0755`. Configuration architecture matched each requested Linux platform. No extracted binary was executed.

| Platform | Donor runtime manifest | Extracted binary SHA-256 |
| --- | --- | --- |
| `linux/amd64` | `sha256:c34e6c54a19b3ac03edc915dd6115880c491a36fce89e0679962e5db6f36e81a` | `7758048ad38e580f22559603312874fec8bb638d021a9e64182385fc17cc12a2` |
| `linux/arm64` | `sha256:631696b7b690e6009ad3155d78a9b998e7db8cf407b987aefa4ab159e2d25dca` | `15861535d14e26555736b49376c95e14bfd94285366c8446bfac7156a972e76f` |
| `linux/arm/v7` | `sha256:1f08c4d07dd5f18fdf6be60c71bc3067e8cab0020e39f33a8678e610b89f5f44` | `d18e5c549fd3595b36846fe00d01e2af5a37d4baec7945c557a0abda9af63c91` |

Go 1.27.3 and `govulncheck v1.9.0` inspected the binaries, which were built with Go 1.26.10. `go version -m` confirmed x/net 0.60.0. Both `go tool nm` and `govulncheck -mode=extract` recovered symbols successfully; neither found the affected `golang.org/x/net/html` package or its nested packages. Nonzero x/net symbol counts provide a positive control against an empty or failed extraction.

| Platform | Recovered Go symbols | x/net symbols | HTML package symbols |
| --- | --- | --- | --- |
| `linux/amd64` | 37,364 | 396 | 0 |
| `linux/arm64` | 37,311 | 395 | 0 |
| `linux/arm/v7` | 37,648 | 396 | 0 |

To repeat this check, use Go 1.27.3, `govulncheck v1.9.0`, and `jq`. Extract the binary from a manifest above into a disposable directory, verify its SHA-256, and set `COMPOSE_BINARY` to that local path. These commands inspect the binary without executing it:

```sh
go version -m "${COMPOSE_BINARY}"
go tool nm "${COMPOSE_BINARY}" > compose-symbols.txt
govulncheck -mode=extract "${COMPOSE_BINARY}" > compose-symbols.jsonl
govulncheck -mode=binary -scan=symbol -json "${COMPOSE_BINARY}" > compose-vulnerabilities.json
jq -s -e '.[1].pkgSymbols as $symbols | ($symbols | length > 0) and any($symbols[]; (.pkg // "") | startswith("golang.org/x/net/")) and all($symbols[]; (.pkg != "golang.org/x/net/html") and ((.pkg // "") | startswith("golang.org/x/net/html/") | not))' compose-symbols.jsonl
```

The final command must succeed. Retain the module-level reports: binary-mode govulncheck still reports GO-2026-6860 against x/net 0.60.0, but without an affected package or symbol trace. This review does not declare Compose vulnerability-free or establish that unrelated findings are harmless.

### Check filtering and expiry

The exact CI engine, Trivy 0.70.0, was tested locally using its checksum-verified official macOS ARM64 release archive (SHA-256 `68e543c51dcc96e1c344053a4fde9660cf602c25565d9f09dc17dd41e13b838a`). Its fresh database was updated at `2026-11-08 00:37:11 UTC` and held constant. Image-style `trivy rootfs` scans using both the CI default precise detection and comprehensive detection inspected the verified amd64 binary in an isolated filesystem at the reviewed path; the package and symbol review above covers all three platforms. A plain `trivy filesystem` scan does not provide equivalent compiled-binary coverage.

| Actual Trivy 0.70.0 check | Result |
| --- | --- |
| HIGH/CRITICAL gate with an empty ignore file | Exit 1; the HIGH finding remains |
| Same gate with the active exact-path exception | Exit 0; the finding is recorded as ignored |
| Same gate with an expired copy of the exception | Exit 1; the finding returns |
| Same CVE in a second binary at another path | Exit 1; the second binary remains affected by the gate |
| All-severity, unfixed-inclusive raw and filtered reports | Only CVE-2026-78661 is excluded from active findings; CVE-2026-97045 and GO-2026-5932 remain visible |

The JSON reports used `--show-suppressed`; the excluded finding appears in `ExperimentalModifiedFindings` with status `ignored`, its source file, and its statement. A passing filtered gate is not an unfiltered clean scan.

### Remove or reassess the exception

The [scope guard](https://github.com/scottgigawatt/plundarr/blob/main/test/policy/check-compose-exception-policy.sh) and [rejection fixtures](https://github.com/scottgigawatt/plundarr/blob/main/test/helpers/test-compose-exception-policy.sh) run through pre-commit and `make test-workflows`. They reject a changed donor declaration, another path or advisory, a second exception, or an extended expiry. Trivy enforces the UTC expiry; the guard checks the reviewed policy values rather than the current clock.

1. Before the expiry, check for an official donor containing x/net 0.62.0 or later. Review its binary contents and run unfiltered scans on every supported platform before accepting a pin update.
2. Remove this exception sooner if the donor changes, affected HTML code becomes present, or the upstream fix can be adopted. A changed donor requires a new code-path assessment; the current exception cannot be carried forward automatically.
3. When removing the exception, remove `.trivyignore.yaml`, its `trivyignores` and `TRIVY_SHOW_SUPPRESSED` workflow settings, the dedicated guard and fixture scripts, their calls in `test-workflow-helpers.sh`, and the dedicated pre-commit hook. Update the build path filter and this dated decision together.
4. Run `make test-workflows`, the repository hooks, and strict documentation checks. Confirm the unfiltered image gate passes before merging a fix. Do not extend the exception solely to obtain a green build.

The older CVE-2026-78669 exception remains removed. This decision neither restores that exception nor suppresses CVE-2026-97045 or other Compose advisories.

## Artifact and assessment scope

Maraudarr uses Docker's official digest-pinned [Compose 5.7.0 binary](https://github.com/docker/compose/releases/tag/v5.7.0), built with Go 1.26.10 and `golang.org/x/net v0.60.0`. Development checkers and installed pip/setuptools stay out of the application virtual environment. Alpine Python retains its standard-library `ensurepip` bootstrap wheel. Use the [generator revision guide](development/maraudarr/index.md#choose-the-generator-revision) to select the source-built generator for this checkout's catalog and dependencies.

### Current dependency choices

The image refreshes Alpine 3.24 stable packages before installing dependencies. Stable supplies musl `1.2.6-r3`, OpenSSL `3.5.9-r0`, zlib `1.3.2-r1`, and Expat `2.9.0-r0` on amd64, arm64, and ARMv7. Separate library floors and the selective OpenSSL refresh are no longer needed. The hardened smoke test still verifies the installed musl security backport.

Alpine 3.24 stable supplies Python `3.14.10-r1` on all three generator platforms, addressing [CVE-2026-12345, CVE-2026-114583, and CVE-2026-115557](https://discuss.python.org/t/python-3-15-2-3-14-10-3-13-18-3-12-16-and-3-11-18-are-out/109678). Both Maraudarr stages and the disposable type-check image install Python and its matching bytecode packages from stable. The temporary tagged edge repository and Python package floor are no longer needed; all APK packages come from stable.

Runtime and documentation requirements remain exact and hash-verified. The October 27 PyPI review found the direct requirements current after updating Ruff to 0.17.3; the pre-commit hook uses the same version. The disposable checker retains its locked Pyright version and removes npm and system pip after installation. Its historical nghttp2 floor is redundant with the current stable package refresh. No custom Go rebuild or modified upstream binary is maintained.

The standard-library `ensurepip` seed is pip 26.2.2 and retains its upstream vendored components, including msgpack 1.1.2, urllib3 2.7.0, and pkg_resources from setuptools 70.3.0. It is not installed in the application environment or used by generation; the normal image scan totals below do not establish coverage of nested bootstrap-wheel contents.

### November 4, 2026 official Compose update

The donor index is now `sha256:a4de4851b16f18634f74de66f126d5de65f7c5cb5a9502d67ab83e9a96041a70`. Its official binaries include the x/net 0.60.0 fix on `linux/amd64`, `linux/arm64`, and `linux/arm/v7`. Dockerfile, example environment, and publication build arguments use the same immutable pin. No custom Go build is introduced.

Trivy 0.76.1 compared this index with the previous 5.6.1 index on all three platforms using comprehensive detection, every severity, unfixed findings, and an explicit empty ignore file. The same database, updated at `2026-11-03 19:16:30 UTC`, was held constant for all six scans. Reported image architectures matched the requested platforms. Findings fell from eight to three on each platform: CVE-2026-78669, CVE-2026-78659, CVE-2026-78660, CVE-2026-78663, and CVE-2026-97032 are absent from 5.7.0. GO-2026-5932, CVE-2026-78661, and CVE-2026-97045 remain visible at UNKNOWN severity.

These donor-image results are separate from the published-image recheck below. The October 28 candidate identities and counts remain historical evidence.

### Removed Compose exception

The exact-path exception for [CVE-2026-78669](https://pkg.go.dev/vuln/GO-2026-6611) is removed, together with the unused ignore file and workflow references. Official Compose 5.7.0 contains the [fix from x/net 0.60.0](https://pkg.go.dev/golang.org/x/net@v0.60.0) on every generator platform. That November 4 change retained the fixed HIGH/CRITICAL gate and added no exception. The separate November 8 decision above concerns only CVE-2026-78661.

On November 4, Trivy 0.76.1 scanned all three runtime manifests from published Maraudarr index `sha256:63e384c6cf571c6a3620af149c4c3c7f4f3283cd6e58ca649c77b3d5ceb73dcf`, built from source `d48316584966eb8b0f291bcf1d57dc6fa2d0ceb9`. The database updated at `2026-11-04 13:16:53 UTC` was held constant. Comprehensive detection included every severity and unfixed findings with an explicit empty ignore file. Each reported architecture matched the selected manifest.

| Platform | Published runtime manifest digest |
| --- | --- |
| `linux/amd64` | `sha256:fcce76074fd94f9e8c2870beb384e1264b2e88fff82095c85dca1cc262558766` |
| `linux/arm64` | `sha256:1450445c746b9e035d7b7d1421ae556e407d07dcafe8bd0b14211494b48586fb` |
| `linux/arm/v7` | `sha256:1f6941631d215bd20e40890873c0b9f59ed44886c772c8bc1a066be93ae4cb04` |

CVE-2026-78669 is absent from every report. Each platform retains three UNKNOWN Compose findings: GO-2026-5932, CVE-2026-78661, and CVE-2026-97045. There are no HIGH or CRITICAL findings in these reports. This result does not establish coverage of nested archives or claim vulnerability-free images. The current database now identifies an upstream fix for GO-2026-5932; Compose 5.7.0 still contains the older module. The historical counts below describe different artifacts and an older database.

Maraudarr's supported launch paths still disable container networking and drop all optional capabilities. Removing the exception does not change those runtime boundaries or update previously released images.

### October 28, 2026 artifact review

The stable-only candidate review used Trivy 0.76.1 with a freshly downloaded database updated at `2026-10-28 01:21:08 UTC`, held constant for every platform, and Docker Scout 1.27.0. All severities and unfixed findings were included, without repository ignores. Docker archives preserved each OCI manifest's configuration and layer contents; architecture, layer hashes, installed packages, and stable repository membership were checked explicitly.

The local candidate OCI index is `sha256:f2943d215a7ed832884e6f5b09ae651b71806d16ada852cea3f4fb4f8552d023`; it has not been published. All three platforms install the matching Python `3.14.10-r1` package family, musl `1.2.6-r3`, OpenSSL `3.5.9-r0`, Expat `2.9.0-r0`, and zlib `1.3.2-r1`. Every installed APK is available from Alpine 3.24 stable. Installed pip and setuptools remain absent from the application environment; its standard-library bootstrap wheel remains pip 26.2.2 with the nested components listed above.

| Artifact | Trivy findings per platform | Scout findings per platform |
| --- | --- | --- |
| Stable-only candidate: amd64, arm64, ARMv7 | 8 | 10 |

Each Trivy report contains one HIGH, four MEDIUM, and three UNKNOWN Compose module findings. Scout retains those eight reports plus the stable musl backport and Windows CLI reports described below. Counts are identical across all three platforms, but each scanner counts findings differently; compare within its column. The three patched Python interpreter advisories are absent from the image reports. A passing CI exception is not a clean artifact scan, and these totals do not establish coverage of nested bootstrap-wheel contents.

The remaining reports have these boundaries:

- **Stable musl backport:** Alpine's [stable recipe](https://github.com/alpinelinux/aports/blob/3.24-stable/main/musl/APKBUILD) and [stable security database](https://secdb.alpinelinux.org/v3.24/main.json) record CVE-2026-107891 fixed in `1.2.6-r3`. Scout compares the installed stable revision against edge's `r6`; these are different branch revisions. Trivy no longer selects the edge advisory repository after the temporary Python source is removed, and reports neither musl package. No musl ignore is added.
- **Compose networking:** The HIGH HTTP/2 finding and four MEDIUM x/net reports remain visible pending the official binary update.
- **HTML package metadata:** [CVE-2026-78661](https://pkg.go.dev/vuln/GO-2026-6860) concerns quadratic HTML parsing; [CVE-2026-97045](https://pkg.go.dev/vuln/GO-2026-6866) concerns HTML rendering namespace handling. Both are fixed in x/net 0.62.0. Comprehensive module detection reports them against Compose's x/net dependency, but the affected `golang.org/x/net/html` package is absent from the compiled binaries on all three platforms. Both reports were retained without new suppressions in that October review. Raw audits remain unfiltered; the November 8 decision above changes only CI handling of CVE-2026-78661 at the reviewed binary path.
- **OpenPGP:** At the October review, [GO-2026-5932](https://pkg.go.dev/vuln/GO-2026-5932) had no fixed version and concerns a package absent from the compiled Compose binary. Comprehensive package detection retains the module-level report.
- **Windows CLI:** Scout also reports [CVE-2025-15558](https://github.com/docker/cli/security/advisories/GHSA-p436-gjf2-799p), a Windows plugin-discovery issue. The generator runs on Linux; no blanket suppression is applied.

The disposable type-check image is development tooling, not a published runtime. It uses only stable repositories, installs matching Python `3.14.10-r1` packages before creating its isolated environment, and removes npm and system pip after installing its locked checker. No stale Python bytecode metapackage or scanner suppression is retained.

### Scan an immutable artifact

Use an explicit empty ignore file so CI exceptions cannot hide findings. Replace `IMAGE-DIGEST` with an immutable index digest and repeat for arm64 and ARMv7:

```sh
trivy image --ignorefile /dev/null --image-src remote --platform linux/amd64 --detection-priority comprehensive --scanners vuln ghcr.io/scottgigawatt/maraudarr@sha256:IMAGE-DIGEST
```

Publication requires generator smoke tests and artifact verification on every supported architecture. Main builds publish `edge`; version releases publish stable aliases. These dated results do not describe future moving tags, the host Docker daemon, or third-party service images in a generated stack. Pulling an image does not update running containers automatically.
