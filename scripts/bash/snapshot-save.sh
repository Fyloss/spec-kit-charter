#!/usr/bin/env bash
# snapshot-save.sh — Save fragment snapshots to local storage
# Usage: snapshot-save.sh <FRAGMENT_NAME> <TYPE> [PROJECT_ROOT]
#
# Saves the current registry version of a fragment to the snapshots directory.
# This is used to detect changes between compose runs.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAGMENT_NAME="${1:?Usage: snapshot-save.sh <FRAGMENT_NAME> <TYPE> [PROJECT_ROOT]}"
FRAGMENT_TYPE="${2:-fragment}"
PROJECT_ROOT="${3:-.}"
source "${SCRIPT_DIR}/charter-common.sh"

resolve_registry_path

if [[ "$FRAGMENT_TYPE" == "sub-constitution" ]]; then
  SOURCE="${REGISTRY_LOCAL_PATH}/sub-constitutions/${FRAGMENT_NAME}.md"
else
  SOURCE="${REGISTRY_LOCAL_PATH}/fragments/${FRAGMENT_NAME}.md"
fi

if [[ ! -f "$SOURCE" ]]; then
  die "Fragment not found in registry: $FRAGMENT_NAME"
fi

SNAPSHOT_FILE="${CHARTER_SNAPSHOTS_DIR}/${FRAGMENT_TYPE}/${FRAGMENT_NAME}.md"
ensure_dir "$(dirname "$SNAPSHOT_FILE")"
cp "$SOURCE" "$SNAPSHOT_FILE"

echo "Snapshot saved: $SNAPSHOT_FILE"
