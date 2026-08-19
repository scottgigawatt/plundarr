#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# notify-discord.sh: Send randomized Maraudarr build notifications to an
#                    optional Discord webhook without exposing its value.
#
# Usage: DISCORD_WEBHOOK_URL=<url> notify-discord.sh --event <start|verdict> \
#        --template <shipyard|kraken> --run-url <url> \
#        --repository <owner/repository> --ref-name <ref> [event options]
#

#
# Keep only the webhook credential in the environment. All public workflow
# metadata and behavior arrive through documented command-line flags.
#
: "${DISCORD_WEBHOOK_URL:=}"
actor=""
discord_dry_run=false
discord_event=""
discord_random_value=""
discord_template=""
dockerhub_image=""
dockerhub_url=""
ghcr_image=""
ghcr_package_url=""
image_platforms=""
job_status=""
published_digest=""
published_tags=""
ref_name=""
repository=""
run_url=""
workflow_name=""

#
# Fail on errors and unset variables.
#
set -eu

#
# usage: Print command-line options for both build notification events.
#
# Parameters: None.
#
# Returns:     Prints usage text.
#
usage() {
    printf '%s\n' \
        "Usage: $0 --event <start|verdict> --template <shipyard|kraken>" \
        "          --run-url <url> --repository <owner/repository>" \
        "          --ref-name <ref> [event options]" \
        "" \
        "Start options:" \
        "  -w, --workflow-name <name>" \
        "  -a, --actor <actor>" \
        "  -p, --platforms <platforms>" \
        "  -g, --ghcr-image <image>" \
        "  -d, --dockerhub-image <image>" \
        "" \
        "Verdict options:" \
        "  -s, --job-status <status>" \
        "  -g, --ghcr-image <image>" \
        "  -c, --ghcr-package-url <url>" \
        "  -b, --dockerhub-url <url>" \
        "  -l, --published-tags <tags>" \
        "  -i, --published-digest <digest>" \
        "" \
        "Common options:" \
        "  -e, --event <start|verdict>" \
        "  -t, --template <shipyard|kraken>" \
        "  -u, --run-url <url>" \
        "  -r, --repository <owner/repository>" \
        "  -f, --ref-name <ref>" \
        "  -n, --random-value <integer>" \
        "  -x, --dry-run" \
        "  -h, --help"
}

#
# require_option_argument: Reject a flag whose value is missing.
#
# Parameters: $1 - Option name.
#             $2 - Number of remaining command-line arguments.
#
# Returns:     0 when a value follows; otherwise exits with status 2.
#
require_option_argument() {
    if [ "$2" -lt 2 ]; then
        printf '%s requires a value.\n' "$1" >&2
        exit 2
    fi
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        -e | --event)
            require_option_argument "$1" "$#"
            discord_event=$2
            shift 2
            ;;
        -t | --template)
            require_option_argument "$1" "$#"
            discord_template=$2
            shift 2
            ;;
        -u | --run-url)
            require_option_argument "$1" "$#"
            run_url=$2
            shift 2
            ;;
        -r | --repository)
            require_option_argument "$1" "$#"
            repository=$2
            shift 2
            ;;
        -f | --ref-name)
            require_option_argument "$1" "$#"
            ref_name=$2
            shift 2
            ;;
        -w | --workflow-name)
            require_option_argument "$1" "$#"
            workflow_name=$2
            shift 2
            ;;
        -a | --actor)
            require_option_argument "$1" "$#"
            actor=$2
            shift 2
            ;;
        -p | --platforms)
            require_option_argument "$1" "$#"
            image_platforms=$2
            shift 2
            ;;
        -g | --ghcr-image)
            require_option_argument "$1" "$#"
            ghcr_image=$2
            shift 2
            ;;
        -d | --dockerhub-image)
            require_option_argument "$1" "$#"
            dockerhub_image=$2
            shift 2
            ;;
        -s | --job-status)
            require_option_argument "$1" "$#"
            job_status=$2
            shift 2
            ;;
        -c | --ghcr-package-url)
            require_option_argument "$1" "$#"
            ghcr_package_url=$2
            shift 2
            ;;
        -b | --dockerhub-url)
            require_option_argument "$1" "$#"
            dockerhub_url=$2
            shift 2
            ;;
        -l | --published-tags)
            require_option_argument "$1" "$#"
            published_tags=$2
            shift 2
            ;;
        -i | --published-digest)
            require_option_argument "$1" "$#"
            published_digest=$2
            shift 2
            ;;
        -n | --random-value)
            require_option_argument "$1" "$#"
            discord_random_value=$2
            shift 2
            ;;
        -x | --dry-run)
            discord_dry_run=true
            shift
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

#
# random_value: Produce a non-negative integer for message selection.
#
# Parameters: None.
#
# Returns:     Prints deterministic test input, operating-system randomness,
#              or a portable timestamp checksum fallback.
#
random_value() {
    if [ -n "${discord_random_value}" ]; then
        case "${discord_random_value}" in
            *[!0-9]*)
                echo "--random-value must be a non-negative integer." >&2
                return 1
                ;;
        esac
        printf '%s\n' "${discord_random_value}"
        return 0
    fi

    if [ -r /dev/urandom ] && command -v od >/dev/null 2>&1; then
        value=$(od -An -N4 -tu4 /dev/urandom | awk 'NF {print $1; exit}')
        if [ -n "${value}" ]; then
            printf '%s\n' "${value}"
            return 0
        fi
    fi

    printf '%s' "$(date +%s)-$$-${discord_template}-${discord_event}" \
        | cksum \
        | awk '{print $1}'
}

#
# choose_message: Select one supplied message without evaluating its contents.
#
# Parameters: $@ - One or more complete message strings.
#
# Returns:     Prints exactly one selected message.
#
choose_message() {
    if [ "$#" -eq 0 ]; then
        echo "choose_message requires at least one message." >&2
        return 1
    fi

    value=$(random_value)
    choice=$((value % $# + 1))
    while [ "${choice}" -gt 1 ]; do
        shift
        choice=$((choice - 1))
    done
    printf '%s\n' "$1"
}

#
# require_value: Reject a missing workflow input with a useful field name.
#
# Parameters: $1 - Input name.
#             $2 - Input value.
#
# Returns:     0 when present; otherwise returns 1.
#
require_value() {
    if [ -z "$2" ]; then
        printf '%s is required.\n' "$1" >&2
        return 1
    fi
}

#
# Skip optional notifications without revealing whether a secret exists.
# Dry runs deliberately continue without a webhook for local payload tests.
#
if [ -z "${DISCORD_WEBHOOK_URL}" ] && [ "${discord_dry_run}" != "true" ]; then
    echo "Discord webhook is not configured; skipping notification."
    exit 0
fi

require_value --event "${discord_event}"
require_value --template "${discord_template}"
require_value --run-url "${run_url}"
require_value --repository "${repository}"
require_value --ref-name "${ref_name}"

#
# Select the destination's identity and stable field labels.
#
case "${discord_template}" in
    shipyard)
        username="Maraudarr Deck Crew"
        repository_label="🗺️ Repository"
        actor_label="🧑‍✈️ Captain"
        ;;
    kraken)
        username="Kraken Build Bureau"
        repository_label="⚓ Repository"
        actor_label="🔘 Button Pusher"
        ;;
    *)
        echo "--template must be shipyard or kraken." >&2
        exit 1
        ;;
esac

#
# Choose a randomized message from the event, destination, and status family.
#
case "${discord_event}" in
    start)
        require_value --workflow-name "${workflow_name}"
        require_value --actor "${actor}"
        require_value --platforms "${image_platforms}"
        require_value --ghcr-image "${ghcr_image}"
        require_value --dockerhub-image "${dockerhub_image}"

        if [ "${discord_template}" = "shipyard" ]; then
            title="🏴‍☠️ Shipyard doors are open"
            description=$(choose_message \
                "${workflow_name} entered the shipyard with confidence wildly disproportionate to the crew's qualifications." \
                "Maraudarr is being assembled from Alpine, optimism, and several legally distinct varieties of duct tape." \
                "The build cannons are loaded. Procurement denies ordering cannons, but the receipt says no refunds." \
                "Someone rang the release bell. The containers put on tiny hats and are pretending this was rehearsed." \
                "OSHA declined jurisdiction, the YAML retained counsel, and ${workflow_name} sailed anyway." \
                "Please keep fingers clear of the build cache and emotional-support manifests.")
            footer="Maraudarr Shipyard • seaworthy is a spectrum"
            color=3447003
        else
            title="🦑 Kraken clocked in"
            description=$(choose_message \
                "${workflow_name} started. The kraken signed eight timesheets and immediately requested overtime." \
                "Three architectures, eight tentacles, and absolutely no respect for personal space." \
                "The kraken assumed build control after completing a four-minute online certification." \
                "Every tentacle has a task. Unfortunately, two tasks are snacks and one is aggressive jazz hands." \
                "The kraken insists the bubbles are part of the observability stack." \
                "The kraken pressed every button at once. Against all engineering guidance, this begins the build.")
            footer="Kraken Build Bureau • tentacle-driven development"
            color=10181046
        fi
        ;;
    verdict)
        require_value --job-status "${job_status}"
        require_value --ghcr-image "${ghcr_image}"

        if [ "${job_status}" = "success" ]; then
            color=3066993
            if [ "${discord_template}" = "shipyard" ]; then
                title="✅ Fleet launched"
                description=$(choose_message \
                    "Both registries agree on a digest. Historians are calling it the first successful group project." \
                    "Maraudarr reached both registries and immediately began acting like this was always the plan." \
                    "Docker Hub and GHCR exchanged friendship bracelets and one suspicious checksum." \
                    "The duct tape is now structural, certified, and eligible for a promotion." \
                    "The release goblins demand payment in cache layers and tiny sandwiches." \
                    "The fleet is live. Please applaud quietly; the provenance attestation is sleeping.")
                footer="Maraudarr Shipyard • receipts attached, alibis pending"
            else
                title="🦑 Kraken stamped approved"
                description=$(choose_message \
                    "Images published everywhere. The kraken requests credit for standing nearby." \
                    "Eight tentacles are high-fiving, which has become a serious scheduling problem." \
                    "The kraken promoted itself to Senior Principal Button Presser." \
                    "One tentacle is already writing a memoir about the successful deployment." \
                    "The kraken celebrated by opening eight pull requests and reviewing none of them." \
                    "Maritime law requires us to pretend the kraken followed the runbook.")
                footer="Kraken Build Bureau • eight arms, one victory lap"
            fi
        else
            color=15158332
            if [ "${discord_template}" = "shipyard" ]; then
                title="💥 Build hit a reef"
                description=$(choose_message \
                    "Maraudarr ended ${job_status}. The stack trace now owns waterfront property." \
                    "The build became an artisanal collection of logs arranged by emotional damage." \
                    "The error message requested a lawyer and better lighting." \
                    "The release goblins have formed an independent commission." \
                    "The fleet produced a breathtaking quantity of actionable regret." \
                    "A dependency sneezed and the ship folded into a tasteful pile of diagnostics.")
                footer="Maraudarr Shipyard • the logs know what they did"
            else
                title="🦑 Kraken misplaced the build"
                description=$(choose_message \
                    "Publication ended ${job_status}. Every tentacle is pointing at a different log." \
                    "The kraken pulled eight levers and somehow all of them were wrong." \
                    "The kraken classified the crater as an undocumented feature." \
                    "Eight tentacles searched for the manifest; nine excuses returned." \
                    "The kraken is deleting its browser history with suspicious urgency." \
                    "The bubbles are no longer part of observability.")
                footer="Kraken Build Bureau • accountability remains underwater"
            fi
        fi
        ;;
    *)
        echo "--event must be start or verdict." >&2
        exit 1
        ;;
esac

#
# Build event-specific Discord JSON through jq so workflow metadata remains data
# instead of executable shell content.
#
if [ "${discord_event}" = "start" ]; then
    payload=$(jq -n \
        --arg username "${username}" \
        --arg title "${title}" \
        --arg description "${description}" \
        --arg url "${run_url}" \
        --arg repository "${repository}" \
        --arg ref "${ref_name}" \
        --arg actor "${actor}" \
        --arg platforms "${image_platforms}" \
        --arg ghcr "${ghcr_image}" \
        --arg dockerhub "${dockerhub_image}" \
        --arg footer "${footer}" \
        --arg repository_label "${repository_label}" \
        --arg actor_label "${actor_label}" \
        --argjson color "${color}" \
        '{
            username: $username,
            embeds: [{
                title: $title,
                description: $description,
                url: $url,
                color: $color,
                fields: [
                    {name: $repository_label, value: $repository, inline: true},
                    {name: "🌿 Ref", value: $ref, inline: true},
                    {name: $actor_label, value: $actor, inline: true},
                    {name: "🧱 Platforms", value: $platforms, inline: false},
                    {name: "📦 GHCR", value: $ghcr, inline: false},
                    {name: "🐳 Docker Hub", value: $dockerhub, inline: false}
                ],
                footer: {text: $footer},
                timestamp: now | todate
            }]
        }')
else
    formatted_tags=$(printf '%s\n' "${published_tags:-none}" \
        | sed '/^$/d; s#^'"${ghcr_image}"':##; s/^/• /')
    [ -n "${formatted_tags}" ] || formatted_tags="none"
    digest_short=$(printf '%s' "${published_digest:-unavailable}" \
        | sed -E 's/^(sha256:[0-9a-f]{12}).*/\1/')

    payload=$(jq -n \
        --arg username "${username}" \
        --arg title "${title}" \
        --arg description "${description}" \
        --arg url "${run_url}" \
        --arg repository "${repository}" \
        --arg ref "${ref_name}" \
        --arg tags "${formatted_tags}" \
        --arg digest "${digest_short}" \
        --arg ghcr_url "${ghcr_package_url:-unavailable}" \
        --arg dockerhub_url "${dockerhub_url:-unavailable}" \
        --arg footer "${footer}" \
        --arg repository_label "${repository_label}" \
        --argjson color "${color}" \
        '{
            username: $username,
            embeds: [{
                title: $title,
                description: $description,
                url: $url,
                color: $color,
                fields: [
                    {name: $repository_label, value: $repository, inline: true},
                    {name: "🌿 Ref", value: $ref, inline: true},
                    {name: "🏷️ Tags", value: $tags, inline: false},
                    {name: "🧾 Digest", value: $digest, inline: false},
                    {name: "📦 GHCR", value: $ghcr_url, inline: false},
                    {name: "🐳 Docker Hub", value: $dockerhub_url, inline: false}
                ],
                footer: {text: $footer},
                timestamp: now | todate
            }]
        }')
fi

#
# Dry runs expose only the public payload for deterministic local tests.
#
if [ "${discord_dry_run}" = "true" ]; then
    printf '%s\n' "${payload}"
    exit 0
fi

#
# Deliver the payload without logging the webhook URL or JSON body.
#
curl \
    --fail \
    --silent \
    --show-error \
    --header "Content-Type: application/json" \
    --data "${payload}" \
    "${DISCORD_WEBHOOK_URL}"
