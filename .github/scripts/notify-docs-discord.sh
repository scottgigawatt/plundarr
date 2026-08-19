#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# notify-docs-discord.sh: Send a randomized GitHub Pages deployment verdict to
#                         the project's optional primary Discord webhook.
#
# Usage: DISCORD_WEBHOOK_URL=<url> notify-docs-discord.sh \
#        --build-status <status> --deploy-status <status> --run-url <url> \
#        --repository <owner/repository> --ref-name <ref> [options]
#

#
# Keep only the webhook credential in the environment. All public workflow
# metadata and behavior arrive through documented command-line flags.
#
: "${DISCORD_WEBHOOK_URL:=}"
build_status=""
deploy_status=""
discord_dry_run=false
discord_random_value=""
ref_name=""
repository=""
run_url=""
site_url="unavailable"

#
# Discord embed colors stored by visual role instead of opaque decimal values.
#
discord_color_failure_red=15158332
discord_color_success_green=3066993

#
# Fail on errors and unset variables.
#
set -eu

#
# usage: Print command-line options for documentation verdict notifications.
#
# Parameters: None.
#
# Returns: Prints usage text.
#
usage() {
    printf '%s\n' \
        "Usage: $0 --build-status <status> --deploy-status <status>" \
        "          --run-url <url> --repository <owner/repository>" \
        "          --ref-name <ref> [options]" \
        "" \
        "Options:" \
        "  -b, --build-status <status>" \
        "  -d, --deploy-status <status>" \
        "  -u, --run-url <url>" \
        "  -s, --site-url <url>" \
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
# Returns: 0 when a value follows; otherwise exits with status 2.
#
require_option_argument() {
    if [ "$2" -lt 2 ]; then
        printf '%s requires a value.\n' "$1" >&2
        exit 2
    fi
}

#
# Parse command-line flags and arguments.
#
while [ "$#" -gt 0 ]; do
    case "$1" in
        -b | --build-status)
            require_option_argument "$1" "$#"
            build_status=$2
            shift 2
            ;;
        -d | --deploy-status)
            require_option_argument "$1" "$#"
            deploy_status=$2
            shift 2
            ;;
        -u | --run-url)
            require_option_argument "$1" "$#"
            run_url=$2
            shift 2
            ;;
        -s | --site-url)
            require_option_argument "$1" "$#"
            site_url=$2
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
# Returns: Prints deterministic test input, operating-system randomness,
#          or a portable timestamp checksum fallback.
#
random_value() {
    # Use the supplied random value if present, but validate it first.
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

    # Use /dev/urandom if available, but fall back to a portable checksum.
    if [ -r /dev/urandom ] && command -v od >/dev/null 2>&1; then
        value=$(od -An -N4 -tu4 /dev/urandom | awk 'NF {print $1; exit}')
        if [ -n "${value}" ]; then
            printf '%s\n' "${value}"
            return 0
        fi
    fi

    # Fallback to a portable timestamp checksum if no other source is available.
    printf '%s' "$(date +%s)-$$-${build_status}-${deploy_status}" \
        | cksum \
        | awk '{print $1}'
}

#
# choose_message: Select one supplied message without evaluating its contents.
#
# Parameters: $@ - One or more complete message strings.
#
# Returns: Prints exactly one selected message.
#
choose_message() {
    # Validate that at least one message is supplied.
    if [ "$#" -eq 0 ]; then
        echo "choose_message requires at least one message." >&2
        return 1
    fi

    # Use a random value to select one of the supplied messages.
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
# Returns: 0 when present; otherwise returns 1.
#
require_value() {
    # Validate that a required input is present.
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
    echo "Discord webhook is not configured; skipping documentation notification."
    exit 0
fi

#
# Validate required workflow inputs and provide a useful error message.
#
require_value --build-status "${build_status}"
require_value --deploy-status "${deploy_status}"
require_value --run-url "${run_url}"
require_value --repository "${repository}"
require_value --ref-name "${ref_name}"
[ -n "${site_url}" ] || site_url="unavailable"

#
# Determine the appropriate message based on build and deploy status.
#
if [ "${build_status}" = "success" ] \
    && [ "${deploy_status}" = "success" ]; then
    title="📚 Developer charts escaped into the wild"
    description=$(choose_message \
        "MkDocs finished without screaming. The hyperlinks formed a union but agreed to deploy after snack negotiations." \
        "The treasure maps are freshly laminated, alphabetized, and only mildly haunted by deprecated flags." \
        "The documentation is live. Every comma was inspected, and three were released on their own recognizance." \
        "The site deployed successfully and immediately developed opinions about your browser's color scheme." \
        "The docs escaped containment and are now teaching strangers how to operate Docker. Legally, this is outreach." \
        "Pages accepted the charts after a rigorous review by one lighthouse and a raccoon in a safety vest.")
    footer="Plundarr Chart Room • facts deployed under adult supervision"
    color=${discord_color_success_green}
else
    title="💥 The chart room has become conceptual"
    description=$(choose_message \
        "The docs fell down the stairs alphabetically. MkDocs is reconstructing the table of contents from witness statements." \
        "A semicolon wandered into Markdown. There are no survivors, only a very judgmental build log." \
        "The documentation ship has become a 404-shaped submarine." \
        "Pages declined the deployment and slid a note under the door reading only: absolutely not." \
        "The chart room renovation uncovered load-bearing Markdown." \
        "A hyperlink achieved sentience, rejected its destination, and took the navigation menu with it.")
    footer="Plundarr Chart Room • the footnotes demand representation"
    color=${discord_color_failure_red}
fi

#
# Build Discord JSON through jq so workflow metadata remains data instead of
# executable shell content.
#
payload=$(jq -n \
    --arg title "${title}" \
    --arg description "${description}" \
    --arg url "${run_url}" \
    --arg repository "${repository}" \
    --arg ref "${ref_name}" \
    --arg build_status "${build_status}" \
    --arg deploy_status "${deploy_status}" \
    --arg site_url "${site_url}" \
    --arg footer "${footer}" \
    --argjson color "${color}" \
    '{
        username: "Plundarr Chart Room",
        embeds: [{
            title: $title,
            description: $description,
            url: $url,
            color: $color,
            fields: [
                {name: "🗺️ Repository", value: $repository, inline: true},
                {name: "🌿 Ref", value: $ref, inline: true},
                {name: "🪚 Build", value: $build_status, inline: true},
                {name: "🚀 Deploy", value: $deploy_status, inline: true},
                {name: "📚 Documentation", value: $site_url, inline: false}
            ],
            footer: {text: $footer},
            timestamp: now | todate
        }]
    }')

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
