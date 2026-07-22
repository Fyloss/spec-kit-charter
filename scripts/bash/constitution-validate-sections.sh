#!/usr/bin/env bash
# constitution-validate-sections.sh — Verify all expected section markers exist
# Usage: constitution-validate-sections.sh [PROJECT_ROOT]
#
# Expected sections are derived from state.yml (fragments + sub-constitutions +
# distributed sub-constitutions + the PROJECT SPECIFIC section when
# local_constitution is true). Each expected section must have a
# "<!-- [NAME] SECTION -->" marker in the generated constitution.
#
# Output:
#   VALID=true
#   -- or --
#   VALID=false + MISSING=<name> lines
# Exit code: 0 = valid, 1 = missing sections or no constitution
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-.}"
source "${SCRIPT_DIR}/charter-common.sh"

if [[ ! -f "$CONSTITUTION_PATH" ]]; then
  echo "VALID=false"
  echo "ERROR=constitution.md was not created"
  exit 1
fi

[[ -f "$CHARTER_STATE" ]] || die "No charter state found: $CHARTER_STATE"

expected=()
while IFS= read -r frag; do
  [[ -z "$frag" ]] && continue
  expected+=("$frag")
done < <(yaml_list "$CHARTER_STATE" "fragments")

while IFS= read -r sub; do
  [[ -z "$sub" ]] && continue
  expected+=("$sub")
done < <(yaml_list "$CHARTER_STATE" "sub_constitutions")

while IFS= read -r dist; do
  [[ -z "$dist" ]] && continue
  validate_package_path "$dist"
  expected+=("$dist")
done < <(yaml_list "$CHARTER_STATE" "distributed_sub_constitutions")

if [[ "$(yaml_field "$CHARTER_STATE" "local_constitution")" == "true" ]]; then
  expected+=("PROJECT SPECIFIC")
fi

missing=()
for section in "${expected[@]}"; do
  if ! grep -q "<!-- \[${section}\] SECTION -->" "$CONSTITUTION_PATH" 2>/dev/null; then
    missing+=("$section")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "VALID=false"
  for m in "${missing[@]}"; do
    echo "MISSING=$m"
  done
  exit 1
else
  echo "VALID=true"
fi
