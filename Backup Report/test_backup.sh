#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

HOST=$(hostname)
IP=$(hostname -I | awk '{print $1}')

SQLFILE=/tmp/backup.sql
TMPFILE=/tmp/hana_backup_$$.tmp

SIDS="CST DSA DST OTT SRT UFT UUT"

echo
echo -e "${BOLD}================ BACKUP REPORT ================${NC}"
echo
echo "$(date)"
echo "Hostname: $HOST"
echo "IP: $IP"
echo

for SID in $SIDS
do
    TOTAL_SIZE=0

    echo
    echo -e "${YELLOW}${BOLD}===== ${SID} =====${NC}"
    echo

    printf "%-10s %-19s %-10s %-8s %8s\n" \
        "DATABASE" \
        "DATE" \
        "STATUS" \
        "TYPE" \
        "SIZE_GB"

    printf "%-10s %-19s %-10s %-8s %8s\n" \
        "--------" \
        "-------------------" \
        "----------" \
        "--------" \
        "-------"

    su - ${SID,,}adm -c "hdbsql -U ${SID}SAPDBCTRL -I ${SQLFILE}" \
        > "$TMPFILE" 2>/dev/null

    while IFS=',' read -r DB DATE STATUS BTYPE SIZE
    do
        DB=$(echo "$DB" | tr -d '"')
        DATE=$(echo "$DATE" | tr -d '"' | cut -d'.' -f1)
        STATUS=$(echo "$STATUS" | tr -d '"')
        BTYPE=$(echo "$BTYPE" | tr -d '"')
        SIZE=$(echo "$SIZE" | tr -d '"')

        [[ "$DB" == "DATABASE_NAME" ]] && continue
        [[ -z "$DB" ]] && continue

        SIZE_FMT=$(printf "%.2f" "$SIZE")

        TOTAL_SIZE=$(awk "BEGIN {printf \"%.2f\", $TOTAL_SIZE + $SIZE_FMT}")

        DATE_FMT=$(printf "%-19s" "$DATE")
        TYPE_FMT=$(printf "%-8s" "$BTYPE")

        if [[ "$STATUS" == "successful" ]]
        then
            STATUS_TXT=$(printf "%-10s" "Completed")

            printf "%-10s ${BLUE}%s${NC} ${GREEN}%s${NC} %s %8s\n" \
                   "$DB" \
                   "$DATE_FMT" \
                   "$STATUS_TXT" \
                   "$TYPE_FMT" \
                   "$SIZE_FMT"
        else
            STATUS_TXT=$(printf "%-10s" "Failed")

            printf "%-10s ${BLUE}%s${NC} ${RED}%s${NC} %s %8s\n" \
                   "$DB" \
                   "$DATE_FMT" \
                   "$STATUS_TXT" \
                   "$TYPE_FMT" \
                   "$SIZE_FMT"
        fi

    done < <(grep '^"' "$TMPFILE")

    echo "--------------------------------------------------------------------------"

    printf "%-52s %8.2f GB\n" \
           "TOTAL SIZE (${SID} + SYSTEMDB):" \
           "$TOTAL_SIZE"

    echo "--------------------------------------------------------------------------"

done

rm -f "$TMPFILE"

echo
echo -e "${BOLD}=============== END OF REPORT ===============${NC}"
echo
