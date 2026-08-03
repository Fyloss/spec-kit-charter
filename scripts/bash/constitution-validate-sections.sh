#!/usr/bin/env bash
# constitution-validate-sections.sh — Verify all expected section markers exist
# Usage: constitution-validate-sections.sh [PROJECT_ROOT]
#
# Expected sections are derived from state.yml (fragments + sub-constitutions +
# distributed sub-constitutions + the PROJECT SPECIFIC section when
# local_constitution is true). Each expected section must have a typed section
# marker in the generated constitution:
#
#   <!-- [F]   ID SECTION -->   (fragments)
#   <!-- [SC]  ID SECTION -->   (registry sub-constitutions)
#   <!-- [DSC] ID SECTION -->   (distributed sub-constitutions)
#   <!-- [PS]  PROJECT SPECIFIC SECTION -->   (project-specific)
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

missing=()

# Fragments → [F] tag
while IFS= read -r frag; do
  [[ -z "$frag" ]] && continue
  if ! grep -q "<!-- \[F\] ${frag} SECTION -->" "$CONSTITUTION_PATH" 2>/dev/null; then
    missing+=("$frag")
  fi
done < <(yaml_list "$CHARTER_STATE" "fragments")

# Registry sub-constitutions → [SC] tag
while IFS= read -r sub; do
  [[ -z "$sub" ]] && continue
  if ! grep -q "<!-- \[SC\] ${sub} SECTION -->" "$CONSTITUTION_PATH" 2>/dev/null; then
    missing+=("$sub")
  fi
done < <(yaml_list "$CHARTER_STATE" "sub_constitutions")

# Distributed sub-constitutions → [DSC] tag
while IFS= read -r dist; do
  [[ -z "$dist" ]] && continue
  if ! grep -q "<!-- \[DSC\] ${dist} SECTION -->" "$CONSTITUTION_PATH" 2>/dev/null; then
    missing+=("$dist")
  fi
done < <(yaml_list "$CHARTER_STATE" "distributed_sub_constitutions")

# Project-specific → [PS] tag
if [[ "$(yaml_field "$CHARTER_STATE" "local_constitution")" == "true" ]]; then
  if ! grep -q "<!-- \[PS\] PROJECT SPECIFIC SECTION -->" "$CONSTITUTION_PATH" 2>/dev/null; then
    missing+=("PROJECT SPECIFIC")
  fi
fi

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "VALID=false"
  for m in "${missing[@]}"; do
    echo "MISSING=$m"
  done
  exit 1
else
  echo "VALID=true"
fi
