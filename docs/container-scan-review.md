# Maraudarr container scan review

This assessment helps maintainers compare published Maraudarr images, review unresolved findings, and reassess the temporary Compose exception. It is separate from the [security reporting policy](SECURITY.md). Results describe the immutable artifacts and database dates below.

<a id="november-9-2026-published-image-check"></a>

## November 13, 2026 published image check

Trivy 0.76.2 scanned every runtime manifest below with comprehensive detection, every severity, unfixed findings included, and an explicit empty ignore file. The database was updated at `2026-11-13 19:05:12 UTC`; scans used `--skip-db-update` and an in-memory cache. Remote scans selected each requested platform from an immutable index; reported architecture and ARMv7 variant matched the request.

- `edge`: index `sha256:1f177c3b23d822fd02b6ca5e47f0422ed4f62a99ed76b7ffcdd5700992f1ac49`, built from `6df94cfaab18e367df774869f432f57b076430f2`.
- `latest`: index `sha256:e28575292e342997bc95ec8bf28918cf8e8303c723c564571fb99cc99867b0c2`, built from `aa8f13bb8f972484e0ffb9339497f3c22aaf4329`.

| Channel and platform | Runtime manifest |
| --- | --- |
| `edge`, `linux/amd64` | `sha256:54d8c38aad94b3a0f58c31d4e345536a002852913aae6c19ef44b7a36e41392b` |
| `edge`, `linux/arm64` | `sha256:d9f59d9e270fe7f9ddd418b684365070abe2c07d90439ca5c9e822b9da4b74ef` |
| `edge`, `linux/arm/v7` | `sha256:cf5a5d76aa59c2c1524025a2f8e54fab2866146c98086730bb46e4554aee0473` |
| `latest`, `linux/amd64` | `sha256:ec00f345054e489840560ff07ff19d99a61fb67b5c70011a17b514f8ed9c7283` |
| `latest`, `linux/arm64` | `sha256:0aa6999ac7f22fd5c963c7fc1208a09227767ca9fbaef87fb089caa417706e3b` |
| `latest`, `linux/arm/v7` | `sha256:c2ae21f33403187e81d574ead412d448925ce88732d194d6c9778d506c2a479c` |

Counts are identical within each channel across amd64, arm64, and ARMv7:

| Channel | HIGH | MEDIUM | UNKNOWN | Findings |
| --- | --- | --- | --- | --- |
| `edge` | 1 | 1 | 2 | The four Compose reports below |
| `latest` | 1 | 2 | 2 | The same Compose reports plus zlib |

The stable image retains [CVE-2026-4738 in zlib](https://secdb.alpinelinux.org/v3.24/main.json): `1.3.2-r1` is installed and `1.4-r0` is fixed. The existing stable-package refresh already installs zlib `1.4-r0` in the audited `edge` image; no separate package floor or new suppression is needed. A new stable release is required to deliver that fix through `latest`. Neither channel has a CRITICAL finding in these reports.

The remaining Compose reports are:

| Advisory | Severity | Module in Compose 5.7.0 | Upstream fixed version |
| --- | --- | --- | --- |
| [CVE-2026-78661 / GO-2026-6860](https://pkg.go.dev/vuln/GO-2026-6860) | HIGH | `golang.org/x/net v0.60.0` | `v0.62.0` |
| [CVE-2026-97045 / GO-2026-6866](https://pkg.go.dev/vuln/GO-2026-6866) | MEDIUM | `golang.org/x/net v0.60.0` | `v0.62.0` |
| [GO-2026-5932](https://pkg.go.dev/vuln/GO-2026-5932) | UNKNOWN | `golang.org/x/crypto v0.57.0` | `v0.58.1-0.20261009181718-2f1f834330b2` |
| CVE-2026-97054 | UNKNOWN | Go `1.26.10` | Go `1.26.11` or `1.27.4` |

Compose [5.7.1](https://github.com/docker/compose/releases/tag/v5.7.1), published November 11, uses Go 1.27.4 and removes the Go standard library finding. The production dependency PR adopts its official digest-pinned donor and markdown-it-py 4.3.0. A fresh arm64 candidate image has one HIGH, one MEDIUM, and one UNKNOWN finding: the three unchanged x/net and x/crypto reports. All three official donor architectures have those same reports. The updated donor still contains x/net 0.60.0 and x/crypto 0.57.0; their module fixes have not reached the latest official Compose release. A passing filtered CI gate is not an unfiltered clean image scan. These candidate changes remain unreleased until merged and published.

<a id="november-8-2026-temporary-compose-exception"></a>

## November 13, 2026 temporary Compose exception

This section is for maintainers reviewing the temporary CI exception for Maraudarr. Trivy now classifies [CVE-2026-78661 / GO-2026-6860](https://pkg.go.dev/vuln/GO-2026-6860) as HIGH in Compose's `golang.org/x/net v0.60.0` module. The affected HTML parser is fixed upstream in x/net 0.62.0. The latest official Compose 5.7.1 donor still contains x/net 0.60.0. Its newly reviewed binaries have no affected HTML package or symbols on any supported architecture. The exception is justified by absent affected code in the reviewed binary, not by an absence of an upstream module fix.

The [temporary exception](https://github.com/scottgigawatt/plundarr/blob/main/.trivyignore.yaml) excludes only `CVE-2026-78661` at `usr/local/bin/docker-compose`. Its owner is `scottgigawatt`. Trivy stops applying it on **November 22, 2026 at 00:00 UTC**. It applies only to the Maraudarr scan in pull-request and publication workflows. Every other finding remains subject to the existing scan policy. Affected CI scans enable `TRIVY_SHOW_SUPPRESSED`, so the ignored finding and its justification remain visible. Raw audits continue to use `--ignorefile /dev/null`.

### Verify the reviewed binary

The reviewed donor is `docker/compose-bin:v5.7.1@sha256:6a6704a7ccbc45eb4cc7e5b71dba685e9bc23705c580430f15034b2b5e46ec2b`. Docker Buildx selected each platform from the immutable index and exported `/docker-compose` into a disposable local directory. Docker validates fetched content digests; SHA-256 checks of the exported files produced the values below. Go build metadata confirmed each requested architecture and ARMv7 variant. No extracted binary was executed.

| Platform | Donor runtime manifest | Extracted binary SHA-256 |
| --- | --- | --- |
| `linux/amd64` | `sha256:7d12ba7faf83e8ed53e89b5142b664bedfa37ce141bc3dc0d44994dd3711fcf4` | `af426722a8af5de812fcee30cc1c39f0639f5f723cbadefb25e5d4db054064cf` |
| `linux/arm64` | `sha256:332b5f5e9fef2296eb23280b9b815457e6558d67b52faafc13d301cef238a80a` | `f2f49f903240895fa764c0dca3a14548b754ad9426f6b609ccaf55ec5a3aa2a5` |
| `linux/arm/v7` | `sha256:bea1e236427b5f44c28fd5a17da637ee5843235ff007e7496f195bca7469cc91` | `c03e0c93cf747f311d39f6920a33c461fd0f7a6246439aaf259766527caa28f5` |

Go 1.27.4 and `govulncheck v1.9.0` inspected the binaries, which were built with Go 1.27.4. `go version -m` confirmed x/net 0.60.0. Both `go tool nm` and `govulncheck -mode=extract` recovered symbols successfully; neither found the affected `golang.org/x/net/html` package or its nested packages. Nonzero x/net symbol counts provide a positive control against an empty or failed extraction.

| Platform | Recovered Go symbols | x/net symbols | HTML package symbols |
| --- | --- | --- | --- |
| `linux/amd64` | 36,931 | 383 | 0 |
| `linux/arm64` | 36,865 | 382 | 0 |
| `linux/arm/v7` | 36,870 | 383 | 0 |

To repeat this check, use Go 1.27.4, `govulncheck v1.9.0`, and `jq`. Extract the binary from a manifest above into a disposable directory, verify its SHA-256, and set `COMPOSE_BINARY` to that local path. These commands inspect the binary without executing it:

```sh
go version -m "${COMPOSE_BINARY}"
go tool nm "${COMPOSE_BINARY}" > compose-symbols.txt
govulncheck -mode=extract "${COMPOSE_BINARY}" > compose-symbols.jsonl
govulncheck -mode=binary -scan=symbol -json "${COMPOSE_BINARY}" > compose-vulnerabilities.json
jq -s -e '.[1].pkgSymbols as $symbols | ($symbols | length > 0) and any($symbols[]; (.pkg // "") | startswith("golang.org/x/net/")) and all($symbols[]; (.pkg != "golang.org/x/net/html") and ((.pkg // "") | startswith("golang.org/x/net/html/") | not))' compose-symbols.jsonl
```

The final command must succeed. Retain the module-level reports: binary-mode govulncheck still reports GO-2026-6860 against x/net 0.60.0, but without an affected package or symbol trace. This review does not declare Compose vulnerability-free or establish that unrelated findings are harmless.

### Check filtering and expiry

Trivy 0.76.2 scanned the fresh arm64 candidate with the November 13 database. An unfiltered comprehensive scan retains the HIGH finding. The HIGH/CRITICAL gate with the exact-path exception passes and records the ignored finding with `--show-suppressed`; the MEDIUM and UNKNOWN module reports remain visible in all-severity audits. The binary assessment above covers amd64, arm64, and ARMv7. The workflow CI engine remains Trivy 0.70.0; its result is validated separately by the PR checks.

The scope guard and rejection fixtures verify that changing the donor, path, advisory, expiry, or entry count fails closed. The November 22 expiry has not been extended.

### Remove or reassess the exception

The [scope guard](https://github.com/scottgigawatt/plundarr/blob/main/test/policy/check-compose-exception-policy.sh) and [rejection fixtures](https://github.com/scottgigawatt/plundarr/blob/main/test/helpers/test-compose-exception-policy.sh) run through pre-commit and `make test-workflows`. They reject a changed donor declaration, another path or advisory, a second exception, or an extended expiry. Trivy enforces the UTC expiry; the guard checks the reviewed policy values rather than the current clock.

1. Before the expiry, check for an official donor containing x/net 0.62.0 or later. Review its binary contents and run unfiltered scans on every supported platform before accepting a pin update.
2. Remove this exception sooner if the donor changes, affected HTML code becomes present, or the upstream fix can be adopted. A changed donor requires a new code-path assessment; the current exception cannot be carried forward automatically.
3. When removing the exception, remove `.trivyignore.yaml`, its `trivyignores` and `TRIVY_SHOW_SUPPRESSED` workflow settings, the dedicated guard and fixture scripts, their calls in `test-workflow-helpers.sh`, and the dedicated pre-commit hook. Update the build path filter and this dated decision together.
4. Run `make test-workflows`, the repository hooks, and strict documentation checks. Confirm the unfiltered image gate passes before merging a fix. Do not extend the exception solely to obtain a green build.

This is the only active exception. CVE-2026-97045 and other Compose advisories remain visible in unfiltered reports.

## Runtime and toolchain boundaries

The production dependency PR uses Docker's official digest-pinned Compose 5.7.1 binary, built with Go 1.27.4; the published artifacts above still use 5.7.0. Dockerfile, example environment, and publication arguments share the reviewed donor pin. No custom Go rebuild or modified upstream binary is maintained.

The image refreshes Alpine 3.24 stable packages before installing dependencies. Python and its matching bytecode packages come from stable; the hardened smoke test verifies the installed musl security backport. Runtime and documentation requirements remain exact and hash-verified. Development checkers and installed pip/setuptools stay out of the application virtual environment. The disposable type-check image retains its locked Pyright version and removes npm and system pip after installation.

Alpine Python's standard-library `ensurepip` seed remains pip 26.2.2 with its upstream vendored components, including msgpack 1.1.2, urllib3 2.7.0, and pkg_resources from setuptools 70.3.0. It is not installed in the application environment or used by generation. The image scan totals above do not establish coverage of nested bootstrap-wheel contents.

[pip 26.3](https://pip.pypa.io/en/stable/news/#v26-3), published on November 2, updates msgpack to 1.2.4 and urllib3 to 2.8.0. Its complete, unmodified wheel has SHA-256 `f3b60b20ffaadd4415ed7957212a38ac63fa4c5fa375bd0f4a797777940fad13`, matching the published PyPI hash. That release does not replace Alpine's package-owned bootstrap archive: its SHA-256 remains `fd7f4dfa8190e014013b9f08f3e973f4e4c26ffd179a204895533a7254813a70` in the November 9 audited manifests and the fresh November 13 arm64 candidate. Keep this archive assessment separate from the whole-image counts above until Alpine updates its Python package.

Supported launch paths disable container networking and drop all optional capabilities. These boundaries do not remove module-level findings. Use the [generator revision guide](development/maraudarr/index.md#choose-the-generator-revision) to select the source-built generator for this checkout's catalog and dependencies.

## Scan an immutable artifact

Use Trivy with an explicit empty ignore file so CI exceptions cannot hide findings. Replace `IMAGE-DIGEST` with an immutable index digest and repeat for arm64 and ARMv7:

```sh
trivy image --ignorefile /dev/null --image-src remote --platform linux/amd64 --detection-priority comprehensive --scanners vuln --severity UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL --ignore-unfixed=false ghcr.io/scottgigawatt/maraudarr@sha256:IMAGE-DIGEST
```

For an offline OCI scan, select exactly one runtime descriptor in the layout's `index.json` and retain its complete verified blobs. With Trivy 0.76.2, `--platform` did not select a different manifest from a multi-platform `--input` layout. Check `Metadata.ImageConfig.architecture` and `variant` in each JSON report; repeating the first architecture is not a three-platform audit.

Publication requires generator smoke tests and artifact verification on every supported architecture. Main builds publish `edge`; version releases publish stable aliases. These dated results do not describe future moving tags, the host Docker daemon, or third-party service images in a generated stack. Pulling an image does not update running containers automatically.
