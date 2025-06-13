#!/bin/bash

# Define the primary HANA DB users and their instance numbers
declare -A PRIMARY_DBS=(
    ["uutadm"]="50"
    ["srtadm"]="51"
    ["uftadm"]="44"
    ["cstadm"]="40"
    ["ottadm"]="55"
    ["dstadm"]="60"
    ["dsaadm"]="70"
)

# Color codes
GREEN="\033[0;32m"
RED="\033[0;31m"
BOLD_YELLOW="\033[1;33m"
RESET="\033[0m"

# Enhanced check_status to check both color and textstatus
check_status() {
    local hostname=$1
    local instance=$2
    local expected_color=$3
    local expected_text=$4

    status=$(sapcontrol -nr $instance -function GetProcessList 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "sapcontrol failed for instance $instance"
        return 2
    fi
    count=$(echo "$status" | awk -F, -v c="$expected_color" -v t="$expected_text" '
        NR>4 && $3 ~ c && $4 ~ t {count++} END {print count}')
    if [ "$count" -eq 0 ]; then
        echo "Error: Process on $hostname instance $instance is not $expected_color and $expected_text."
        return 1
    fi
    return 0
}

# Function to check the status of a HANA database
check_hana_status() {
    local username=$1
    local instance=$2

    local process_list=$(sudo su - $username -c "sapcontrol -nr $instance -function GetProcessList" 2>/dev/null)
    local short_username=${username:0:3}

    # Only consider lines where the process state is present (not blank, not header)
    local total=$(echo "$process_list" | awk -F, 'NR>4 && $3 ~ /[A-Z]+/ && $4 ~ /[A-Za-z]+/ {count++} END {print count+0}')
    local green_running=$(echo "$process_list" | awk -F, 'NR>4 && $3 ~ /GREEN/ && $4 ~ /Running/ {count++} END {print count+0}')
    local gray_stopped=$(echo "$process_list" | awk -F, 'NR>4 && $3 ~ /GRAY/ && $4 ~ /Stopped/ {count++} END {print count+0}')
    local yellow_stopping=$(echo "$process_list" | awk -F, 'NR>4 && $3 ~ /YELLOW/ && $4 ~ /Stopping/ {count++} END {print count+0}')
    local yellow_starting=$(echo "$process_list" | awk -F, 'NR>4 && $3 ~ /YELLOW/ && $4 ~ /Starting/ {count++} END {print count+0}')

    # Debug: Uncomment to see what is being parsed
    echo "${short_username}: total=$total green_running=$green_running gray_stopped=$gray_stopped yellow_stopping=$yellow_stopping yellow_starting=$yellow_starting"

    if [ "$total" -eq "$green_running" ] && [ "$total" -ne 0 ]; then
        echo -e "${GREEN}$short_username Running${RESET}"
    elif [ "$total" -eq "$gray_stopped" ] && [ "$total" -ne 0 ]; then
        echo -e "${RED}$short_username Stopped${RESET}" >> stopped.txt
    elif [ "$yellow_stopping" -gt 0 ]; then
        echo -e "${BOLD_YELLOW}$short_username Stopping${RESET}"
    elif [ "$yellow_starting" -gt 0 ]; then
        echo -e "${BOLD_YELLOW}$short_username Starting${RESET}"
    else
        echo -e "${RED}$short_username Unknown${RESET}" >> stopped.txt
    fi
}

# Function to stop HANA database
stop_hana() {
    local hostname=$1
    shift
    local users=("$@")

    echo -ne "Are you sure you want to stop the HANA database on \033[1m$hostname\033[0m? (yes/no): "
    read confirm
    if [[ "$confirm" != "yes" ]]; then
        echo "HANA database stop cancelled."
        return 1
    fi

    echo -e "Stopping HANA database on \033[1m$hostname\033[0m..."
    for user in "${users[@]}"; do
        sudo su - $user -c 'HDB stop' 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "HDB stop failed for user $user"
            continue
        fi
    done
    # Make the success message bold red
    echo ""
    echo -ne "${RED}HANA database on \033[1m$hostname\033[0m stopped successfully.${RESET}"
}

# Function to start all primary HANA DBs if not already started
start_hana() {
    for username in "${!PRIMARY_DBS[@]}"; do
        instance=${PRIMARY_DBS[$username]}
        process_list=$(sudo su - $username -c "sapcontrol -nr $instance -function GetProcessList" 2>/dev/null)
        # Only consider lines where the process state is present (not blank, not header)
        if echo "$process_list" | awk -F, 'NR>4 && $3 ~ /[A-Z]+/ && $4 ~ /[A-Za-z]+/ && ($3 !~ /GREEN/ || $4 !~ /Running/)' | grep -q .; then
            short_username=${username:0:3}
            echo -e "\033[1;32mStarting \033[1m$short_username\033[0;32m (instance $instance)...\033[0m"
            sudo su - $username -c "HDB start"
        else
            short_username=${username:0:3}
            echo "HANA DB for $short_username (instance $instance) is already started."
        fi
    done
}

# Main script
if [ $# -ne 1 ]; then
    echo "Usage: $0 {start|stop|status}"
    exit 1
fi

action=$1

case $action in
    start)
        start_hana
        ;;
    stop)
        stop_hana "uvuhanottdb" uutadm srtadm uftadm cstadm ottadm dstadm dsaadm
        ;;
    status)
        echo ""
        echo "$(date)"
        echo "$(hostname)"
        echo ""
        echo -e "Status:"
        echo ""
        echo -e "${GREEN}Running${RESET}"
        echo -e "--------"
        for username in "${!PRIMARY_DBS[@]}"; do
            instance=${PRIMARY_DBS[$username]}
            check_hana_status $username $instance
        done | sort

        if [[ -f stopped.txt ]]; then
            echo ""
            echo -e "${RED}Stopped:${RESET}"
            echo -e "--------"
            while read line; do
                echo -e "\t${RED}$line${RESET}"
            done < stopped.txt
            rm stopped.txt
        fi
        echo ""
        ;;
    *)
        echo "Invalid action. Usage: $0 {start|stop|status}"
        exit 1
        ;;
esac
