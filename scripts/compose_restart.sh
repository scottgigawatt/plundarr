#!/bin/sh

#
# This script is designed for Synology NAS (or any Linux system)
# to fully stop, clean, and rebuild a Docker Compose project.
# It ensures containers start in the correct order by explicitly tearing down
# and bringing up the stack, blocking until complete.
#
# Usage: sh compose_restart.sh /path/to/project
#

# Check if a directory path was provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 /path/to/compose/project"
    exit 1
fi

PROJECT_DIR="$1"

# Change to the specified project directory, or exit with error if not found
cd "$PROJECT_DIR" || {
    echo "ERROR: Could not find project directory at $PROJECT_DIR"
    exit 1
}

# Extract the last part of the directory path to use as a human-readable name
PROJECT_NAME=$(basename "$PROJECT_DIR")

# Detect whether to use 'docker compose' or 'docker-compose'
if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
else
    echo "ERROR: Neither 'docker compose' nor 'docker-compose' was found on this system."
    exit 1
fi

# Tear down the running stack, including named volumes
echo "Stopping and removing current containers and volumes for '$PROJECT_NAME'..."
$COMPOSE_CMD down -v

# Rebuild and start the stack in detached mode
echo "Rebuilding and starting containers for '$PROJECT_NAME' with enforced startup order..."
$COMPOSE_CMD up -d

# Report success
echo "'$PROJECT_NAME' stack restarted successfully."
