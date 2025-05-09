# SAP HANA Database Status Check Script

This script helps monitor the operational status of SAP HANA databases by executing the `sapcontrol` command under respective SAP system users. It provides a clear, color-coded display of running and stopped databases.

---

## Features

- ✅ Checks primary and secondary HANA database instances

---

## Script Overview

- Written in Bash
- Uses associative arrays to define primary and secondary SAP HANA systems
- Executes `sapcontrol -nr <instance> -function GetProcessList` for each SID user

---

## Usage

1. Ensure the script is executable:

    ```bash
    chmod +x status.sh
    ```

2. Run the script:

    ```bash
    ./status.sh
    ```

---

## Example Output

```bash
Tue Apr 29 12:00:00 IST 2025
uvuhanottdb

Status:

Running
--------
cst
ott
srt
uft
uut

Stopped
--------
        dsp        
```
![image](https://github.com/user-attachments/assets/0d020dac-328f-400b-a752-7df22b6e5973)




## Configuration

Edit the following arrays in the script to reflect your landscape:

```bash
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
```

---

## Requirements

- SAP HANA systems installed with respective users (e.g., `srtadm`, `uftadm`, etc.)
- Passwordless `sudo` access to each SAP user
- `sapcontrol` command-line tool available in each SID environment

---

## Notes

- The script creates a temporary file `stopped.txt` to collect stopped SIDs
- This file is removed after displaying the result
- Secondary database SIDs are highlighted for visibility

---


