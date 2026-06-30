#!/usr/bin/env bash
# snapshot-read.sh — Read a fragment from the snapshot storage
# Usage: snapshot-read.sh <FRAGMENT_NAME> <TYPE> [PROJECT_ROOT]
#
# Outputs saved snapshot content, or exits with code 2 if not found.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAGMENT_NAME="${1:?Usage: snapshot-read.sh <FRAGMENT_NAME> <TYPE> [PROJECT_ROOT]}"
FRAGMENT_TYPE="${2:-fragment}"
PROJECT_ROOT="${3:-.}"
source "${SCRIPT_DIR}/charter-common.sh"

SNAPSHOT_FILE="${CHARTER_SNAPSHOTS_DIR}/${FRAGMENT_TYPE}/${FRAGMENT_NAME}.md"

if [[ ! -f "$SNAPSHOT_FILE" ]]; then
  exit 2
fi

cat "$SNAPSHOT_FILE"
