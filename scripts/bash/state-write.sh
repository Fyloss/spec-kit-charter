#!/usr/bin/env bash
# state-write.sh — Write the charter state file
# Usage: state-write.sh [PROJECT_ROOT]
#
# Reads state YAML from stdin and writes to the state file.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-.}"
source "${SCRIPT_DIR}/charter-common.sh"

ensure_dir "$CHARTER_EXT_DIR"

cat > "$CHARTER_STATE"
echo "State saved to: $CHARTER_STATE"
