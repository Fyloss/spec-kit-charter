#!/usr/bin/env bash
# config-distributed-set.sh — Enable/disable distributed sub-constitutions
# Usage: config-distributed-set.sh <true|false> [PROJECT_ROOT]
#
# Updates the "distributed_sub_constitutions" flag in .specify/charter/config.yml
# while preserving the existing registry and registry_type values.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAG="${1:?Usage: config-distributed-set.sh <true|false> [PROJECT_ROOT]}"
PROJECT_ROOT="${2:-.}"
source "${SCRIPT_DIR}/charter-common.sh"

[[ "$FLAG" == "true" || "$FLAG" == "false" ]] || die "Flag must be 'true' or 'false' (got: $FLAG)"
[[ -f "$CHARTER_CONFIG" ]] || die "No config found. Run /speckit.charter.config first."

registry="$(get_registry)"
reg_type="$(get_registry_type)"
write_config "$registry" "$reg_type" "$FLAG"

echo "Config updated: $CHARTER_CONFIG"
echo "distributed_sub_constitutions=${FLAG}"
