---
description: "Restore the constitution to the last saved backup version"
scripts:
  sh: ../../scripts/bash/charter-common.sh
---

# Charter Restore

Restore the project constitution to the last saved backup created by charter during composition.

## User Input

$ARGUMENTS

No arguments required. The most recent backup is used by default.

## Prerequisites

1. Charter must be configured — `.specify/charter/` directory must exist
2. At least one backup must exist in `.specify/charter/backups/`

## Steps

### Step 1: Find Available Backups

```bash
bash .specify/extensions/charter/scripts/bash/backup-list.sh "$(pwd)"
```

`backup-list.sh` prints the available backups (newest first, up to 10) with their
sizes, then `TOTAL_BACKUPS=<n>` and `LATEST=<path>`. If no backups exist it prints
`TOTAL_BACKUPS=0` and exits non-zero — in that case display the error and stop:

```
❌ ERROR: No constitution backups have been created yet.
Backups are created automatically when /speckit.charter.compose runs.
```

### Step 2: Show Restore Preview

Display information about the latest backup and the current constitution:

```bash
bash .specify/extensions/charter/scripts/bash/backup-preview.sh "$(pwd)"
```

`backup-preview.sh` prints the latest backup's metadata, the current
constitution's size and section markers, and the first 20 lines of the backup.

### Step 3: Confirm Restoration

Present the confirmation prompt:

```
⚠️ This will replace the current constitution with the backup from <BACKUP_TIMESTAMP>.

Current constitution: <SIZE> bytes
Backup constitution: <SIZE> bytes

Proceed with restoration? (yes/no)
```

- **yes**: Proceed to Step 4.
- **no**: Cancel and stop.

### Step 4: Restore the Backup

```bash
bash .specify/extensions/charter/scripts/bash/backup-restore.sh "$(pwd)"
```

`backup-restore.sh` first creates a safety backup of the current constitution
(suffixed `-pre-restore`), then overwrites the constitution with the most recent
backup. It prints `SAFETY_BACKUP=<filename>` (if a current constitution existed),
`RESTORED_FROM=<filename>`, and `SIZE=<bytes>`.

### Step 5: Display Result

```
✅ Constitution restored successfully.

Restored from: <BACKUP_FILENAME>
Constitution size: <SIZE> bytes

Note: The state file (.specify/charter/state.yml) has NOT been modified.
      If you want to recompose from current state, run /speckit.charter.compose
      If you want to reconfigure fragments, run /speckit.charter.config
```

## Notes

- The restore command uses the most recent backup file (sorted by filename timestamp)
- A safety backup of the current constitution is created before overwriting, with a `-pre-restore` suffix
- The state file is NOT modified — it still reflects the last configured composition
- After restoration, the constitution may be out of sync with the state file — this is intentional, as the user may want to restore and then reconfigure
- Backups are created automatically by `/speckit.charter.compose` before each composition
