# Workflow Helper Chart ⚙️

These helpers keep reusable release, notification, registry, and preset reference logic out of workflow `run` blocks. Workflows provide metadata through explicit long options and reserve environment variables for credentials.

## Helper Chart 🧭

| Helper                    | Purpose                                                            |
| ------------------------- | ------------------------------------------------------------------ |
| `discord-notifier.sh`     | Validate inputs, render a selected jq payload, and notify Discord  |
| `registry-mirror.sh`      | Copy published container tags from GHCR to Docker Hub              |
| `validate-release-tag.sh` | Require annotated SemVer release tags whose commits belong to main |
| `update_preset_examples.py` | Commit validated public reference pairs to the current PR branch |

`discord-notifier.sh` reads the stable profiles, themed strings, presentation
values, and payload shapes documented in the
[Discord wardrobe](../discord/README.md). `registry-mirror.sh` verifies copied
manifest digests instead of trusting a successful transfer alone.

## Workflow Consumers 🧵

`build-and-push.yml` uses all three helpers for guarded multi-registry image
publication. The notifier also supports a documentation profile for workflows
that publish a site. Keeping the helpers and structured assets byte-identical
lets sibling repositories reuse them while reviewing each workflow locally.

## Offline Validation 🧪

Run the complete helper and publishing-policy suite without contacting Discord
or either container registry:

> [!TIP]
>
> ```sh
> make test-workflows
> ```

The suite uses temporary Git repositories, deterministic payload selection, and
a local Skopeo stub. It covers short and long options, release-tag rejection,
message rendering, registry mirroring, digest comparison, synchronized build
pins, and canonical image-tag channels.

## Preset reference updates

`validate-pr.yml` runs `update_preset_examples.py` from the reviewed base commit after generated references pass validation. It accepts only bounded Compose/example environment pairs, checks that the same-repository PR head is unchanged, and updates its branch without force. It explicitly dispatches validation and CodeQL for the resulting commit. Fork PRs receive downloadable references without repository write access.
