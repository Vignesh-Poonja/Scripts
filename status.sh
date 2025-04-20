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

declare -A SECONDARY_DBS=(
    ["dspadm"]="93"
)

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW_BOLD='\033[1;33m'
NC='\033[0m'

# Function to check the status of a HANA database
check_hana_status() {
    local username=$1
    local instance=$2

    # Get the full process list
    local process_list
    process_list=$(sudo su - $username -c "sapcontrol -nr $instance -function GetProcessList")

    # Extract the first three characters of the username
    local short_username=${username:0:3}

    # Check if any process is not GREEN, Running
    if echo "$process_list" | grep -qvE 'GREEN, Running'; then
        echo "$short_username" >> stopped.txt
    else
        echo "$short_username" >> running.txt
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

# Remove temp files if they exist
rm -f running.txt stopped.txt

# Check the status of primary databases
for username in "${!PRIMARY_DBS[@]}"; do
    instance=${PRIMARY_DBS[$username]}
    check_hana_status $username $instance
done

# Check the status of secondary databases
for username in "${!SECONDARY_DBS[@]}"; do
    instance=${SECONDARY_DBS[$username]}
    check_hana_status $username $instance
done

# Display running databases
if [[ -f running.txt ]]; then
    while read -r db; do
        if [[ "$db" == "dsp" ]]; then
            printf "%-15b ${GREEN}Running${NC}\n" "${YELLOW_BOLD}${db}${NC}"
        else
            printf "%-15s ${GREEN}Running${NC}\n" "$db"
        fi
    done < <(sort running.txt)
    rm running.txt
fi

# Display stopped databases
if [[ -f stopped.txt ]]; then
    while read -r db; do
        if [[ "$db" == "dsp" ]]; then
            printf "%-15b ${RED}Stopped${NC}\n" "${YELLOW_BOLD}${db}${NC}"
        else
            printf "%-15s ${RED}Stopped${NC}\n" "$db"
        fi
    done < <(sort stopped.txt)
    rm stopped.txt
fi

echo ""
