#!/usr/bin/env bash
# registry-fetch.sh — Fetch/refresh registry and resolve its local path
# Usage: registry-fetch.sh [PROJECT_ROOT]
#
# Outputs the resolved local path to the registry on success.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-.}"
source "${SCRIPT_DIR}/charter-common.sh"

resolve_registry_path

echo "$REGISTRY_LOCAL_PATH"
