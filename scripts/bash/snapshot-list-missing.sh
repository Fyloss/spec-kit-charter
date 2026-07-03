#!/usr/bin/env bash
# snapshot-list-missing.sh — List state fragments that have no saved snapshot
# Usage: snapshot-list-missing.sh [PROJECT_ROOT]
#
# Reads the fragment and sub-constitution lists from state.yml and reports any
# whose snapshot file is missing from the snapshot store.
# Output:
#   MISSING_SNAPSHOTS=true
#   MISSING=<name>   (one line per missing snapshot)
#   -- or --
#   MISSING_SNAPSHOTS=false
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-.}"
source "${SCRIPT_DIR}/charter-common.sh"

if [[ ! -f "$CHARTER_STATE" ]]; then
  echo "MISSING_SNAPSHOTS=false"
  exit 0
fi

missing=()

while IFS= read -r frag; do
  [[ -z "$frag" ]] && continue
  [[ -f "${CHARTER_SNAPSHOTS_DIR}/fragment/${frag}.md" ]] || missing+=("$frag")
done < <(yaml_list "$CHARTER_STATE" "fragments")

while IFS= read -r sub; do
  [[ -z "$sub" ]] && continue
  [[ -f "${CHARTER_SNAPSHOTS_DIR}/sub-constitution/${sub}.md" ]] || missing+=("$sub")
done < <(yaml_list "$CHARTER_STATE" "sub_constitutions")

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "MISSING_SNAPSHOTS=true"
  for m in "${missing[@]}"; do
    echo "MISSING=$m"
  done
else
  echo "MISSING_SNAPSHOTS=false"
fi
