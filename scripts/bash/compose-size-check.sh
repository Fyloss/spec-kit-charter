#!/usr/bin/env bash
# compose-size-check.sh — Calculate total size of composed constitution
# Usage: compose-size-check.sh [PROJECT_ROOT]
#
# Reads state.yml, fetches all fragment content + local constitution,
# and outputs the total byte count.
# Outputs:
#   TOTAL_BYTES=<number>
#   EXCEEDS_32K=true|false
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-.}"
source "${SCRIPT_DIR}/charter-common.sh"

if [[ ! -f "$CHARTER_STATE" ]]; then
  die "No charter state found. Run /speckit.charter.config first."
fi

resolve_registry_path

total_bytes=0

# Read fragments from state
while IFS= read -r frag; do
  [[ -z "$frag" ]] && continue
  frag_file="${REGISTRY_LOCAL_PATH}/fragments/${frag}.md"
  if [[ -f "$frag_file" ]]; then
    size=$(wc -c < "$frag_file")
    total_bytes=$((total_bytes + size))
  fi
done < <(yaml_list "$CHARTER_STATE" "fragments")

# Read sub-constitutions from state.
# IDs are stored as "sub-constitutions/<name>"; strip the prefix to get the
# filename under the registry's sub-constitutions/ directory.
while IFS= read -r sub; do
  [[ -z "$sub" ]] && continue
  # Strip "sub-constitutions/" prefix if present (new ID format)
  name="${sub#sub-constitutions/}"
  sub_file="${REGISTRY_LOCAL_PATH}/sub-constitutions/${name}.md"
  if [[ -f "$sub_file" ]]; then
    size=$(wc -c < "$sub_file")
    total_bytes=$((total_bytes + size))
  fi
done < <(yaml_list "$CHARTER_STATE" "sub_constitutions")

# Read distributed sub-constitutions from state (local package files).
# IDs are stored as "<pkg>/.charter/constitution"; strip the suffix to get the
# package path, then resolve to the on-disk file.
while IFS= read -r dist; do
  [[ -z "$dist" ]] && continue
  # Strip "/.charter/constitution" suffix to recover the package path
  pkg="${dist%/.charter/constitution}"
  validate_package_path "$pkg"
  dist_file="${PROJECT_ROOT}/${pkg}/.charter/constitution.md"
  if [[ -f "$dist_file" ]]; then
    size=$(wc -c < "$dist_file")
    total_bytes=$((total_bytes + size))
  fi
done < <(yaml_list "$CHARTER_STATE" "distributed_sub_constitutions")

# Check local constitution
has_local="$(yaml_field "$CHARTER_STATE" "local_constitution")"
if [[ "$has_local" == "true" ]]; then
  # Estimate from stored content or from current file
  if [[ -f "$CONSTITUTION_PATH" ]]; then
    size=$(wc -c < "$CONSTITUTION_PATH")
    total_bytes=$((total_bytes + size))
  fi
fi

# Add overhead for section markers (~100 bytes each)
section_count=0
section_count=$((section_count + $(yaml_list "$CHARTER_STATE" "fragments" | wc -l)))
section_count=$((section_count + $(yaml_list "$CHARTER_STATE" "sub_constitutions" | wc -l)))
section_count=$((section_count + $(yaml_list "$CHARTER_STATE" "distributed_sub_constitutions" | wc -l)))
if [[ "$has_local" == "true" ]]; then
  section_count=$((section_count + 1))
fi
total_bytes=$((total_bytes + section_count * 100))

echo "TOTAL_BYTES=${total_bytes}"
if [[ $total_bytes -gt 32768 ]]; then
  echo "EXCEEDS_32K=true"
else
  echo "EXCEEDS_32K=false"
fi
