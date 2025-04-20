#!/bin/bash

# Define the primary and secondary databases
declare -A PRIMARY_DBS=(
    ["uutadm"]="50"
    ["srtadm"]="51"
    ["uftadm"]="44"
    ["cstadm"]="40"
    ["ottadm"]="55"
    ["dstadm"]="60"
    ["dsaadm"]="70"
)

# Define secondary databases as an associative array
declare -A SECONDARY_DBS=(
    ["dspadm"]="93"
)

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW_BOLD='\033[1;33m'
NC='\033[0m' # No Color

# Function to check the status of a HANA database
check_hana_status() {
    local username=$1
    local instance=$2
    local role=$3

    # Get the full process list
    local process_list=$(sudo su - $username -c "sapcontrol -nr $instance -function GetProcessList")

    # Extract the first three characters of the username
    local short_username=${username:0:3}

    # Determine display name with formatting
    local display_name="$short_username"
    if [[ "$role" == "secondary" && "$short_username" == "dsp" ]]; then
        display_name="${YELLOW_BOLD}${short_username}${NC}"
    fi

    # Check if any process is not GREEN, Running
    if echo "$process_list" | grep -qvE 'GREEN, Running'; then
        # Mark as stopped (red)
        printf "%-15s ${RED}Stopped${NC}\n" "$display_name"
    else
        # Mark as running (green)
        printf "%-15s ${GREEN}Running${NC}\n" "$display_name"
    fi
}

# Print the date and hostname
echo ""
echo "$(date)"
echo "$(hostname)"
echo ""
echo -e "Status:\n"
printf "%-15s %-10s\n" "Database" "Status"
printf "%-15s %-10s\n" "--------" "--------"

# Check the status of primary databases
for username in "${!PRIMARY_DBS[@]}"; do
    instance=${PRIMARY_DBS[$username]}
    check_hana_status "$username" "$instance" "primary"
done | sort

# Add a line gap before secondary databases
echo ""

# Check the status of secondary databases
for username in "${!SECONDARY_DBS[@]}"; do
    instance=${SECONDARY_DBS[$username]}
    check_hana_status "$username" "$instance" "secondary"
done | sort

echo ""
