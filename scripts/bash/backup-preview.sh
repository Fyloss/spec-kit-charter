#!/usr/bin/env bash
# backup-preview.sh — Preview the latest backup and the current constitution
# Usage: backup-preview.sh [PROJECT_ROOT]
#
# Prints metadata for the most recent backup, the current constitution's size
# and section markers, and the first 20 lines of the backup content.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-.}"
source "${SCRIPT_DIR}/charter-common.sh"

LATEST="$(find "$CHARTER_BACKUPS_DIR" -name '*.md.backup' -type f 2>/dev/null | sort -r | head -1)"
if [[ -z "$LATEST" ]]; then
  die "No backups found in $CHARTER_BACKUPS_DIR"
fi

echo "=== LATEST BACKUP ==="
echo "File: $(basename "$LATEST")"
echo "Size: $(wc -c < "$LATEST") bytes"
echo "Date: $(stat -c %y "$LATEST" 2>/dev/null || stat -f %Sm "$LATEST" 2>/dev/null)"
echo ""

echo "=== CURRENT CONSTITUTION ==="
if [[ -f "$CONSTITUTION_PATH" ]]; then
  echo "Size: $(wc -c < "$CONSTITUTION_PATH") bytes"
  echo "Sections:"
  bash "${SCRIPT_DIR}/constitution-parse.sh" "$CONSTITUTION_PATH"
else
  echo "No constitution file exists."
fi

echo ""
echo "=== BACKUP CONTENT PREVIEW (first 20 lines) ==="
head -20 "$LATEST"
