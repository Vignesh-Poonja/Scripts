# HANA Backup Report Automation

## Overview

This solution automates the collection and reporting of SAP HANA database backup information from the HANA Backup Catalog.

The script retrieves the latest successful complete data backup details for:

- SYSTEMDB
- Tenant Databases

and displays:

- Backup Date & Time
- Backup Status
- Backup Destination Type (Backint / File)
- Backup Size (GB)
- Total Size (Tenant + SYSTEMDB)

The output is intended to replace manual verification through HANA Studio, HANA Cockpit, or DBA Cockpit.

---

## Files

### backup.sql

HANA SQL query used to retrieve the latest successful backup entry from:

- SYS_DATABASES.M_BACKUP_CATALOG
- SYS_DATABASES.M_BACKUP_CATALOG_FILES

Data returned:

- Database Name
- Backup Date
- Status
- Destination Type
- Backup Size

---

### backup_report.sh

Shell script that:

1. Connects to each SAP HANA SID.
2. Executes the SQL query using the corresponding hdbuserstore key.
3. Formats the output.
4. Calculates total backup size (SYSTEMDB + Tenant).
5. Generates the latest report.

---

## Prerequisites

### Operating System

- Linux

### SAP HANA

The following must exist for each SID:

```bash
hdbuserstore LIST
```

Example:

```bash
KEY UUTSAPDBCTRL
KEY CSTSAPDBCTRL
KEY UFPPSAPDBCTRL
```

### Access

The executing user must be able to switch to the corresponding SID administrator account:

```bash
sudo su - <sidadm>
```

---

## Installation

Copy the files:

```text
backup.sql
backup_report.sh
```

to:

```text
/usr/local/bin
```

Grant permissions:

```bash
chmod 755 /usr/local/bin/backup_report.sh
chmod 644 /usr/local/bin/backup.sql
```

---

## Execution

Run manually:

```bash
backup
```

or

```bash
/usr/local/bin/backup_report.sh
```

---

## Output Example

```text
===== UUT =====

DATABASE   DATE                STATUS     TYPE      SIZE_GB
--------   ------------------- ---------- --------  -------
SYSTEMDB   2026-10-17 04:59:00 Completed  backint      4.81
UUT        2026-10-17 05:00:39 Completed  backint    101.45

--------------------------------------------------------------------------
TOTAL SIZE (UUT + SYSTEMDB):                           106.26 GB
--------------------------------------------------------------------------
```

---

## Report Location

Latest report:

```text
/usr/local/backup_reports/backup_report.txt
```

View:

```bash
cat /usr/local/backup_reports/backup_report.txt
```

---

## Cron Schedule

Example schedule:

### 12:00 AM IST

```cron
30 20 * * * /usr/local/bin/backup_report.sh >/dev/null 2>&1
```

### 10:00 AM IST

```cron
30 6 * * * /usr/local/bin/backup_report.sh >/dev/null 2>&1
```

---

## Features

- Automated SAP HANA Backup Reporting
- SYSTEMDB and Tenant Database Support
- Backup Size Calculation
- Backup Status Validation
- Backint/File Destination Visibility
- Host-Based Reporting
- Daily Scheduled Execution
- Lightweight Implementation
- No SAP HANA Password Exposure
- No HANA Studio Dependency

---

## Author

Vignesh Poonja

SAP Basis / HANA Administration
