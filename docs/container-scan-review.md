# Maraudarr container scan review

This assessment helps maintainers compare published Maraudarr images, review unresolved findings, and reassess the temporary Compose exception. It is separate from the [security reporting policy](SECURITY.md). Results describe the immutable artifacts and database dates below.

## November 9, 2026 published image check

Trivy 0.76.2 scanned every runtime manifest below with comprehensive detection, every severity, unfixed findings included, and an explicit empty ignore file. The same database, updated at `2026-11-09 06:57:06 UTC`, was held constant for all six scans. Complete configurations and layers were verified against their SHA-256 digests and sizes before scanning. Each local OCI layout selected one runtime manifest; reported architecture and ARMv7 variant matched the requested platform.

- `edge`: index `sha256:4679b53ba2dc1143975d4a6f567852bb95187c9de71a16a99cc04c22299fde6d`, built from `bbcc3e7112525e6cf73d10c8e596a865564ab117`.
- `latest`: index `sha256:e28575292e342997bc95ec8bf28918cf8e8303c723c564571fb99cc99867b0c2`, built from `aa8f13bb8f972484e0ffb9339497f3c22aaf4329`.

| Channel and platform | Runtime manifest |
| --- | --- |
| `edge`, `linux/amd64` | `sha256:c05244029b81d0af268852719fcf38dd09d44aee6bc2fd86b75c56cf26b6b241` |
| `edge`, `linux/arm64` | `sha256:c4b10dcb972cb2a79d2126f424cc25f3534ef9dce3ad3abf636b4d910c6f8213` |
| `edge`, `linux/arm/v7` | `sha256:454699eb209b39bdb756effc10d7cc6dc55ab175bba63d7ee6ab90e92b339b16` |
| `latest`, `linux/amd64` | `sha256:ec00f345054e489840560ff07ff19d99a61fb67b5c70011a17b514f8ed9c7283` |
| `latest`, `linux/arm64` | `sha256:0aa6999ac7f22fd5c963c7fc1208a09227767ca9fbaef87fb089caa417706e3b` |
| `latest`, `linux/arm/v7` | `sha256:c2ae21f33403187e81d574ead412d448925ce88732d194d6c9778d506c2a479c` |

Counts are identical within each channel across amd64, arm64, and ARMv7:

| Channel | HIGH | MEDIUM | UNKNOWN | Findings |
| --- | --- | --- | --- | --- |
| `edge` | 1 | 1 | 1 | The three Compose reports below |
| `latest` | 1 | 2 | 1 | The same Compose reports plus zlib |

The stable image retains [CVE-2026-4738 in zlib](https://secdb.alpinelinux.org/v3.24/main.json): `1.3.2-r1` is installed and `1.4-r0` is fixed. The existing stable-package refresh already installs zlib `1.4-r0` in the audited `edge` image; no separate package floor or new suppression is needed. A new stable release is required to deliver that fix through `latest`. Neither channel has a CRITICAL finding in these reports.

The remaining Compose reports are:

| Advisory | Severity | Module in Compose 5.7.0 | Upstream fixed version |
| --- | --- | --- | --- |
| [CVE-2026-78661 / GO-2026-6860](https://pkg.go.dev/vuln/GO-2026-6860) | HIGH | `golang.org/x/net v0.60.0` | `v0.62.0` |
| [CVE-2026-97045 / GO-2026-6866](https://pkg.go.dev/vuln/GO-2026-6866) | MEDIUM | `golang.org/x/net v0.60.0` | `v0.62.0` |
| [GO-2026-5932](https://pkg.go.dev/vuln/GO-2026-5932) | UNKNOWN | `golang.org/x/crypto v0.57.0` | `v0.58.1-0.20261009181718-2f1f834330b2` |

The official Compose release check on November 9 still returned 5.7.0. Module fixes are published, but no newer official donor containing them was available. Keep these reports and the exception's expiry/removal requirements until a compatible official donor can be adopted. A passing filtered CI gate is not an unfiltered clean image scan.

## November 8, 2026 temporary Compose exception

This section is for maintainers reviewing the temporary CI exception for Maraudarr. Trivy now classifies [CVE-2026-78661 / GO-2026-6860](https://pkg.go.dev/vuln/GO-2026-6860) as HIGH in Compose's `golang.org/x/net v0.60.0` module. The affected HTML parser is fixed upstream in x/net 0.62.0. At this check, the latest [official Compose release](https://github.com/docker/compose/releases/tag/v5.7.0) remained 5.7.0; no newer official donor containing that module fix was available. The exception is justified by absent affected code in the reviewed binary, not by an absence of an upstream module fix.

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

This is the only active exception. CVE-2026-97045 and other Compose advisories remain visible in unfiltered reports.

## Runtime and toolchain boundaries

Maraudarr uses Docker's official digest-pinned [Compose 5.7.0 binary](https://github.com/docker/compose/releases/tag/v5.7.0), built with Go 1.26.10. Dockerfile, example environment, and publication arguments share the reviewed donor pin. No custom Go rebuild or modified upstream binary is maintained.

The image refreshes Alpine 3.24 stable packages before installing dependencies. Python and its matching bytecode packages come from stable; the hardened smoke test verifies the installed musl security backport. Runtime and documentation requirements remain exact and hash-verified. Development checkers and installed pip/setuptools stay out of the application virtual environment. The disposable type-check image retains its locked Pyright version and removes npm and system pip after installation.

Alpine Python's standard-library `ensurepip` seed remains pip 26.2.2 with its upstream vendored components, including msgpack 1.1.2, urllib3 2.7.0, and pkg_resources from setuptools 70.3.0. It is not installed in the application environment or used by generation. The image scan totals above do not establish coverage of nested bootstrap-wheel contents.

Supported launch paths disable container networking and drop all optional capabilities. These boundaries do not remove module-level findings. Use the [generator revision guide](development/maraudarr/index.md#choose-the-generator-revision) to select the source-built generator for this checkout's catalog and dependencies.

## Scan an immutable artifact

Use Trivy with an explicit empty ignore file so CI exceptions cannot hide findings. Replace `IMAGE-DIGEST` with an immutable index digest and repeat for arm64 and ARMv7:

```sh
trivy image --ignorefile /dev/null --image-src remote --platform linux/amd64 --detection-priority comprehensive --scanners vuln --severity UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL --ignore-unfixed=false ghcr.io/scottgigawatt/maraudarr@sha256:IMAGE-DIGEST
```

For an offline OCI scan, select exactly one runtime descriptor in the layout's `index.json` and retain its complete verified blobs. With Trivy 0.76.2, `--platform` did not select a different manifest from a multi-platform `--input` layout. Check `Metadata.ImageConfig.architecture` and `variant` in each JSON report; repeating the first architecture is not a three-platform audit.

Publication requires generator smoke tests and artifact verification on every supported architecture. Main builds publish `edge`; version releases publish stable aliases. These dated results do not describe future moving tags, the host Docker daemon, or third-party service images in a generated stack. Pulling an image does not update running containers automatically.
