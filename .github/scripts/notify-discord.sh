#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# notify-discord.sh: Send a named Maraudarr build notification to an optional
#                    Discord webhook without exposing the webhook value.
#
# Usage: DISCORD_TEMPLATE=<shipyard|kraken> DISCORD_WEBHOOK_URL=<url> \
#        RUN_URL=<url> WORKFLOW_NAME=<name> REF_NAME=<ref> ACTOR=<actor> \
#        REPOSITORY=<owner/repository> IMAGE_PLATFORMS=<platforms> \
#        GHCR_IMAGE=<image> DOCKERHUB_IMAGE=<image> sh .github/scripts/notify-discord.sh
#

#
# Fail on errors and unset variables after optional webhook normalization.
#
: "${DISCORD_WEBHOOK_URL:=}"
set -eu

#
# Skip optional notifications without revealing whether a secret is configured.
#
if [ -z "${DISCORD_WEBHOOK_URL}" ]; then
    echo "Discord webhook is not configured; skipping notification."
    exit 0
fi

#
# Select the approved presentation template without accepting arbitrary payload
# fields from a workflow expression.
#
case "${DISCORD_TEMPLATE:-}" in
    shipyard)
        username="Maraudarr Deck Crew"
        title="🏴‍☠️ Shipyard doors are open"
        description="${WORKFLOW_NAME} is building the fleet. Keep hands, feet, and cursed YAML inside the workflow."
        footer="Maraudarr Shipyard • bolts tightened, YAML questioned"
        color=3447003
        repository_label="🗺️ Repository"
        actor_label="🧑‍✈️ Captain"
        ;;
    kraken)
        username="Kraken Build Bureau"
        title="🦑 Kraken clocked in"
        description="${WORKFLOW_NAME} started a multi-arch build. The kraken found the button and accepted no training."
        footer="Kraken Build Bureau • too many arms, adequate supervision"
        color=10181046
        repository_label="⚓ Repository"
        actor_label="🔘 Button Pusher"
        ;;
    *)
        echo "DISCORD_TEMPLATE must be shipyard or kraken." >&2
        exit 1
        ;;
esac

#
# Build Discord JSON through jq so workflow metadata remains data, not shell.
#
payload="$(jq -n \
    --arg username "${username}" \
    --arg title "${title}" \
    --arg description "${description}" \
    --arg url "${RUN_URL}" \
    --arg repository "${REPOSITORY}" \
    --arg ref "${REF_NAME}" \
    --arg actor "${ACTOR}" \
    --arg platforms "${IMAGE_PLATFORMS}" \
    --arg ghcr "${GHCR_IMAGE}" \
    --arg dockerhub "${DOCKERHUB_IMAGE}" \
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
    }')"

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
