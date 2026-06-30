#!/usr/bin/env bash
# constitution-backup.sh — Create a backup of the current constitution.md
# Usage: constitution-backup.sh [PROJECT_ROOT]
#
# Stores backup in .specify/extensions/charter/backups/
# with a timestamped filename.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-.}"
source "${SCRIPT_DIR}/charter-common.sh"

if [[ ! -f "$CONSTITUTION_PATH" ]]; then
  info "No constitution.md found — nothing to back up."
  exit 0
fi

ensure_dir "$CHARTER_BACKUPS_DIR"

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_FILE="${CHARTER_BACKUPS_DIR}/constitution-${TIMESTAMP}.md.backup"

cp "$CONSTITUTION_PATH" "$BACKUP_FILE"
echo "$BACKUP_FILE"
