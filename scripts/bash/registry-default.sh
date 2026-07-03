#!/usr/bin/env bash
# registry-default.sh — Report the existing/default registry to propose to the user
# Usage: registry-default.sh [PROJECT_ROOT]
#
# Output:
#   EXISTING_CONFIG=true  + "registry: <value>"   (when config.yml exists)
#   EXISTING_CONFIG=false + "registry: .charter"  (default proposal)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-.}"
source "${SCRIPT_DIR}/charter-common.sh"

if [[ -f "$CHARTER_CONFIG" ]]; then
  echo "EXISTING_CONFIG=true"
  echo "registry: $(yaml_field "$CHARTER_CONFIG" "registry")"
else
  echo "EXISTING_CONFIG=false"
  echo "registry: .charter"
fi
