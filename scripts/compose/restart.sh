#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# restart.sh: Run directly on a Docker host to stop and restart a Compose
#             project in a predictable way.
#
# The script:
#   - Accepts one Compose-project directory.
#   - Waits up to 60 seconds for the Docker daemon during host boot.
#   - Detects Docker Compose v2 or v1.
#   - Restarts the stack without deleting named volumes or application state.
#
# Usage: sh scripts/compose/restart.sh /path/to/project
#

#
# Exit on errors and unset variables.
#
set -eu

#
# Check if a directory path was provided as an argument.
#
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 /path/to/compose/project"
    exit 1
fi

PROJECT_DIR="$1"

#
# Wait for Docker daemon to become available.
#
echo "Checking if Docker daemon is available..."
WAIT_TIME=0
MAX_WAIT=60

#
# Loop until Docker is available or the maximum wait time is reached.
#
while ! docker info >/dev/null 2>&1; do
    # If the wait time exceeds the maximum, exit with an error.
    if [ "$WAIT_TIME" -ge "$MAX_WAIT" ]; then
        echo "ERROR: Docker daemon did not become available after $MAX_WAIT seconds."
        exit 1
    fi
    echo "Docker daemon not ready. Waiting..."
    sleep 2
    WAIT_TIME=$((WAIT_TIME + 2))
done

#
# Change to the specified project directory, or exit with error if not found.
#
CDPATH='' cd -- "$PROJECT_DIR" || {
    echo "ERROR: Could not find project directory at $PROJECT_DIR"
    exit 1
}

#
# Extract the last part of the directory path to use as a human-readable name.
#
PROJECT_NAME=$(basename "$PROJECT_DIR")

#
# Detect whether to use 'docker compose' or 'docker-compose'.
#
if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
else
    echo "ERROR: Neither 'docker compose' nor 'docker-compose' was found on this system."
    exit 1
fi

#
# Tear down the running stack while preserving named volumes and application state.
#
echo "Stopping current containers for '$PROJECT_NAME' while preserving volumes..."
$COMPOSE_CMD down --remove-orphans

#
# Rebuild and start the stack in detached mode.
#
echo "Rebuilding and starting containers for '$PROJECT_NAME' with enforced startup order..."
$COMPOSE_CMD up -d

#
# Report success.
#
echo "'$PROJECT_NAME' stack restarted successfully."
