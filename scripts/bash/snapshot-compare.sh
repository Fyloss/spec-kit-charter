#!/usr/bin/env bash
# snapshot-compare.sh — Compare a constitution section against its snapshot
# Usage: snapshot-compare.sh <SECTION_NAME> <TYPE> [PROJECT_ROOT]
#
# Compares the content of a section in constitution.md against the saved snapshot.
# Exit codes:
#   0 = identical (or no snapshot exists)
#   1 = different
#   2 = snapshot missing
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECTION_NAME="${1:?Usage: snapshot-compare.sh <SECTION_NAME> <TYPE> [PROJECT_ROOT]}"
SECTION_TYPE="${2:-fragment}"
PROJECT_ROOT="${3:-.}"
source "${SCRIPT_DIR}/charter-common.sh"

SNAPSHOT_FILE="${CHARTER_SNAPSHOTS_DIR}/${SECTION_TYPE}/${SECTION_NAME}.md"

if [[ ! -f "$SNAPSHOT_FILE" ]]; then
  exit 2
fi

# Extract current section from constitution
CURRENT_CONTENT="$(bash "${SCRIPT_DIR}/constitution-extract.sh" "$SECTION_NAME" "$CONSTITUTION_PATH" 2>/dev/null || true)"
SNAPSHOT_CONTENT="$(cat "$SNAPSHOT_FILE")"

if [[ "$CURRENT_CONTENT" == "$SNAPSHOT_CONTENT" ]]; then
  exit 0
else
  exit 1
fi
