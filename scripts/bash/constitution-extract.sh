#!/usr/bin/env bash
# constitution-extract.sh — Extract content of a specific section from constitution.md
# Usage: constitution-extract.sh <SECTION_ID> [CONSTITUTION_PATH]
#
# Extracts everything between the section marker and the next marker (or end of
# file / speckit footer). Strips the speckit top comment and bottom metadata.
#
# Supports typed markers (<!-- [TYPE] ID SECTION -->) and legacy markers
# (<!-- [ID] SECTION -->). The SECTION_ID argument is always just the plain ID
# (e.g., "global/compliance", "PROJECT SPECIFIC") — callers do not include the
# type tag.
set -euo pipefail

SECTION_NAME="${1:?Usage: constitution-extract.sh <SECTION_ID> [CONSTITUTION_PATH]}"
CONSTITUTION_PATH="${2:-.specify/memory/constitution.md}"

if [[ ! -f "$CONSTITUTION_PATH" ]]; then
  echo ""
  exit 0
fi

awk -v section="$SECTION_NAME" '
BEGIN { in_section=0; found=0; n=0 }

# Match any section marker (typed or legacy) and extract the ID.
# Typed:  <!-- [TYPE] ID SECTION -->
# Legacy: <!-- [ID] SECTION -->
/^[[:space:]]*<!-- \[/ {
  s = $0
  name = ""

  # Try typed marker: contains "] " (closing bracket followed by space then ID)
  close_bracket = index(s, "] ")
  if (close_bracket > 0) {
    # Verify it looks like a typed marker: bracket content is A-Z only
    open_bracket = index(s, "[")
    if (open_bracket > 0 && open_bracket < close_bracket) {
      tag = substr(s, open_bracket + 1, close_bracket - open_bracket - 1)
      # Tag is uppercase letters only → typed marker
      if (tag ~ /^[A-Z]+$/) {
        rest = substr(s, close_bracket + 2)
        section_end = index(rest, " SECTION -->")
        if (section_end > 0) {
          name = substr(rest, 1, section_end - 1)
        }
      }
    }
  }

  # Fall back to legacy marker: <!-- [ID] SECTION -->
  if (name == "") {
    open_bracket = index(s, "[")
    close_bracket = index(s, "]")
    if (open_bracket > 0 && close_bracket > open_bracket) {
      name = substr(s, open_bracket + 1, close_bracket - open_bracket - 1)
    }
  }

  if (name != "") {
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
