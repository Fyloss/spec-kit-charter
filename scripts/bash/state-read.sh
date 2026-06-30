#!/usr/bin/env bash
# state-read.sh — Read the charter state file
# Usage: state-read.sh [PROJECT_ROOT]
#
# Outputs state file content or empty if not found.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-.}"
source "${SCRIPT_DIR}/charter-common.sh"

if [[ -f "$CHARTER_STATE" ]]; then
  cat "$CHARTER_STATE"
else
  echo "# No charter state configured yet."
  echo "# Run /speckit.charter.config to set up."
fi
