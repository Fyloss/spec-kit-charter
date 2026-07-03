#!/usr/bin/env bash
# constitution-extract.sh — Extract content of a specific section from constitution.md
# Usage: constitution-extract.sh <SECTION_NAME> [CONSTITUTION_PATH]
#
# Extracts everything between <!-- [SECTION_NAME] SECTION --> and the next
# <!-- [...] SECTION --> marker (or end of file / speckit footer).
# Strips the speckit top comment and bottom metadata from the output.
set -euo pipefail

SECTION_NAME="${1:?Usage: constitution-extract.sh <SECTION_NAME> [CONSTITUTION_PATH]}"
CONSTITUTION_PATH="${2:-.specify/memory/constitution.md}"

if [[ ! -f "$CONSTITUTION_PATH" ]]; then
  echo ""
  exit 0
fi

awk -v section="$SECTION_NAME" '
BEGIN { in_section=0; found=0; n=0 }

# Match section start
/^[[:space:]]*<!-- \[/ {
  # Extract name between [ and ] using portable match+substr
  s = $0
  i = index(s, "[")
  j = index(s, "]")
  if (i > 0 && j > i) {
    name = substr(s, i+1, j-i-1)
    if (name == section) {
      in_section=1
      found=1
      next
    } else if (in_section) {
      in_section=0
      exit
    }
  }
}

# Skip speckit footer metadata
in_section && /^\*Version\*:/ { in_section=0; exit }
in_section && /^\*\*Version\*\*:/ { in_section=0; exit }

# Collect content while in section
in_section { lines[n++] = $0 }

END {
  # Trim trailing blank lines so inter-section separators are not included
  last = n - 1
  while (last >= 0 && lines[last] == "") last--
  for (i = 0; i <= last; i++) print lines[i]
}
' "$CONSTITUTION_PATH"
