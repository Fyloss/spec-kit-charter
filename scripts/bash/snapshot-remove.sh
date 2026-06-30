#!/usr/bin/env bash
# snapshot-remove.sh — Remove a fragment snapshot
# Usage: snapshot-remove.sh <FRAGMENT_NAME> <TYPE> [PROJECT_ROOT]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAGMENT_NAME="${1:?Usage: snapshot-remove.sh <FRAGMENT_NAME> <TYPE> [PROJECT_ROOT]}"
FRAGMENT_TYPE="${2:-fragment}"
PROJECT_ROOT="${3:-.}"
source "${SCRIPT_DIR}/charter-common.sh"

SNAPSHOT_FILE="${CHARTER_SNAPSHOTS_DIR}/${FRAGMENT_TYPE}/${FRAGMENT_NAME}.md"

if [[ -f "$SNAPSHOT_FILE" ]]; then
  rm "$SNAPSHOT_FILE"
  echo "Snapshot removed: $SNAPSHOT_FILE"
else
  echo "No snapshot found for: $FRAGMENT_NAME"
fi
