HANA System Replication Management Script — prod.sh
📌 Overview

prod.sh is a Bash script that automates the process of starting, stopping, registering, and unregistering multiple SAP HANA databases configured as secondary systems in a System Replication setup.

It is built to:

Register databases as secondary and start them.

Stop databases and unregister them from replication.

Automatically detect current status before taking action.

⚙️ Configuration

Inside the script, define the following three associative arrays to map each database SID to its admin user, instance number, and registration command:

# Example structure
declare -A DB_USERS=( ["<SID1>"]="<sidadm1>" ["<SID2>"]="<sidadm2>" )
declare -A DB_INSTANCES=( ["<SID1>"]="<instanceNo1>" ["<SID2>"]="<instanceNo2>" )
declare -A DB_REGISTER=(
  ["<SID1>"]="hdbnsutil -sr_register --name=<SecondaryName1> --remoteHost=<PrimaryHost> --remoteInstance=<PrimaryInstance1> --replicationMode=syncmem --operationMode=logreplay"
  ["<SID2>"]="hdbnsutil -sr_register --name=<SecondaryName2> --remoteHost=<PrimaryHost> --remoteInstance=<PrimaryInstance2> --replicationMode=syncmem --operationMode=logreplay"
)


💡 Tip: Add as many SIDs as needed — the script loops through all defined SIDs automatically.

📋 Prerequisites

Run this script on the secondary HANA host.

Ensure you have sudo privileges to switch to each <sidadm> user.

hdbnsutil and sapcontrol commands must be available in each <sidadm> user’s environment.

The primary system must be reachable from the secondary system.

📥 Installation (Recommended)
1. Copy the script to /usr/local/bin
sudo cp prod.sh /usr/local/bin/prod.sh
sudo chmod +x /usr/local/bin/prod.sh

2. Create a shell alias named prod

Add this line to your shell configuration file (~/.bashrc or ~/.zshrc):

alias prod='/usr/local/bin/prod.sh'


Then apply the changes:

source ~/.bashrc


Now you can run the script simply as:

prod start
prod stop

🚀 Usage
Start all secondary databases
prod start


Registers each DB as a secondary (if not already registered)

Starts each DB if it is not running

Stop and unregister all secondary databases
prod stop


Prompts for confirmation

Stops and unregisters each DB from system replication

⚡ Script Workflow
When running start:

Check if the database is already registered as a secondary.

If not registered → run the hdbnsutil -sr_register command.

Check if the database is running.

If not running → run HDB start.

When running stop:

Prompt for confirmation.

Stop the database with HDB stop.

Unregister the database using hdbnsutil -sr_unregister.

📌 Log Colors

🟢 Green — Success

🟡 Yellow — In Progress

🔴 Red — Failure

⚠️ Notes

The stop operation affects all configured databases, so use it cautiously.

Use this script only in controlled environments (such as DR or HA secondary nodes).

👨‍💻 Author

This script was created to simplify SAP HANA System Replication operations across multiple databases.
