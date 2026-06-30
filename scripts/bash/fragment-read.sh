#!/usr/bin/env bash
# fragment-read.sh — Read a fragment's content from the registry
# Usage: fragment-read.sh <FRAGMENT_NAME> <TYPE> [PROJECT_ROOT]
#
# TYPE: "fragment" or "sub-constitution"
# FRAGMENT_NAME: relative path without .md (e.g., "global/compliance")
#
# Outputs the fragment content to stdout.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAGMENT_NAME="${1:?Usage: fragment-read.sh <FRAGMENT_NAME> <TYPE> [PROJECT_ROOT]}"
FRAGMENT_TYPE="${2:-fragment}"
PROJECT_ROOT="${3:-.}"
source "${SCRIPT_DIR}/charter-common.sh"

resolve_registry_path

if [[ "$FRAGMENT_TYPE" == "sub-constitution" ]]; then
  FRAGMENT_FILE="${REGISTRY_LOCAL_PATH}/sub-constitutions/${FRAGMENT_NAME}.md"
else
  FRAGMENT_FILE="${REGISTRY_LOCAL_PATH}/fragments/${FRAGMENT_NAME}.md"
fi

if [[ ! -f "$FRAGMENT_FILE" ]]; then
  die "Fragment not found: $FRAGMENT_FILE"
fi

cat "$FRAGMENT_FILE"
