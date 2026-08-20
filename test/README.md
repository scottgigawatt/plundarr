# Plundarr Test Hold 🧪🏴‍☠️

Welcome to the test hold, where Plundarr checks that Privateerr and Gluetun left the PIA WireGuard and port-forwarding voyage in a usable state.

## Test Script Chart 🗺️

| Hold         | Script                                                                                                                                  | Purpose                                                             |
| ------------ | --------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| 🧭 Generator | [`generator/maraudarr-image-smoke.sh`](https://github.com/scottgigawatt/plundarr/blob/main/test/generator/maraudarr-image-smoke.sh)     | Test image UI and validate one disposable deployment                |
| 🧭 Generator | [`generator/test-maraudarr-image.sh`](https://github.com/scottgigawatt/plundarr/blob/main/test/generator/test-maraudarr-image.sh)       | Verify local, pulled, built, and unavailable image resolution paths |
| 🧭 Generator | [`generator/test-maraudarr-matrix.sh`](https://github.com/scottgigawatt/plundarr/blob/main/test/generator/test-maraudarr-matrix.sh)     | Generate and validate representative preset and add-on combinations |
| 🧰 Helpers   | [`helpers/test-make-helpers.sh`](https://github.com/scottgigawatt/plundarr/blob/main/test/helpers/test-make-helpers.sh)                 | Test Make's AWK, backup, PIA preflight, and Compose status helpers  |
| 🧰 Helpers   | [`helpers/test-policy-checks.sh`](https://github.com/scottgigawatt/plundarr/blob/main/test/helpers/test-policy-checks.sh)               | Test valid and invalid publishing-policy fixtures offline           |
| 🧰 Helpers   | [`helpers/test-workflow-helpers.sh`](https://github.com/scottgigawatt/plundarr/blob/main/test/helpers/test-workflow-helpers.sh)         | Test release, Discord, and registry helper behavior offline         |
| 🛡️ Policy    | [`policy/check-build-pin-policy.sh`](https://github.com/scottgigawatt/plundarr/blob/main/test/policy/check-build-pin-policy.sh)         | Keep digest-pinned build dependency tags synchronized               |
| 🛡️ Policy    | [`policy/check-image-tag-policy.sh`](https://github.com/scottgigawatt/plundarr/blob/main/test/policy/check-image-tag-policy.sh)         | Enforce canonical image tags in every metadata-action block         |
| 🧮 Policy    | [`policy/awk/check-image-tags.awk`](https://github.com/scottgigawatt/plundarr/blob/main/test/policy/awk/check-image-tags.awk)           | Parse and validate workflow image-tag metadata blocks               |
| 🧮 Policy    | [`policy/awk/collect-build-pins.awk`](https://github.com/scottgigawatt/plundarr/blob/main/test/policy/awk/collect-build-pins.awk)       | Extract and validate digest-pinned build dependency values          |
| 🌊 Runtime   | [`runtime/plundarr-stack-wait.sh`](https://github.com/scottgigawatt/plundarr/blob/main/test/runtime/plundarr-stack-wait.sh)             | Wait for a generated stack to become healthy                        |
| 🌊 Runtime   | [`runtime/plundarr-vpn-test.sh`](https://github.com/scottgigawatt/plundarr/blob/main/test/runtime/plundarr-vpn-test.sh)                 | Validate Privateerr, Gluetun, and selected downloader state         |
| 🎭 Stubs     | [`stubs/compose-docker-stub.sh`](https://github.com/scottgigawatt/plundarr/blob/main/test/stubs/compose-docker-stub.sh)                 | Supply deterministic Docker output to Compose helper tests          |
| 🎭 Stubs     | [`stubs/maraudarr-image-docker-stub.sh`](https://github.com/scottgigawatt/plundarr/blob/main/test/stubs/maraudarr-image-docker-stub.sh) | Simulate Maraudarr image discovery and retrieval outcomes           |
| 🎭 Stubs     | [`stubs/workflow-skopeo-stub.sh`](https://github.com/scottgigawatt/plundarr/blob/main/test/stubs/workflow-skopeo-stub.sh)               | Simulate registry inspection without network access                 |

The subfolders separate generator contracts, reusable helper tests, publishing
policy checks, live-stack runtime checks, and deterministic command stubs. Make
targets remain the public interface; invoke individual scripts only while
diagnosing a focused failure.

## What Gets Tested 🦜

The VPN test script does not use a throwaway test image. It validates the actual Privateerr, Gluetun, and qBittorrent Compose containers:

- Privateerr generated PIA WireGuard `wg0.conf`.
- Privateerr generated PIA port-forwarding metadata in `privateerr.env`.
- Privateerr and Gluetun containers are running and healthy.
- Gluetun is reachable through its unauthenticated health endpoint from inside the Gluetun container.
- PIA port-forwarding produced a usable forwarded port when required.
- qBittorrent listens on Gluetun's forwarded port when qBittorrent validation is enabled.

## Test Voyages 🧭

### Maraudarr Generator Checks

Use the complete Maraudarr test target while changing image resolution,
presets, service charts, or generated config seeds:

> [!TIP]
>
> ```sh
> make test
> ```

These checks simulate local-image discovery, a successful GHCR pull, a local
fallback build, and a complete retrieval failure without contacting a registry.
They also run the Python unit suite; exercise the offline release, Discord, and
registry helpers; enforce synchronized build pins and canonical image tags;
verify the compact Compose status and secret-safe PIA preflight helpers; and
generate representative Compose charts.

Use the focused Make-helper target while changing AWK programs, config backup,
the PIA credential preflight, or Compose status formatting:

> [!TIP]
>
> ```sh
> make test-make-helpers
> ```

After building an image, run its terminal UI tests with exact runtime
dependencies, then exercise its hardened contract and validate one disposable
deployment:

> [!TIP]
>
> ```sh
> make test-image
> ```

This makes the Rich terminal regression checks mandatory for the built image,
even when Rich is unavailable to host-side tests. CI can select another voyage
with `MARAUDARR_TEST_PRESET`,
`MARAUDARR_TEST_ADD`, `MARAUDARR_TEST_REMOVE`, and
`MARAUDARR_TEST_FILE` without duplicating a raw `docker run` block.

### Workflow and Publishing Policy Checks

Use the offline automation target while changing workflows, workflow helpers,
Docker build inputs, release behavior, or published image tags:

> [!TIP]
>
> ```sh
> make test-workflows
> ```

The workflow-helper suite validates release-tag inputs, Discord payloads,
registry mirroring, and digest comparison without contacting those services.
The policy checks require every build dependency tag to carry one synchronized
SHA-256 digest across Dockerfiles, the root example environment, and the build
workflow. They also require each Docker metadata block to publish the shared
`latest`, `edge`, `sha-...`, exact SemVer, minor, and stable-major channels.
Major version zero and prerelease safeguards are enforced by the same policy.

`helpers/test-policy-checks.sh` copies the policy programs into a disposable
repository and proves that valid input passes while mismatched pins, missing
aliases, and noncanonical tag rules fail with useful diagnostics.

### Running Stack Check

Use this when the full Plundarr stack is already running:

> [!TIP]
>
> ```sh
> make test-vpn
> ```

This checks the existing Privateerr and Gluetun containers, then verifies generated files and port forwarding.

### Privateerr + Gluetun + Download E2E

Use this when ye want `Make` to launch only the VPN pair plus download clients, validate it, then clean up:

> [!TIP]
>
> ```sh
> make test-e2e
> ```

This target:

1. Restores example config.
2. Starts only `privateerr`, `gluetun`, and selected download services with Docker Compose.
3. Waits for those services to report healthy.
4. Runs `test/runtime/plundarr-vpn-test.sh`.
5. Brings the Compose stack down.
6. Restores example config again.

Generate the downloader mode before the test voyage. Plundarr and Boudoirr use
qBittorrent by default; switch to SABnzbd-only with:

> [!TIP]
>
> ```sh
> make ship REMOVE_SERVICES=qbittorrent,cleanuparr ADD_SERVICES=sabnzbd
> make test-e2e
> ```

Chart the same E2E voyage with NZBGet instead:

> [!TIP]
>
> ```sh
> make ship REMOVE_SERVICES=qbittorrent,cleanuparr ADD_SERVICES=nzbget
> make test-e2e
> ```

Keep qBittorrent and add either Usenet client when ye want both downloader
types tested together, for example `make ship ADD_SERVICES=sabnzbd`.

### Full Stack Test

Use this when ye want Make to launch every service, wait for health, and validate the full port-forwarding chain:

> [!TIP]
>
> ```sh
> make test-stack
> ```

This target:

1. Restores example config.
2. Starts every Compose service.
3. Waits for healthcheck-enabled containers to report healthy.
4. Verifies Privateerr output, Gluetun health, Gluetun forwarded port, and qBittorrent port sync.
5. Leaves the stack running on success.
6. Prints Compose status and recent logs on failure.
7. Restores example config after validation.

> [!WARNING]
> 🧨 VPN tests can involve real PIA credentials in `.env`. 🧨
>
> Do not commit live credentials, generated WireGuard VPN configs, forwarded ports, or logs from yer secret treasure chest. 🪎

## Example Files 📜

The [examples](https://github.com/scottgigawatt/plundarr/tree/main/test/examples) directory stores example files used to reset the repo after a live run:

- [examples/example-wg0.conf](https://github.com/scottgigawatt/plundarr/blob/main/test/examples/example-wg0.conf)
- [examples/example-privateerr.env](https://github.com/scottgigawatt/plundarr/blob/main/test/examples/example-privateerr.env)

These files match the Privateerr examples exactly. Cleanup targets copy them
back into `dist/<preset>/config/gluetun/wireguard/` so live secrets do not
accidentally sneak into Git.

Useful cleanup commands:

> [!CAUTION]
>
> ```sh
> make clean-test
> make restore-test-config
> make nuke
> make clean
> ```

`make delete-config` is deliberately absent from that routine cleanup example:
it destroys the selected deployment's application state.

> [!TIP]
> 🏴‍☠️ Run cleanup before committing after any real VPN voyage. _Future ye will thank past ye!_
