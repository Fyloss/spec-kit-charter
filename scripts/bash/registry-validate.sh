#!/usr/bin/env bash
# registry-validate.sh — Validate a charter registry structure
# Usage: registry-validate.sh [PROJECT_ROOT]
#
# Exit codes:
#   0 = valid registry
#   1 = invalid registry (details on stderr)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/charter-common.sh"
PROJECT_ROOT="${1:-.}"

# Re-source with updated PROJECT_ROOT
source "${SCRIPT_DIR}/charter-common.sh"

resolve_registry_path

if [[ ! -d "$REGISTRY_LOCAL_PATH" ]]; then
  die "Registry path does not exist: $REGISTRY_LOCAL_PATH"
fi

if [[ ! -f "${REGISTRY_LOCAL_PATH}/manifest.yml" ]]; then
  die "Registry is missing required manifest.yml at: $REGISTRY_LOCAL_PATH"
fi

# Validate manifest has required fields
manifest_version="$(yaml_field "${REGISTRY_LOCAL_PATH}/manifest.yml" "version")"
manifest_name="$(yaml_field "${REGISTRY_LOCAL_PATH}/manifest.yml" "name")"

if [[ -z "$manifest_version" ]]; then
  die "manifest.yml is missing required field: version"
fi

if [[ -z "$manifest_name" ]]; then
  die "manifest.yml is missing required field: name"
fi

if [[ ! -d "${REGISTRY_LOCAL_PATH}/fragments" ]]; then
  warn "Registry has no 'fragments' directory — no fragments available"
fi

echo "VALID"
echo "name=${manifest_name}"
echo "version=${manifest_version}"
