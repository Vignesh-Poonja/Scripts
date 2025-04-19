#!/bin/bash

# Path to the updated script on the local machine (uvusapuutci)
SCRIPT_PATH="/usr/local/bin/server_health.sh"

# List of target servers
SERVERS=(
  "uvusapuftci"
  "uvusapsrtci"
)

# Username to use for SSH
USERNAME="cgvk62"

# Loop through each server
for server in "${SERVERS[@]}"; do
  echo "Updating $server..."

  # Copy the script to /tmp on the target server
  scp "$SCRIPT_PATH" "$USERNAME@$server:/tmp/server_health.sh"

  # Move it to /usr/local/bin and set permissions
  ssh "$USERNAME@$server" "sudo mv /tmp/server_health.sh /usr/local/bin/server_health.sh && sudo chmod 755 /usr/local/bin/server_health.sh"

  # Check result
  if [[ $? -eq 0 ]]; then
    echo "✅ Updated on $server"
  else
    echo "❌ Failed on $server"
  fi

done
