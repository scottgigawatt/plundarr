#!/bin/sh

#
# This script ensures that Entware is properly set up on boot for a Synology NAS.
#
# It performs the following actions:
# 1. Creates the /opt directory if it does not exist and mounts Entware to /opt.
# 2. Starts the Entware services using the init script.
# 3. Checks if the Entware profile is already included in the global profile. If not, it adds the necessary entry.
# 4. Updates the Entware package list.
#

# Mount/Start Entware
mkdir -p /opt  # Create /opt directory if it does not exist
mount -o bind "/volume1/@Entware/opt" /opt
/opt/etc/init.d/rc.unslung start

# Add Entware Profile in Global Profile
if grep -qF '/opt/etc/profile' /etc/profile; then
    echo "Confirmed: Entware Profile in Global Profile"
else
    echo "Adding: Entware Profile in Global Profile"
    cat >>/etc/profile <<"EOF"

# Load Entware Profile
[ -r "/opt/etc/profile" ] && . /opt/etc/profile  # Include Entware profile in global profile
EOF
fi

# Update Entware List
/opt/bin/opkg update
