#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# docker-socket.sh: This script is intended to run directly on Synology NAS to
#                   grant the docker group access to the Docker daemon socket
#                   after Container Manager starts.
#
# Synology can recreate /var/run/docker.sock with root-only group ownership
# after a reboot or Container Manager update. Run this script as root from a
# boot-up task after creating a docker group and adding trusted users to it.
#
# The script:
#   - Verifies it is running as root.
#   - Verifies the Synology docker group exists.
#   - Waits up to 120 seconds for the Docker daemon socket to appear.
#   - Assigns the socket to root:docker with group read/write access.
#

set -eu

echo "Starting script to configure Docker socket permissions."

#
# Docker socket settings and boot-time wait limits.
#
DOCKER_SOCKET="/var/run/docker.sock"
DOCKER_GROUP="docker"
WAIT_TIME=0
MAX_WAIT=120
WAIT_INTERVAL=2

#
# Ensure the script is running as root.
#
if [ "$(id -u)" != "0" ]; then
    echo "ERROR: This script must run as root."
    exit 1
fi

#
# Ensure the Synology docker group exists before changing socket ownership.
#
if ! synogroup --get "$DOCKER_GROUP" >/dev/null 2>&1; then
    echo "ERROR: Synology group '$DOCKER_GROUP' does not exist."
    echo "Create it in DSM and add each trusted Docker user before retrying."
    exit 1
fi

#
# Wait for Container Manager to create the Docker daemon socket during boot.
#
while [ ! -S "$DOCKER_SOCKET" ]; do
    if [ "$WAIT_TIME" -ge "$MAX_WAIT" ]; then
        echo "ERROR: Docker socket did not appear at $DOCKER_SOCKET after $MAX_WAIT seconds."
        exit 1
    fi

    echo "Docker socket is not ready. Waiting..."
    sleep "$WAIT_INTERVAL"
    WAIT_TIME=$((WAIT_TIME + WAIT_INTERVAL))
done

#
# Grant the docker group read/write access without exposing the socket to
# untrusted users.
#
echo "Setting $DOCKER_SOCKET ownership to root:$DOCKER_GROUP."
chown "root:$DOCKER_GROUP" "$DOCKER_SOCKET"

echo "Setting $DOCKER_SOCKET permissions to 0660."
chmod 0660 "$DOCKER_SOCKET"

echo "Docker socket permissions configured successfully."
