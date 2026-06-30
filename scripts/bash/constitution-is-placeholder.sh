#!/usr/bin/env bash
# constitution-is-placeholder.sh — Check if a constitution file is a placeholder template
# Usage: constitution-is-placeholder.sh [CONSTITUTION_PATH]
#
# A constitution is considered a placeholder if it contains bracket-style
# placeholder tokens like [PROJECT_NAME], [PRINCIPLE_1_NAME], [CONSTITUTION_VERSION], etc.
#
# Exit codes:
#   0 = IS a placeholder (should not be used as local constitution)
#   1 = NOT a placeholder (valid constitution)
#   2 = file does not exist
set -euo pipefail

CONSTITUTION_PATH="${1:-.specify/memory/constitution.md}"

if [[ ! -f "$CONSTITUTION_PATH" ]]; then
  echo "FILE_EXISTS=false"
  exit 2
fi

# Count placeholder markers — these are the known Spec Kit template placeholders
PLACEHOLDER_COUNT=$(grep -cE '\[(PROJECT_NAME|PRINCIPLE_[0-9]+_NAME|PRINCIPLE_[0-9]+_DESCRIPTION|SECTION_[0-9]+_NAME|SECTION_[0-9]+_CONTENT|CONSTITUTION_VERSION|RATIFICATION_DATE|LAST_AMENDED_DATE|GOVERNANCE_RULES)\]' "$CONSTITUTION_PATH" 2>/dev/null || true)
PLACEHOLDER_COUNT="${PLACEHOLDER_COUNT:-0}"
# Trim whitespace
PLACEHOLDER_COUNT="$(echo "$PLACEHOLDER_COUNT" | tr -d '[:space:]')"

if [[ "$PLACEHOLDER_COUNT" -gt 0 ]]; then
  echo "IS_PLACEHOLDER=true"
  echo "PLACEHOLDER_COUNT=$PLACEHOLDER_COUNT"
  exit 0
else
  echo "IS_PLACEHOLDER=false"
  exit 1
fi
