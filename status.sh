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

# Function to check the status of a HANA database
check_hana_status() {
    local username=$1
    local instance=$2

    # Get the full process list
    local process_list=$(sudo su - $username -c "sapcontrol -nr $instance -function GetProcessList")

    # Extract the first three characters of the username
    local short_username=${username:0:3}

    # Check if any process is not GREEN, Running
    if echo "$process_list" | grep -qvE 'GREEN, Running'; then
        # If any process is not GREEN, Running, mark as stopped
        echo "$short_username" >> stopped.txt
    else
        # All processes are GREEN, Running
        echo "$short_username"
    fi
}

# Print the date and hostname
echo ""
echo "$(date)"
echo "$(hostname)"
echo ""
echo "Status:"
echo ""
echo "Running        Stopped"
echo "--------       --------"

# Check the status of primary databases
for username in "${!PRIMARY_DBS[@]}"; do
    instance=${PRIMARY_DBS[$username]}
    check_hana_status $username $instance
done | sort

# Add a line gap before secondary databases
echo ""

# Check the status of secondary databases
for username in "${!SECONDARY_DBS[@]}"; do
    instance=${SECONDARY_DBS[$username]}
    check_hana_status $username $instance
done | sort

# Print stopped databases
if [[ -f stopped.txt ]]; then
    cat stopped.txt
    rm stopped.txt
fi
