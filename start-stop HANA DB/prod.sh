#!/bin/bash

# Database SIDs, instance numbers, and sidadm users
declare -A DB_USERS=( ["UFP"]="ufpadm" ["CSP"]="cspadm" ["OTP"]="otpadm" )
declare -A DB_INSTANCES=( ["UFP"]="64" ["CSP"]="95" ["OTP"]="85" )
declare -A DB_REGISTER=(
  ["UFP"]="hdbnsutil -sr_register --name=SecondaryUFP --remoteHost=uvuhanofpdb --remoteInstance=64 --replicationMode=syncmem --operationMode=logreplay"
  ["CSP"]="hdbnsutil -sr_register --name=SecondaryCSP --remoteHost=uvuhanofpdb --remoteInstance=95 --replicationMode=syncmem --operationMode=logreplay"
  ["OTP"]="hdbnsutil -sr_register --name=SecondaryOTP --remoteHost=uvuhanofpdb --remoteInstance=85 --replicationMode=syncmem --operationMode=logreplay"
)

stop_db() {
  read -p $'\e[1;31mAre you sure you want to stop and unregister all DBs? (yes/no): \e[0m' confirm
  if [[ ! "$confirm" =~ ^([Yy][Ee][Ss]|[Yy])$ ]]; then
    echo -e "\e[1mStop operation cancelled.\e[0m"
    return 1
  fi
  for sid in UFP CSP OTP; do
    user=${DB_USERS[$sid]}
    inst=${DB_INSTANCES[$sid]}
    echo -e "\n\e[1;33mStopping $sid (user: $user, instance: $inst)...\e[0m"
    sudo su - "$user" -c "HDB stop"
    if [ $? -ne 0 ]; then
      echo -e "\e[1;31mFailed to stop $sid.\e[0m"
      continue
    fi
    sudo su - "$user" -c "hdbnsutil -sr_unregister --id=Secondary$sid"
    if [ $? -ne 0 ]; then
      echo -e "\e[1;31mFailed to unregister $sid.\e[0m"
      continue
    fi
    echo -e "\e[1;32m$sid stopped and unregistered.\e[0m"
  done
}

is_registered() {
  local user=$1
  sudo su - "$user" -c "hdbnsutil -sr_state" 2>/dev/null | grep -q 'is secondary/consumer system: true'
}

is_running() {
  local user=$1
  local inst=$2
  local status
  status=$(sudo su - "$user" -c "sapcontrol -nr $inst -function GetProcessList" 2>/dev/null)
  local total=$(echo "$status" | awk -F, 'NR>4 && $3 ~ /[A-Z]+/ && $4 ~ /[A-Za-z]+/ {count++} END {print count+0}')
  local green_running=$(echo "$status" | awk -F, 'NR>4 && $3 ~ /GREEN/ && $4 ~ /Running/ {count++} END {print count+0}')
  [ "$total" -ne 0 ] && [ "$total" -eq "$green_running" ]
}

start_db() {
  for sid in UFP CSP OTP; do
    user=${DB_USERS[$sid]}
    inst=${DB_INSTANCES[$sid]}
    regcmd=${DB_REGISTER[$sid]}
    echo -e "\e[1;33m===== $sid =====\e[0m"
    if is_registered "$user"; then
      echo -e "\e[1;32mReplication is already registered.\e[0m"
    else
      echo -e "\e[1;33mRegistering replication for $sid...\e[0m"
      sudo su - "$user" -c "$regcmd"
      if [ $? -ne 0 ]; then
        echo -e "\e[1;31mFailed to register $sid.\e[0m"
        continue
      fi
    fi
    if is_running "$user" "$inst"; then
      echo -e "\e[1;32m$sid is already running.\e[0m"
      echo ""
      continue
    fi
    echo -e "\e[1;33mStarting $sid...\e[0m"
    sudo su - "$user" -c "HDB start"
    if [ $? -ne 0 ]; then
      echo -e "\e[1;31mFailed to start $sid.\e[0m"
      continue
    fi
    echo -e "\e[1;32m$sid registered and started.\e[0m"
    echo ""
  done
}

case "$1" in
  start)
    start_db
    ;;
  stop)
    stop_db
    ;;
  *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;
esac
