#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# tun.sh: This script is intended to run directly on Synology NAS to ensure
#         the /dev/net/tun device exists for VPN applications like Gluetun.
#
# The script:
#   - Verifies if /dev/net/tun exists and creates it if missing.
#   - Creates the /dev/net directory if it doesn't exist.
#   - Creates the tun device node with the correct major/minor numbers.
#   - Sets the appropriate permissions on the device node.
#   - Loads the tun kernel module if it's not already loaded.
#

echo "Starting script to ensure /dev/net/tun exists and is configured properly."

#
# Check if /dev/net/tun exists and create it if it doesn't.
#
if [ ! -c /dev/net/tun ]; then
    echo "/dev/net/tun does not exist. Creating the necessary file structure."

    # Check if /dev/net directory exists, create it if it doesn't.
    if [ ! -d /dev/net ]; then
        echo "/dev/net directory does not exist. Creating it."
        mkdir -m 755 /dev/net
    else
        echo "/dev/net directory already exists."
    fi

    # Create the /dev/net/tun device node with the correct major and minor numbers.
    echo "Creating /dev/net/tun device node."
    mknod /dev/net/tun c 10 200

    # Set the appropriate permissions for the tun device node.
    echo "Setting permissions for /dev/net/tun."
    chmod 0755 /dev/net/tun
else
    echo "/dev/net/tun already exists."
fi

#
# Load the tun module if it is not already loaded.
#
if ! lsmod | grep -q "^tun\s"; then
    echo "tun module is not loaded. Loading it now."
    if insmod /lib/modules/tun.ko; then
        echo "tun module loaded successfully."
    else
        echo "Failed to load tun module."
    fi
else
    echo "tun module is already loaded."
fi

echo "Script execution completed."
