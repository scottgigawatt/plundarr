#!/bin/sh

#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# entware.sh: This script is intended to run directly on Synology NAS to
#             ensure that the Entware profile is included in the global profile
#             and that Entware is mounted, started, and refreshed on boot.
#
# Usage: scripts/synology/entware.sh
#
# The script:
#   - Creates the /opt directory if it does not exist and mounts Entware to /opt.
#   - Starts the Entware services using the init script.
#   - Checks if the Entware profile is already included in the global profile. If not, it adds the necessary entry.
#   - Updates the Entware package list and upgrades installed packages to ensure the system is up-to-date.
#

#
# Mount and start Entware.
#
mkdir -p /opt                               # Create /opt directory if it does not exist
mount -o bind "/volume1/@Entware/opt" /opt  # Mount Entware to /opt
/opt/etc/init.d/rc.unslung start            # Start Entware services

#
# Add the Entware profile to the global profile when it is not already included.
#
if grep -qF '/opt/etc/profile' /etc/profile; then
    echo "Confirmed: Entware Profile in Global Profile"
else
    echo "Adding: Entware Profile in Global Profile"
    cat >>/etc/profile <<"EOF"

# Load Entware Profile
[ -r "/opt/etc/profile" ] && . /opt/etc/profile  # Include Entware profile in global profile
EOF
fi

#
# Update Entware package list and upgrade installed packages.
#
/opt/bin/opkg update
/opt/bin/opkg upgrade
