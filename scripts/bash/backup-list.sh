#!/usr/bin/env bash
# backup-list.sh — List available constitution backups (newest first)
# Usage: backup-list.sh [PROJECT_ROOT]
#
# Output (when backups exist):
#   === AVAILABLE BACKUPS ===
#   <filename> (<size> bytes)      (up to 10, newest first)
#   TOTAL_BACKUPS=<n>
#   LATEST=<absolute path to newest backup>
# When none exist: TOTAL_BACKUPS=0
# Exit code: 0 = at least one backup, 1 = none
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-.}"
source "${SCRIPT_DIR}/charter-common.sh"

if [[ ! -d "$CHARTER_BACKUPS_DIR" ]]; then
  echo "TOTAL_BACKUPS=0"
  exit 1
fi

mapfile -t backups < <(find "$CHARTER_BACKUPS_DIR" -name '*.md.backup' -type f | sort -r)

if [[ ${#backups[@]} -eq 0 ]]; then
  echo "TOTAL_BACKUPS=0"
  exit 1
fi

echo "=== AVAILABLE BACKUPS ==="
for f in "${backups[@]:0:10}"; do
  echo "$(basename "$f") ($(wc -c < "$f") bytes)"
done

echo "TOTAL_BACKUPS=${#backups[@]}"
echo "LATEST=${backups[0]}"
