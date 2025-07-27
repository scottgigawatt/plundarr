#!/bin/sh

#
# tun.sh: Ensures the /dev/net/tun device exists and is properly configured
#         on Synology Disk Station for use with VPN applications like Gluetun.
#
# The script:
#   - Verifies if /dev/net/tun exists and creates it if missing
#   - Creates the /dev/net directory if it doesn't exist
#   - Creates the tun device node with the correct major/minor numbers
#   - Sets the appropriate permissions on the device node
#   - Loads the tun kernel module if it's not already loaded
#

echo "Starting script to ensure /dev/net/tun exists and is configured properly."

# Create the necessary file structure for /dev/net/tun if it does not already exist
if [ ! -c /dev/net/tun ]; then
    echo "/dev/net/tun does not exist. Creating the necessary file structure."

    # Create the /dev/net directory if it does not exist
    if [ ! -d /dev/net ]; then
        echo "/dev/net directory does not exist. Creating it."
        mkdir -m 755 /dev/net
    else
        echo "/dev/net directory already exists."
    fi

    # Create the /dev/net/tun device node with major number 10 and minor number 200
    echo "Creating /dev/net/tun device node."
    mknod /dev/net/tun c 10 200

    # Set the permissions for /dev/net/tun
    echo "Setting permissions for /dev/net/tun."
    chmod 0755 /dev/net/tun
else
    echo "/dev/net/tun already exists."
fi

# Load the tun module if it is not already loaded
if ! lsmod | grep -q "^tun\s"; then
    echo "tun module is not loaded. Loading it now."
    insmod /lib/modules/tun.ko
    if [ $? -eq 0 ]; then
        echo "tun module loaded successfully."
    else
        echo "Failed to load tun module."
    fi
else
    echo "tun module is already loaded."
fi

echo "Script execution completed."
