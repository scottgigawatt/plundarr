#!/bin/sh

#
# This script ensures the /dev/net/tun device exists on Synology Disk Station for use with VPN applications like gluetun.
# The /dev/net/tun device is a virtual network device that implements point-to-point network tunnels. It is essential for
# VPNs as it allows the encapsulation of packets, creating a secure and private connection over the internet.
#

# Create the necessary file structure for /dev/net/tun if it does not already exist
if [ ! -c /dev/net/tun ]; then
    # Create the /dev/net directory if it does not exist
    if [ ! -d /dev/net ]; then
        mkdir -m 755 /dev/net
    fi
    # Create the /dev/net/tun device node with major number 10 and minor number 200
    mknod /dev/net/tun c 10 200
    # Set the permissions for /dev/net/tun
    chmod 0755 /dev/net/tun
fi

# Load the tun module if it is not already loaded
if ! lsmod | grep -q "^tun\s"; then
    insmod /lib/modules/tun.ko
fi
