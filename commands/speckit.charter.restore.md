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
PROJECT_ROOT="$(pwd)"
BACKUP_DIR="${PROJECT_ROOT}/.specify/charter/backups"

if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "❌ ERROR: No backup directory found."
  echo "No constitution backups have been created yet."
  echo "Backups are created automatically when /speckit.charter.compose runs."
  exit 1
fi

# List backups sorted by date (newest first)
BACKUPS=$(find "$BACKUP_DIR" -name '*.md.backup' -type f | sort -r)
if [[ -z "$BACKUPS" ]]; then
  echo "❌ ERROR: No backups found in $BACKUP_DIR"
  echo "Backups are created automatically when /speckit.charter.compose runs."
  exit 1
fi

echo "=== AVAILABLE BACKUPS ==="
echo "$BACKUPS" | head -10 | while read -r f; do
  FILENAME=$(basename "$f")
  SIZE=$(wc -c < "$f")
  echo "$FILENAME ($SIZE bytes)"
done

BACKUP_COUNT=$(echo "$BACKUPS" | wc -l)
echo ""
echo "TOTAL_BACKUPS=$BACKUP_COUNT"
echo "LATEST=$(echo "$BACKUPS" | head -1)"
```

If no backups exist, display the error and stop.

### Step 2: Show Restore Preview

Display information about the latest backup and the current constitution:

```bash
PROJECT_ROOT="$(pwd)"
CONSTITUTION="${PROJECT_ROOT}/.specify/memory/constitution.md"
BACKUP_DIR="${PROJECT_ROOT}/.specify/charter/backups"
LATEST=$(find "$BACKUP_DIR" -name '*.md.backup' -type f | sort -r | head -1)

echo "=== LATEST BACKUP ==="
echo "File: $(basename "$LATEST")"
echo "Size: $(wc -c < "$LATEST") bytes"
echo "Date: $(stat -c %y "$LATEST" 2>/dev/null || stat -f %Sm "$LATEST" 2>/dev/null)"
echo ""

echo "=== CURRENT CONSTITUTION ==="
if [[ -f "$CONSTITUTION" ]]; then
  echo "Size: $(wc -c < "$CONSTITUTION") bytes"
  echo "Sections:"
  grep -E '^\s*<!-- \[.+\] SECTION -->' "$CONSTITUTION" 2>/dev/null || echo "(no section markers)"
else
  echo "No constitution file exists."
fi

echo ""
echo "=== BACKUP CONTENT PREVIEW (first 20 lines) ==="
head -20 "$LATEST"
```

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
PROJECT_ROOT="$(pwd)"
CONSTITUTION="${PROJECT_ROOT}/.specify/memory/constitution.md"
BACKUP_DIR="${PROJECT_ROOT}/.specify/charter/backups"
LATEST=$(find "$BACKUP_DIR" -name '*.md.backup' -type f | sort -r | head -1)

# Create a safety backup of the CURRENT constitution before overwriting
if [[ -f "$CONSTITUTION" ]]; then
  TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
  cp "$CONSTITUTION" "${BACKUP_DIR}/constitution-${TIMESTAMP}-pre-restore.md.backup"
  echo "Safety backup of current version: constitution-${TIMESTAMP}-pre-restore.md.backup"
fi

# Restore
cp "$LATEST" "$CONSTITUTION"
echo "✅ Constitution restored from: $(basename "$LATEST")"
```

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
