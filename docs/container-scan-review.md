# Maraudarr container scan review

This assessment helps maintainers compare published Maraudarr images and review the temporary Compose exception. Results describe the immutable artifacts and database date below. Use the [security reporting policy](SECURITY.md) to report a vulnerability. The source changes below are proposed in [dependency PR #217](https://github.com/scottgigawatt/plundarr/pull/217) and remain unreleased.

<a id="november-9-2026-published-image-check"></a>
<a id="november-13-2026-published-image-check"></a>

## November 23, 2026 published image check

Trivy 0.76.2 scanned every runtime manifest below with comprehensive detection, every severity, unfixed findings included, and an explicit empty ignore file. The database was updated at `2026-11-23 01:05:17 UTC`; scans used `--skip-db-update` and an in-memory cache. Each report confirms the requested architecture and ARMv7 variant.

- `latest`: version `3.2.1`, index `sha256:079bdd64104f6aaf0d148b43dc5b1236e8b3b72de24019ee301d4c14b7d81af2`, revision `af08965d480a0661b20045d934e7249b7a28304b`.
- `edge`: index `sha256:dad460abca3d3392b3435d9cdfb0b83cc887958859319759a28e07bb327aeec1`, revision `232b2d2ff38e91ef39f57bec7c0283f11f28a2bb`.

| Channel and platform | Runtime manifest |
| --- | --- |
| `latest`, `linux/amd64` | `sha256:08d88b180492831f5b1990cda5ebd741c23ed8c88cc402f14d5caceff3941bf3` |
| `latest`, `linux/arm64` | `sha256:b076851da57e150cd6234301eb1a3022969965711a7234fba52ec73d81472d7a` |
| `latest`, `linux/arm/v7` | `sha256:f374855d331f50b7d82fe9c103108e81408f5c6a49105bef3d824bf85ce69f3f` |
| `edge`, `linux/amd64` | `sha256:33dd07cd05660142859265cb65204904aac99560bada6e283d38ed954ec440a4` |
| `edge`, `linux/arm64` | `sha256:32b86bd7c1fb2cb03055f8e6446cdc81a8f3f7ab05524cbbf81feaad9c1e329e` |
| `edge`, `linux/arm/v7` | `sha256:37bb32817af5fa9165216699f8a67b712c1b74bb5cafc86832a7ce9e9c6985e3` |

Every published manifest has **1 HIGH, 9 MEDIUM, 4 LOW, and 1 UNKNOWN** package/advisory findings. Counts include separate reports for the same advisory in different packages.

OpenSSL supplies ten findings: six MEDIUM and four LOW across `libcrypto3` and `libssl3` `3.5.9-r0`. Alpine fixes them in `3.5.9-r1`. The source update requires those supported stable packages in both build and runtime stages, invalidating cached installation layers. Fresh candidates on amd64, arm64, and ARMv7 remove all ten rows; each retains the five Compose findings below. Their normal cached builds enforce the package floor, and each platform passes the precise HIGH/CRITICAL gate with one visibly suppressed finding. A new stable release is required to deliver source fixes through `latest`.

| Advisory | Severity | Installed module | Upstream fixed version |
| --- | --- | --- | --- |
| [CVE-2026-78661 / GO-2026-6860](https://pkg.go.dev/vuln/GO-2026-6860) | HIGH | `golang.org/x/net v0.60.0` | `v0.62.0` |
| [CVE-2026-97045 / GO-2026-6866](https://pkg.go.dev/vuln/GO-2026-6866) | MEDIUM | `golang.org/x/net v0.60.0` | `v0.62.0` |
| CVE-2026-128085 | MEDIUM | `go.opentelemetry.io/otel/sdk` and `trace v1.46.0` | `v1.47.0` |
| [GO-2026-5932](https://pkg.go.dev/vuln/GO-2026-5932) | UNKNOWN | `golang.org/x/crypto v0.57.0` | `v0.58.1-0.20261009181718-2f1f834330b2` |

[Compose 5.8.0](https://github.com/docker/compose/releases/tag/v5.8.0) is the latest official release checked on November 23. All three donor binaries retain these module versions and five findings. The image uses Docker's official digest-pinned binary; no custom Go rebuild is maintained. A module fix existing upstream does not establish that Docker's published binary contains it.

<a id="november-8-2026-temporary-compose-exception"></a>
<a id="november-13-2026-temporary-compose-exception"></a>

## November 23, 2026 temporary Compose exception

This section is for maintainers reviewing the exact-path exception for `CVE-2026-78661`. A fresh package and symbol assessment of Compose 5.8.0 finds no affected `golang.org/x/net/html` package or nested package on any supported architecture. The exception rests on absent affected code in these binaries; it does not declare the module fixed.

The [exception](https://github.com/scottgigawatt/plundarr/blob/main/.trivyignore.yaml) excludes only `CVE-2026-78661` at `usr/local/bin/docker-compose`, with owner `scottgigawatt`. It expires on **November 30, 2026 at 00:00 UTC**. This new review replaces the expired November 22 assessment and binds the exception to the newly inspected donor. All other findings remain visible. Pull-request and publication scans enable `TRIVY_SHOW_SUPPRESSED`; raw audits use `--ignorefile /dev/null`.

### Verify the reviewed binary

The donor index is `docker/compose-bin:v5.8.0@sha256:c9f99a4efa43ca83e5acc056da938c38504010c10a2dd804569032be5d3b0dd5`. Buildx exported each architecture's binary from its immutable manifest. SHA-256 checks identify the exported files; Go build metadata confirms Go 1.27.4, the requested architecture, and the module versions above. No extracted binary was executed.

| Platform | Donor runtime manifest | Binary SHA-256 |
| --- | --- | --- |
| `linux/amd64` | `sha256:2b1984a73f63ed92cf4ca659c592ae666c14877a0b9fbdfca586a3ab5488d226` | `b8840f5008c447f41fce0a57ae3adeab42c89b1eb6e6012524bcabbfb4ffbaf6` |
| `linux/arm64` | `sha256:0a55ea77790d69990819578ee2476501acd20df2ac0c3e202ebe3c43b354b8ce` | `1a9c918b2fb49b9c87f0018c64b5abd0d30715155e98dc939779fbaee6c414d3` |
| `linux/arm/v7` | `sha256:47ed358fc687e399e65295009829728331f7c8314c8d842a6efccd3c9d4c20d1` | `a7a79755648b975b66df08b4bfbe12b29f113d5dd8c7cd5b6b53b69efff2f422` |

Go 1.27.4 and `govulncheck v1.9.0` recovered symbols successfully through both `go tool nm` and `govulncheck -mode=extract`. Nonzero x/net symbol counts provide a positive control; both methods found zero affected HTML package symbols.

| Platform | Recovered Go symbols | x/net symbols | HTML package symbols |
| --- | --- | --- | --- |
| `linux/amd64` | 37,564 | 383 | 0 |
| `linux/arm64` | 37,497 | 382 | 0 |
| `linux/arm/v7` | 37,501 | 383 | 0 |

To reproduce, install Go 1.27.4, `govulncheck v1.9.0`, and `jq`. Export one manifest's binary into a disposable directory, verify its hash above, and set `COMPOSE_BINARY` to its local path. These commands inspect the binary without executing it:

```sh
go version -m "${COMPOSE_BINARY}"
go tool nm "${COMPOSE_BINARY}" > compose-symbols.txt
govulncheck -mode=extract "${COMPOSE_BINARY}" > compose-symbols.jsonl
govulncheck -mode=binary -scan=symbol -json "${COMPOSE_BINARY}" > compose-vulnerabilities.json
jq -s -e '.[1].pkgSymbols as $symbols | ($symbols | length > 0) and any($symbols[]; (.pkg // "") | startswith("golang.org/x/net/")) and all($symbols[]; (.pkg != "golang.org/x/net/html") and ((.pkg // "") | startswith("golang.org/x/net/html/") | not))' compose-symbols.jsonl
```

The final command must succeed. Retain module-level findings even when affected package symbols are absent. These results do not assess the reachability of unrelated advisories.

### Check filtering and expiry

An unfiltered candidate scan retains one HIGH, three MEDIUM, and one UNKNOWN finding. The ordinary gate considers fixed HIGH/CRITICAL findings and applies the single exact-path exception; passing that gate does not mean an unfiltered scan is clean. The policy and [rejection fixtures](https://github.com/scottgigawatt/plundarr/blob/main/test/helpers/test-compose-exception-policy.sh) reject changes to the reviewed donor, advisory, path, expiry, or entry count. Trivy enforces the UTC expiry.

1. Before November 30, check whether an official donor contains x/net 0.62.0 or later. Inspect its actual binaries and scan every supported platform.
2. Remove or reassess the exception if the donor changes, affected HTML code appears, or a compatible official fix becomes available. Do not extend it solely to pass CI.
3. When removing the exception, remove `.trivyignore.yaml`, its workflow settings and path filter, the dedicated guard, rejection fixtures, their workflow-helper calls, and the pre-commit hook together.
4. Run `make test-workflows`, `pre-commit run --all-files`, `make docs`, and the unfiltered image gate before accepting removal.

## Runtime and toolchain boundaries

The production image refreshes stable Alpine packages and uses exact, hash-verified application dependencies. Development checkers, installed pip, and installed setuptools stay outside the application environment. Supported launch paths disable container networking and drop all optional capabilities; those controls do not remove module-level findings.

The fresh arm64 candidate retains Alpine's package-owned `pip-26.2.2-py3-none-any.whl` bootstrap archive, SHA-256 `fd7f4dfa8190e014013b9f08f3e973f4e4c26ffd179a204895533a7254813a70`. It vendors msgpack 1.1.2, urllib3 2.7.0, and setuptools 70.3.0. Generation does not install or use it. Whole-image totals do not establish coverage of nested wheel contents; a newer pip wheel does not replace Alpine's archive automatically.

## Scan an immutable artifact

Use an empty ignore file and repeat for every supported architecture. Replace `IMAGE-DIGEST` with an immutable runtime manifest from the table:

```sh
trivy image --ignorefile /dev/null --image-src remote --detection-priority comprehensive --scanners vuln --severity UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL --ignore-unfixed=false ghcr.io/scottgigawatt/maraudarr@sha256:IMAGE-DIGEST
```

For an offline OCI scan, select exactly one runtime descriptor in the layout's `index.json` and retain its verified blobs. With Trivy 0.76.2, `--platform` did not select a different manifest from a multi-platform `--input` layout. Confirm `Metadata.ImageConfig.architecture` and `variant` in every report.

Main builds publish `edge`; version releases publish stable aliases. These dated results do not describe future moving tags, third-party stack images, or live service health. Use the [generator revision guide](development/maraudarr/index.md#choose-the-generator-revision) to select source-built dependencies for this checkout.
