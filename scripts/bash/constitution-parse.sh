#!/usr/bin/env bash
# constitution-parse.sh — Parse an existing constitution.md for section markers
# Usage: constitution-parse.sh [CONSTITUTION_PATH]
#
# Output format (one per line):
#   SECTION_NAME
#
# Section markers are HTML comments: <!-- [SECTION_NAME] SECTION -->
# Also outputs "HAS_SECTIONS=true" or "HAS_SECTIONS=false" as first line.
set -euo pipefail

CONSTITUTION_PATH="${1:-.specify/memory/constitution.md}"

if [[ ! -f "$CONSTITUTION_PATH" ]]; then
  echo "HAS_SECTIONS=false"
  echo "FILE_EXISTS=false"
  exit 0
fi

echo "FILE_EXISTS=true"

# Extract section names from HTML comment markers
sections=()
while IFS= read -r line; do
  # Match: <!-- [SECTION_NAME] SECTION -->
  if [[ "$line" =~ ^[[:space:]]*\<!--[[:space:]]*\[([^\]]+)\][[:space:]]*SECTION[[:space:]]*--\> ]]; then
    sections+=("${BASH_REMATCH[1]}")
  fi
done < "$CONSTITUTION_PATH"

if [[ ${#sections[@]} -eq 0 ]]; then
  echo "HAS_SECTIONS=false"
else
  echo "HAS_SECTIONS=true"
  for s in "${sections[@]}"; do
    echo "SECTION=$s"
  done
fi
