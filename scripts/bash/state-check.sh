#!/usr/bin/env bash
# state-check.sh — Report whether the charter state file exists, and print it
# Usage: state-check.sh [PROJECT_ROOT]
#
# Output:
#   STATE_EXISTS=true  (followed by "=== STATE ===" and the state content)
#   STATE_EXISTS=false
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-.}"
source "${SCRIPT_DIR}/charter-common.sh"

if [[ -f "$CHARTER_STATE" ]]; then
  echo "STATE_EXISTS=true"
  echo "=== STATE ==="
  cat "$CHARTER_STATE"
else
  echo "STATE_EXISTS=false"
fi
