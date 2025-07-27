#!/bin/sh

#
# compose_restart.sh: This script is designed for Synology NAS (or any Linux system) to fully stop,
#                     clean, and rebuild a Docker Compose project in a predictable and reliable way.
#
# The script:
#   - Accepts a single argument: the path to a Docker Compose project directory.
#   - Waits up to 60 seconds for the Docker CLI to become available (on boot).
#   - Navigates to the specified project directory and extracts a project name.
#   - Detects whether to use 'docker compose' (v2) or 'docker-compose' (v1).
#   - Shuts down all containers and removes volumes using 'down -v'.
#   - Rebuilds and starts the stack using 'up -d'.
#   - Logs status messages throughout for visibility and debugging.
#
# Usage: sh compose_restart.sh /path/to/project
#

# Check if a directory path was provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 /path/to/compose/project"
    exit 1
fi

PROJECT_DIR="$1"

# Wait for Docker daemon to become available (max 60 seconds)
echo "Checking if Docker daemon is available..."
WAIT_TIME=0
MAX_WAIT=60

while ! docker info >/dev/null 2>&1; do
    if [ "$WAIT_TIME" -ge "$MAX_WAIT" ]; then
        echo "ERROR: Docker daemon did not become available after $MAX_WAIT seconds."
        exit 1
    fi
    echo "Docker daemon not ready. Waiting..."
    sleep 2
    WAIT_TIME=$((WAIT_TIME + 2))
done

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
