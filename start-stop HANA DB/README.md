# ott.sh

A Bash script to manage SAP HANA database instances for multiple users.  
It provides commands to **start**, **stop**, and **check the status** of all configured HANA DB instances.

## Features

- Start all configured HANA DB instances if not already running
- Stop all configured HANA DB instances (with confirmation prompt)
- Show status of all instances, color-coded for easy reading

## Usage

```bash
./ott.sh {start|stop|status}
```

- `start` &mdash; Starts all HANA DB instances that are not already running.
- `stop` &mdash; Stops all HANA DB instances (asks for confirmation).
- `status` &mdash; Shows the status of all HANA DB instances.

## Prerequisites

- Bash shell (Linux or WSL recommended)
- The user running the script must have `sudo` privileges to switch to HANA DB users
- `sapcontrol` command must be available for each instance

## Configuration

The script uses a Bash associative array to define HANA DB users and their instance numbers:

```bash
declare -A PRIMARY_DBS=(
    ["username"]="instance_no"
)
```

Modify this section if your usernames or instance numbers are different.

## Output

- **Running** instances are shown in green.
- **Stopped** instances are shown in red.
- **Starting/Stopping** states are shown in bold yellow.
- Prompts and messages use color and bold formatting for clarity.

## Example

```bash
# Start all HANA DBs
./ott.sh start

# Stop all HANA DBs (with confirmation)
./ott.sh stop

# Show status of all HANA DBs
./ott.sh status
```

![ott sh_png](https://github.com/user-attachments/assets/64822e4f-3bc4-46aa-adb5-2db136cb1011)

## Notes

- The script creates and deletes a temporary `stopped.txt` file to track stopped/unknown instances during status checks.
- Make sure the script is executable:
  ```bash
  chmod +x ott.sh
  ```
- Run the script from a terminal with appropriate permissions.

---
**Author:** Your Name  
**License:** MIT (or specify your license)
