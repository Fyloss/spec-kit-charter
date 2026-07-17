#!/usr/bin/env bash
# snapshot-detect-modified.sh — Detect sections modified since last composition
# Usage: snapshot-detect-modified.sh [PROJECT_ROOT]
#
# Reads the fragment list from state.yml and compares each fragment section in
# the current constitution against its saved snapshot.
#
# NOTE: Only fragments are snapshotted. Sub-constitutions (registry and
# distributed) are cacheless — they are re-read fresh on every compose — so they
# are never reported here as "modified".
# Output:
#   MODIFIED=true
#   MODIFIED_SECTION=<name>   (one line per modified section)
#   -- or --
#   MODIFIED=false
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-.}"
source "${SCRIPT_DIR}/charter-common.sh"

if [[ ! -f "$CHARTER_STATE" ]]; then
  echo "MODIFIED=false"
  exit 0
fi

modified=()

check() {
  local name="$1" type="$2" rc=0
  bash "${SCRIPT_DIR}/snapshot-compare.sh" "$name" "$type" "$PROJECT_ROOT" >/dev/null 2>&1 || rc=$?
  if [[ "$rc" -eq 1 ]]; then
    modified+=("$name")
  fi
}

while IFS= read -r frag; do
  [[ -z "$frag" ]] && continue
  check "$frag" "fragment"
done < <(yaml_list "$CHARTER_STATE" "fragments")

if [[ ${#modified[@]} -gt 0 ]]; then
  echo "MODIFIED=true"
  for s in "${modified[@]}"; do
    echo "MODIFIED_SECTION=$s"
  done
else
  echo "MODIFIED=false"
fi
