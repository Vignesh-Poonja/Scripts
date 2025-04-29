#!/bin/bash

# Define the primary databases
declare -A PRIMARY_DBS=(
    ["ufpadm"]="64"
    ["cspadm"]="95"
    ["otpadm"]="85"
    ["dspadm"]="93"
)

# Define color codes
GREEN="\033[0;32m"
RED="\033[0;31m"
BOLD_YELLOW="\033[1;33m"
RESET="\033[0m"

# Function to check the status of a HANA database
check_hana_status() {
    local username=$1
    local instance=$2

    # Get the full process list
    local process_list=$(sudo su - $username -c "sapcontrol -nr $instance -function GetProcessList")

    # Extract the first three characters of the username
    local short_username=${username:0:3}

    # Check if any process is not GREEN, Running
    if echo "$process_list" | grep -qE 'GRAY|YELLOW'; then
        # If any process is GRAY or YELLOW, mark the database as stopped
        echo -e "$short_username${RESET}" >> stopped.txt
    else
        # All processes are GREEN, Running
        echo -e "$short_username${RESET}"
    fi
}

# Print the date and hostname
echo ""
echo "$(date)"
echo "$(hostname)"
echo ""
echo -e "Status:"
echo ""
echo -e "${GREEN}Running${RESET}        ${RED}Stopped${RESET}"
echo -e "--------       --------"

# Check the status of primary databases
for username in "${!PRIMARY_DBS[@]}"; do
    instance=${PRIMARY_DBS[$username]}
    check_hana_status $username $instance
done | sort

# Print stopped databases
if [[ -f stopped.txt ]]; then
    echo ""
    cat stopped.txt
    rm stopped.txt
fi
echo ""