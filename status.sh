#!/bin/bash

# Define primary and secondary databases
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

# Clear temp files
> running.txt
> stopped.txt

# Check database status
check_hana_status() {
    local username=$1
    local instance=$2
    local short_username=${username:0:3}

    local process_list
    process_list=$(sudo su - "$username" -c "sapcontrol -nr $instance -function GetProcessList")

    if echo "$process_list" | grep -qvE 'GREEN, Running'; then
        echo "$short_username" >> stopped.txt
    else
        echo "$short_username" >> running.txt
    fi
}

# Header
echo ""
echo "$(date)"
echo "$(hostname)"
echo ""
echo "Status:"
echo ""
printf "%-18s%s\n" "Running" "Stopped"
printf "%-18s%s\n" "--------" "--------"

# Check primary DBs
for username in "${!PRIMARY_DBS[@]}"; do
    check_hana_status "$username" "${PRIMARY_DBS[$username]}"
done

# Check secondary DBs
for username in "${!SECONDARY_DBS[@]}"; do
    check_hana_status "$username" "${SECONDARY_DBS[$username]}"
done

# Sort and paste output side by side with colors
paste <(
    sort running.txt | while read -r db; do
        echo -e "${GREEN}${db}${NC}"
    done
) <(
    sort stopped.txt | while read -r db; do
        if [[ "$db" == "dsp" ]]; then
            echo -e "${YELLOW_BOLD}${db}${NC}"
        else
            echo -e "${RED}${db}${NC}"
        fi
    done
)

# Cleanup
rm -f running.txt stopped.txt
echo ""
