#!/bin/sh

#
# set-inotify-limits.sh: Raises Linux inotify limits on Synology to support
#                        large Plex media libraries.
#
# Plex uses inotify watches to monitor folders for changes. When the default
# limits are too low, Plex can fail to watch all directories and may log
# errors like:
#   "Failed to add watch (28: No space left on device)"
#
# Example:
#   A system with 20,000 media folders across Movies, TV, and Music cannot
#   operate reliably with the default 8,192 watch limit. Raising the limit
#   to 262,144 allows Plex to monitor the full library with room to grow.
#
# These limits are appropriate for systems with large RAM capacity such as
# a DS1522+ with 32 GB memory. The kernel only consumes memory for watches
# actually in use, so increasing the ceiling does not force full allocation.
#
# The script:
#   - Detects a usable sysctl binary
#   - Raises inotify watch, instance, and queue limits immediately
#   - Verifies the values were applied
#   - Writes a persistent sysctl drop-in if supported
#

echo "Starting script to raise inotify limits for Plex."

WATCHES_DEFAULT="262144"
INSTANCES_DEFAULT="2048"
QUEUED_EVENTS_DEFAULT="65536"

WATCHES="${WATCHES:-$WATCHES_DEFAULT}"
INSTANCES="${INSTANCES:-$INSTANCES_DEFAULT}"
QUEUED_EVENTS="${QUEUED_EVENTS:-$QUEUED_EVENTS_DEFAULT}"

SYSCTL_BIN=""

# Find sysctl in common Synology locations
if [ -x /sbin/sysctl ]; then
    SYSCTL_BIN="/sbin/sysctl"
elif [ -x /usr/sbin/sysctl ]; then
    SYSCTL_BIN="/usr/sbin/sysctl"
elif [ -x /bin/sysctl ]; then
    SYSCTL_BIN="/bin/sysctl"
elif [ -x /usr/bin/sysctl ]; then
    SYSCTL_BIN="/usr/bin/sysctl"
fi

# Ensure script is running as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must run as root."
    exit 1
fi

# Ensure sysctl exists
if [ -z "$SYSCTL_BIN" ]; then
    echo "sysctl binary not found."
    exit 1
fi

set_and_verify() {
    KEY="$1"
    VALUE="$2"

    echo "Setting $KEY to $VALUE."
    "$SYSCTL_BIN" -w "$KEY=$VALUE" >/dev/null 2>&1

    CURRENT="$("$SYSCTL_BIN" -n "$KEY" 2>/dev/null)"

    if [ "$CURRENT" != "$VALUE" ]; then
        echo "Failed to set $KEY. Expected $VALUE but got $CURRENT."
        exit 1
    fi

    echo "$KEY successfully set to $CURRENT."
}

# Apply settings immediately
set_and_verify "fs.inotify.max_user_watches" "$WATCHES"
set_and_verify "fs.inotify.max_user_instances" "$INSTANCES"
set_and_verify "fs.inotify.max_queued_events" "$QUEUED_EVENTS"

# Persist configuration if sysctl.d exists
if [ -d /etc/sysctl.d ]; then
    CONF_FILE="/etc/sysctl.d/99-plundarr-inotify.conf"

    echo "Writing persistent configuration to $CONF_FILE."

    cat > "$CONF_FILE" <<EOF
# Managed by plundarr: inotify limits for Plex
fs.inotify.max_user_watches=$WATCHES
fs.inotify.max_user_instances=$INSTANCES
fs.inotify.max_queued_events=$QUEUED_EVENTS
EOF

    chmod 0644 "$CONF_FILE"
    echo "Persistent configuration written."
else
    echo "/etc/sysctl.d not found. Skipping persistent configuration."
fi

echo "Final inotify values:"
"$SYSCTL_BIN" fs.inotify.max_user_watches 2>/dev/null
"$SYSCTL_BIN" fs.inotify.max_user_instances 2>/dev/null
"$SYSCTL_BIN" fs.inotify.max_queued_events 2>/dev/null

echo "Script execution completed."
