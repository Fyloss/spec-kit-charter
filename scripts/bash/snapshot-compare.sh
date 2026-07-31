#!/usr/bin/env bash
# snapshot-compare.sh — Compare a constitution section against its snapshot
# Usage: snapshot-compare.sh <SECTION_NAME> <TYPE> [PROJECT_ROOT]
#
# Compares the content of a section in constitution.md against the saved snapshot.
# Heading levels are ignored during comparison: compose auto-shifts headings to H2
# in the final constitution, while snapshots store the original registry heading
# levels. Stripping leading '#' chars from heading lines prevents false positives.
#
# Exit codes:
#   0 = identical (ignoring heading indent)
#   1 = different (non-heading content changed → real user edit)
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

# Strip leading '#' characters (and the following space) from every heading line
# so that heading-level differences introduced by compose's auto-indent do not
# cause false change detection.
normalize_headings() {
  sed 's/^#\+[[:space:]]*//'
}

# Extract current section from constitution
CURRENT_CONTENT="$(bash "${SCRIPT_DIR}/constitution-extract.sh" "$SECTION_NAME" "$CONSTITUTION_PATH" 2>/dev/null || true)"
SNAPSHOT_CONTENT="$(cat "$SNAPSHOT_FILE")"

CURRENT_NORM="$(printf '%s' "$CURRENT_CONTENT" | normalize_headings)"
SNAPSHOT_NORM="$(printf '%s' "$SNAPSHOT_CONTENT" | normalize_headings)"

if [[ "$CURRENT_NORM" == "$SNAPSHOT_NORM" ]]; then
  exit 0
else
  exit 1
fi
