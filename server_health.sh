#!/bin/bash

# Function to calculate CPU utilization
get_cpu_utilization() {
    cpu_idle=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d'.' -f1)
    cpu_utilization=$((100 - cpu_idle))
    echo $cpu_utilization
}

# Function to calculate memory utilization
get_memory_utilization() {
    mem_total=$(free | grep Mem | awk '{print $2}')
    mem_used=$(free | grep Mem | awk '{print $3}')
    mem_utilization=$((mem_used * 100 / mem_total))
    echo $mem_utilization
}

# Function to calculate disk utilization (with mount point)
get_disk_utilization() {
    df -P | awk 'NR>1 {gsub("%",""); print $5, $6}'
}

# Function to check swap space
check_swap_space() {
    free_swap_kb=$(free | awk '/Swap:/ {print $4}')
    # Convert KB to GB (1 GB = 1048576 KB)
    free_swap_gb=$((free_swap_kb / 1024 / 1024))
    echo $free_swap_gb
}

# Variables
health_status="Healthy"
explanation=""

hostname=$(hostname)
cpu_utilization=$(get_cpu_utilization)
memory_utilization=$(get_memory_utilization)
disk_utilization=$(get_disk_utilization)
free_swap_space=$(check_swap_space)

# CPU check
if [ "$cpu_utilization" -gt 60 ]; then
    health_status="Not Healthy"
    explanation+="CPU utilization is $cpu_utilization%, which is above the threshold of 60%.\n"
fi

# Memory check
if [ "$memory_utilization" -gt 80 ]; then
    health_status="Not Healthy"
    explanation+="Memory utilization is $memory_utilization%, which is above the threshold of 60%.\n"
fi

# Disk check
while read -r usage mount_point; do
    if [ "$mount_point" != "/sap_staging" ] && [ "$usage" -ge 85 ]; then
        health_status="Not Healthy"
        explanation+="Disk utilization for $mount_point is $usage%, which is above the threshold of 85%.\n"
    fi
done <<< "$disk_utilization"

# Swap space check
if [ "$free_swap_space" -lt 2 ]; then
    health_status="Not Healthy"
    explanation+="Free swap space is ${free_swap_space}GB, which is below the minimum required 2GB.\n"
fi

# Output
echo
echo $(date)
echo "Hostname: $hostname"
echo
echo "Server Health Status: $health_status"
echo
echo "CPU Usage: $cpu_utilization%"
echo "Memory Usage: $memory_utilization%"
echo "Free Swap Space: ${free_swap_space}GB"
echo

# Detailed explanation if requested
if [ "$1" == "explain" ]; then
    if [ "$health_status" == "Healthy" ]; then
        echo "The server is healthy because CPU, memory, disk, and swap utilization are within acceptable thresholds."
    else
        echo -e "Reason for health status:\n$explanation"
        echo
    fi
fi
