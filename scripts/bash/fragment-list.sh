#!/usr/bin/env bash
# fragment-list.sh — List all fragments and sub-constitutions from a registry
# Usage: fragment-list.sh [PROJECT_ROOT]
#
# Output format (tab-separated):
#   TYPE\tCATEGORY\tPATH\tNAME
#
# TYPE: mandatory_fragment | recommended_fragment | fragment | sub-constitution
# CATEGORY: the parent folder path (e.g., "global", "languages/typescript")
# PATH: relative path within fragments/ or sub-constitutions/
# NAME: display name (path without .md extension)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-.}"
source "${SCRIPT_DIR}/charter-common.sh"

resolve_registry_path
MANIFEST="${REGISTRY_LOCAL_PATH}/manifest.yml"
FRAGMENTS_DIR="${REGISTRY_LOCAL_PATH}/fragments"
SUB_CONST_DIR="${REGISTRY_LOCAL_PATH}/sub-constitutions"

# Read mandatory and recommended lists from manifest (newline-delimited, no
# associative arrays — macOS ships bash 3.2 which lacks `declare -A`)
MANDATORY_LIST="$(yaml_list "$MANIFEST" "mandatory_fragments")"
RECOMMENDED_LIST="$(yaml_list "$MANIFEST" "recommended_fragments")"

is_in_list() {
  local needle="$1" list="$2" line
  while IFS= read -r line; do
    [[ "$line" == "$needle" ]] && return 0
  done <<< "$list"
  return 1
}

# List fragments recursively
if [[ -d "$FRAGMENTS_DIR" ]]; then
  while IFS= read -r file; do
    # Get path relative to fragments/
    rel_path="${file#${FRAGMENTS_DIR}/}"
    # Name is path without .md
    name="${rel_path%.md}"
    # Category is the directory part
    category="$(dirname "$rel_path")"
    [[ "$category" == "." ]] && category=""

    if is_in_list "$name" "$MANDATORY_LIST"; then
      echo -e "mandatory_fragment\t${category}\t${rel_path}\t${name}"
    elif is_in_list "$name" "$RECOMMENDED_LIST"; then
      echo -e "recommended_fragment\t${category}\t${rel_path}\t${name}"
    else
      echo -e "fragment\t${category}\t${rel_path}\t${name}"
    fi
  done < <(find "$FRAGMENTS_DIR" -name '*.md' -type f | sort)
fi

# List sub-constitutions
if [[ -d "$SUB_CONST_DIR" ]]; then
  while IFS= read -r file; do
    rel_path="${file#${SUB_CONST_DIR}/}"
    name="${rel_path%.md}"
    echo -e "sub-constitution\t\t${rel_path}\t${name}"
  done < <(find "$SUB_CONST_DIR" -name '*.md' -type f | sort)
fi
