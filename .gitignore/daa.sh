#!/bin/bash

# Server details: shortname => hostname mapping
declare -A servers=(
  ["uuo"]="uvusapuuoci"
  ["srt"]="uvusapsrtci"
  ["uft"]="uvusapuftci"
)

# Color codes
GREEN="\e[1;32m"
RED="\e[1;31m"
NC="\e[0m" # No Color

# Function to check DAA status
check_status() {
  ssh "$1" "sudo su - daaadm -c 'sapcontrol -nr 98 -function GetProcessList'" 2>/dev/null | grep -q "All processes running"
  return $?
}

# Function to start DAA if not running
start_if_needed() {
  ssh "$1" "sudo su - daaadm -c 'sapcontrol -nr 98 -function GetProcessList'" 2>/dev/null | grep -q "All processes running"
  if [ $? -ne 0 ]; then
    ssh "$1" "sudo su - daaadm -c 'startsap'" >/dev/null 2>&1
  fi
}

# Main
if [[ "$1" != "status" && "$1" != "start" ]]; then
  echo "Usage: $0 {status|start}"
  exit 1
fi

echo -e "DAA\n---"
for sid in "${!servers[@]}"; do
  host="${servers[$sid]}"
  if [[ "$1" == "start" ]]; then
    start_if_needed "$host"
  fi

  if check_status "$host"; then
    echo -e "${GREEN}${sid}${NC}"
  else
    echo -e "${RED}${sid}${NC}"
  fi
done
