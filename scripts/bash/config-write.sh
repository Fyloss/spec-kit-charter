#!/usr/bin/env bash
# config-write.sh — Write charter config file
# Usage: config-write.sh <REGISTRY_VALUE> [PROJECT_ROOT]
#
# Writes .specify/charter/config.yml with the given registry value.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGISTRY_VALUE="${1:?Usage: config-write.sh <REGISTRY_VALUE> [PROJECT_ROOT]}"
PROJECT_ROOT="${2:-.}"
source "${SCRIPT_DIR}/charter-common.sh"

ensure_charter_data_dir

# Detect type
if is_git_url "$REGISTRY_VALUE"; then
  REG_TYPE="git"
else
  REG_TYPE="directory"
fi

# Preserve the existing distributed sub-constitutions flag across registry
# changes (defaults to false when no config exists yet).
DISTRIBUTED="$(get_distributed_enabled)"

write_config "$REGISTRY_VALUE" "$REG_TYPE" "$DISTRIBUTED"

echo "Config saved to: $CHARTER_CONFIG"
echo "registry=${REGISTRY_VALUE}"
echo "registry_type=${REG_TYPE}"
echo "distributed_sub_constitutions=${DISTRIBUTED}"
