#!/usr/bin/env bash
# fragment-is-mandatory.sh — Check whether a fragment is mandatory in the registry
# Usage: fragment-is-mandatory.sh <FRAGMENT_NAME> [PROJECT_ROOT]
#
# Reads the registry manifest's mandatory_fragments list.
# Output: "MANDATORY=true" or "MANDATORY=false".
# Exit code: 0 = mandatory, 1 = not mandatory
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAGMENT_NAME="${1:?Usage: fragment-is-mandatory.sh <FRAGMENT_NAME> [PROJECT_ROOT]}"
PROJECT_ROOT="${2:-.}"
source "${SCRIPT_DIR}/charter-common.sh"

resolve_registry_path
MANIFEST="${REGISTRY_LOCAL_PATH}/manifest.yml"

if [[ -f "$MANIFEST" ]] && yaml_list "$MANIFEST" "mandatory_fragments" | grep -qxF "$FRAGMENT_NAME"; then
  echo "MANDATORY=true"
  exit 0
else
  echo "MANDATORY=false"
  exit 1
fi
