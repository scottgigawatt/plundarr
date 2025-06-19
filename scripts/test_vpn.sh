#!/bin/sh

#
# test_vpn.sh
#
# Purpose:
#   This script verifies whether a Docker container using a VPN network
#   (such as with Gluetun) is routing traffic properly. It compares the
#   public IP and location of the container with that of the host system.
#
#   The script:
#     - Runs a temporary Alpine container using the VPN network
#     - Installs wget inside the container
#     - Retrieves the container's public IP and location via ipinfo.io
#     - Retrieves the host's public IP and location via ipinfo.io
#     - Compares the two IP addresses to determine if the VPN is active
#     - Pretty-prints all JSON responses, using jq if available

# Constants
CONTAINER_NAME="gluetun-latest"
DOCKER_IMAGE="alpine:latest"
IPINFO_URL="https://ipinfo.io"

# ANSI colors
COLOR_RED='\033[31m'
COLOR_GREEN='\033[32m'
COLOR_YELLOW='\033[33m'
COLOR_BLUE='\033[34m'
COLOR_RESET='\033[0m'

# Check for jq availability
if command -v jq >/dev/null 2>&1; then
    HAS_JQ=1
else
    HAS_JQ=0
fi

# Show starting message
printf '%b\n' "${COLOR_BLUE}Running VPN container test...${COLOR_RESET}"

# Define and print the Docker command
docker_cmd="docker run --rm --network=container:$CONTAINER_NAME $DOCKER_IMAGE sh -c 'apk add --no-cache wget >/dev/null 2>&1 && wget -qO- $IPINFO_URL'"
printf '%b\n' "${COLOR_BLUE}Step 1: Running Docker container with VPN network:${COLOR_RESET}"
printf '%b\n' "$docker_cmd"

# Execute the Docker command
container_output=$(eval "$docker_cmd")

# Print container JSON output
printf '%b\n' "${COLOR_BLUE}Step 2: Received container response:${COLOR_RESET}"
if [ "$HAS_JQ" -eq 1 ]; then
    printf "%s\n" "$container_output" | jq .
else
    printf "%s\n" "$container_output" | sed 's/[,{]/\n&/g'
fi

# Extract container info
container_ip=$(printf "%s\n" "$container_output" | grep -oE '"ip":\s*"[^"]+"' | cut -d'"' -f4)
container_city=$(printf "%s\n" "$container_output" | grep -oE '"city":\s*"[^"]+"' | cut -d'"' -f4)
container_region=$(printf "%s\n" "$container_output" | grep -oE '"region":\s*"[^"]+"' | cut -d'"' -f4)
container_country=$(printf "%s\n" "$container_output" | grep -oE '"country":\s*"[^"]+"' | cut -d'"' -f4)
container_location="$container_city, $container_region $container_country"

# Validate container IP
if [ -z "$container_ip" ]; then
    printf '%b\n' "${COLOR_RED}Error: could not determine VPN container IP address.${COLOR_RESET}"
    exit 1
fi

# Run and display host request
printf '%b\n' "${COLOR_BLUE}Step 3: Getting host IP info from ipinfo.io...${COLOR_RESET}"
host_output=$(wget -qO- "$IPINFO_URL")

# Print host JSON output
printf '%b\n' "${COLOR_BLUE}Step 4: Received host response:${COLOR_RESET}"
if [ "$HAS_JQ" -eq 1 ]; then
    printf "%s\n" "$host_output" | jq .
else
    printf "%s\n" "$host_output" | sed 's/[,{]/\n&/g'
fi

# Extract host info
host_ip=$(printf "%s\n" "$host_output" | grep -oE '"ip":\s*"[^"]+"' | cut -d'"' -f4)
host_city=$(printf "%s\n" "$host_output" | grep -oE '"city":\s*"[^"]+"' | cut -d'"' -f4)
host_region=$(printf "%s\n" "$host_output" | grep -oE '"region":\s*"[^"]+"' | cut -d'"' -f4)
host_country=$(printf "%s\n" "$host_output" | grep -oE '"country":\s*"[^"]+"' | cut -d'"' -f4)
host_location="$host_city, $host_region $host_country"

# Compare IPs and report result
printf '%b\n' "${COLOR_BLUE}Step 5: Comparing container and host IPs...${COLOR_RESET}"
if [ "$container_ip" != "$host_ip" ]; then
    printf '%b\n' "${COLOR_GREEN}VPN is active. Container IP: $container_ip ($container_location), Host IP: $host_ip ($host_location).${COLOR_RESET}"
else
    printf '%b\n' "${COLOR_YELLOW}Warning: container IP $container_ip matches host IP $host_ip. VPN may not be active.${COLOR_RESET}"
fi
