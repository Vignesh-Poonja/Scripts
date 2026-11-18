# SAP Profile Directory Cleanup (`cleanup_profile.sh`)

A host-independent Bash utility designed for SAP administrators (`<sid>adm`) to safely back up active SAP profile files and archive outdated logs, numbered profile versions, and manual backup files in `/usr/sap/<SID>/SYS/profile`.

---

## Key Features

* **Host-Independent Detection:** Automatically resolves the SAP profile directory (`$DIR_PROFILE` or `/usr/sap/${SAPSYSTEMNAME}/SYS/profile`) and system ID (`<SID>`) without hardcoded paths or hostnames.
* **Strict Active Profile Protection:** Identifies and preserves only `DEFAULT.PFL` and active instance profiles matching `<SID>_<INSTANCE><NR>_<HOSTNAME>` (e.g., `UUO_ASCS01_uvusapuuoci`, `UUT_D00_uvusapuutci`).
* **Automatic Archive Management:** Creates the `archive/` directory automatically on first run and enforces `750` (`rwxr-x---`) permissions so `<sid>adm` and `sapsys` always have proper access.
* **Readable Timestamped Backups:** Copies all active profiles (preserving permissions and timestamps via `cp -p`) into `archive/active_backup_<Day Mon DD HH:MM:SS AM/PM TZ YYYY>` before moving any files.
* **Interactive Preview & Confirmation:** Displays color-coded lists of files to keep and files queued for archiving, requiring explicit `y/n` confirmation prior to moving files.
* **Self-Exclusion:** Automatically excludes `*.sh` scripts and subdirectories from being moved.

---

## Prerequisites

* **User Context:** Must be executed as the SAP system administrator (`<sid>adm`, such as `uuoadm` or `uutadm`).
* **Shell:** Bash (`/bin/bash`).
* **Permissions:** Read/write access to `/usr/sap/<SID>/SYS/profile`.

---

## Installation

1. Save the script to your profile directory or a central admin location (e.g., `/usr/sap/<SID>/SYS/profile/cleanup_profile.sh` or `~/bin/cleanup_profile.sh`).
2. Grant execute permissions to `<sid>adm`:
   ```bash
   chmod 750 cleanup_profile.sh
   ```

---

## Usage

Run the script as `<sid>adm`:

```bash
./cleanup_profile.sh
```

### Execution Workflow

1. **Directory & Permission Check:** Detects `$DIR_PROFILE` and creates or updates permissions (`750`) on `archive/`.
2. **Active Profile Backup:** Copies `DEFAULT.PFL` and active instance profiles into `archive/active_backup_<timestamp>/`.
3. **File Preview:** Lists all non-active files (such as `DEFAULT.1.PFL`, `DEFAULT.PFL_<date>`, `dev_dpmon`, `sapcpe.log`, `trans.log`, and `*_bkp*` files) that will be moved.
4. **Confirmation:** Prompts `Proceed with moving these X files into archive/? (y/n):`.
   * Entering **`y`** moves the listed files into `archive/`.
   * Entering **`n`** aborts the move while retaining the newly created active profile backup.

---

## What Stays vs. What Moves

| Category | Examples | Action |
| :--- | :--- | :--- |
| **Active Profiles** | `DEFAULT.PFL`, `<SID>_ASCS01_<host>`, `<SID>_D00_<host>` | **Kept** in profile directory & backed up |
| **Old Profile Versions** | `DEFAULT.1.PFL`, `DEFAULT.PFL_08092023`, `<SID>_D00_<host>.1` | **Moved** to `archive/` |
| **Manual Backups** | `<SID>_D00_<host>_bkp02122024`, `DEFAULT.PFL_11.10.2025` | **Moved** to `archive/` |
| **Logs & Notes** | `sapcpe.log`, `dev_dpmon`, `dev_likey`, `trans.log`, `mem.txt` | **Moved** to `archive/` |
| **Scripts & Folders** | `cleanup_profile.sh`, `archive/`, `Install_prof/` | **Ignored / Kept** in place |

---

## Script Source

```bash
#!/bin/bash

# --- Color & Typography Definitions ---
if [[ -t 1 ]]; then
  BOLD='\033[1m'
  DIM='\033[2m'
  RED='\033[1;31m'
  GREEN='\033[1;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[1;34m'
  CYAN='\033[1;36m'
  RESET='\033[0m'
else
  BOLD='' DIM='' RED='' GREEN='' YELLOW='' BLUE='' CYAN='' RESET=''
fi

# --- Header Banner ---
echo -e "${CYAN}${BOLD}============================================================${RESET}"
echo -e "${CYAN}${BOLD}               SAP Profile Directory Cleanup                ${RESET}"
echo -e "${CYAN}${BOLD}============================================================${RESET}"

# 1. Dynamically detect the SAP profile directory
if [[ -n "$DIR_PROFILE" && -d "$DIR_PROFILE" ]]; then
  PROFILE_DIR="$DIR_PROFILE"
elif [[ -n "$SAPSYSTEMNAME" && -d "/usr/sap/${SAPSYSTEMNAME}/SYS/profile" ]]; then
  PROFILE_DIR="/usr/sap/${SAPSYSTEMNAME}/SYS/profile"
else
  echo -e "${RED}[ERROR] Could not detect SAP profile directory. Run this as <sid>adm.${RESET}"
  exit 1
fi

cd "$PROFILE_DIR" || exit 1
echo -e "${BLUE}[INFO]${RESET} Working in profile directory: ${BOLD}${PROFILE_DIR}${RESET}"

# 2. Create 'archive' directory if missing, and ensure proper permissions (750)
if [[ ! -d "archive" ]]; then
  mkdir -p archive || {
    echo -e "${RED}[ERROR] Failed to create 'archive' directory in $PROFILE_DIR.${RESET}"
    exit 1
  }
  echo -e "${GREEN}[OK]${RESET}   Created ${BOLD}'archive'${RESET} directory."
fi

chmod 750 archive || {
  echo -e "${RED}[ERROR] Cannot set permissions on 'archive' directory.${RESET}"
  exit 1
}

# 3. Strictly identify only active SAP profiles
SID="${SAPSYSTEMNAME:-$(basename "$(dirname "$(dirname "$PROFILE_DIR")")")}"
ACTIVE_PROFILES=()

[[ -f "DEFAULT.PFL" ]] && ACTIVE_PROFILES+=("DEFAULT.PFL")

for f in "${SID}"_*; do
  if [[ -f "$f" && "$f" =~ ^${SID}_[A-Za-z]+[0-9]{2}_[A-Za-z0-9-]+$ ]]; then
    ACTIVE_PROFILES+=("$f")
  fi
done

if [[ ${#ACTIVE_PROFILES[@]} -eq 0 ]]; then
  echo -e "${RED}[ERROR] No active SAP profiles found for SID '$SID'. Aborting for safety.${RESET}"
  exit 1
fi

echo -e "\n${GREEN}${BOLD}✔ Detected Active Profiles (WILL BE KEPT):${RESET}"
for profile in "${ACTIVE_PROFILES[@]}"; do
  echo -e "  ${GREEN}● ${BOLD}${profile}${RESET}"
done

# 4. Back up detected active profiles using full readable date/time
TIMESTAMP=$(date +"%a %b %d %I:%M:%S %p %Z %Y")
BACKUP_SUBDIR="archive/active_backup_${TIMESTAMP}"

mkdir -p "$BACKUP_SUBDIR" || {
  echo -e "${RED}[ERROR] Failed to create backup directory '$BACKUP_SUBDIR'. Aborting.${RESET}"
  exit 1
}

cp -p "${ACTIVE_PROFILES[@]}" "$BACKUP_SUBDIR"/ || {
  echo -e "${RED}[ERROR] Failed to back up active profiles. Aborting.${RESET}"
  exit 1
}

echo -e "\n${CYAN}${BOLD}ℹ Active profiles safely backed up to:${RESET} ${BOLD}${BACKUP_SUBDIR}${RESET}"
ls -lh "$BACKUP_SUBDIR"

# 5. Build dynamic exclusion arguments for 'find'
FIND_EXCLUDES=( ! -name '*.sh' )
for profile in "${ACTIVE_PROFILES[@]}"; do
  FIND_EXCLUDES+=( ! -name "$profile" )
done

# 6. Preview files to be moved
FILES_TO_MOVE=$(find . -maxdepth 1 -type f "${FIND_EXCLUDES[@]}" | sed 's|^\./||' | sort)

if [[ -z "$FILES_TO_MOVE" ]]; then
  echo -e "\n${GREEN}${BOLD}✔ Nothing to move. Profile directory is already clean!${RESET}"
  exit 0
fi

FILE_COUNT=$(echo "$FILES_TO_MOVE" | wc -l | tr -d ' ')
echo -e "\n${YELLOW}${BOLD}⚠ Files to be moved to archive/ (${FILE_COUNT} files):${RESET}"
while IFS= read -r file; do
  echo -e "  ${YELLOW}➜${RESET} ${file}"
done <<< "$FILES_TO_MOVE"

# 7. Prompt for confirmation before moving
echo -e "\n${CYAN}${BOLD}------------------------------------------------------------${RESET}"
read -p "$(echo -e "${BOLD}Proceed with moving these ${FILE_COUNT} files into archive/? (y/n): ${RESET}")" CONFIRM

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  find . -maxdepth 1 -type f "${FIND_EXCLUDES[@]}" -exec mv -t archive {} +
  echo -e "\n${GREEN}${BOLD}✔ Cleanup complete! ${FILE_COUNT} old files moved to archive/.${RESET}"
else
  echo -e "\n${YELLOW}${BOLD}✖ Cleanup canceled.${RESET} ${DIM}Your backup in '${BACKUP_SUBDIR}' was kept.${RESET}"
fi
```
