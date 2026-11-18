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

echo -e "\n${BOLD}✔ Detected Active Profiles (WILL BE KEPT):${RESET}"
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
