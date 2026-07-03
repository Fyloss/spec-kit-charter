#!/usr/bin/env bash
# backup-restore.sh — Restore the constitution from the most recent backup
# Usage: backup-restore.sh [PROJECT_ROOT]
#
# Creates a safety backup of the current constitution (suffixed -pre-restore)
# before overwriting it with the latest backup.
# Output:
#   SAFETY_BACKUP=<filename>   (only when a current constitution existed)
#   RESTORED_FROM=<filename>
#   SIZE=<bytes> bytes
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-.}"
source "${SCRIPT_DIR}/charter-common.sh"

LATEST="$(find "$CHARTER_BACKUPS_DIR" -name '*.md.backup' -type f 2>/dev/null | sort -r | head -1)"
if [[ -z "$LATEST" ]]; then
  die "No backups found in $CHARTER_BACKUPS_DIR"
fi

# Safety backup of the CURRENT constitution before overwriting
if [[ -f "$CONSTITUTION_PATH" ]]; then
  ensure_dir "$CHARTER_BACKUPS_DIR"
  TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
  SAFETY="${CHARTER_BACKUPS_DIR}/constitution-${TIMESTAMP}-pre-restore.md.backup"
  cp "$CONSTITUTION_PATH" "$SAFETY"
  echo "SAFETY_BACKUP=$(basename "$SAFETY")"
fi

ensure_dir "$(dirname "$CONSTITUTION_PATH")"
cp "$LATEST" "$CONSTITUTION_PATH"
echo "RESTORED_FROM=$(basename "$LATEST")"
echo "SIZE=$(wc -c < "$CONSTITUTION_PATH") bytes"
