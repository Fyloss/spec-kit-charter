#!/usr/bin/env bash
# constitution-strip-local.sh — Extract local constitution content, stripping speckit metadata
# Usage: constitution-strip-local.sh [CONSTITUTION_PATH]
#
# Reads the entire constitution.md and strips:
#   - Top HTML comment block (Sync Impact Report)
#   - Bottom metadata line (Version/Ratified/Last Amended)
# Outputs the clean content.
set -euo pipefail

CONSTITUTION_PATH="${1:-.specify/memory/constitution.md}"

if [[ ! -f "$CONSTITUTION_PATH" ]]; then
  echo ""
  exit 0
fi

awk '
BEGIN { skip_top=0; buffer="" }

# Skip top HTML comment (Sync Impact Report)
NR==1 && /^<!--/ { skip_top=1; next }
skip_top && /-->/ { skip_top=0; next }
skip_top { next }

# Collect all lines, we will trim the footer at the end
{ lines[NR] = $0; last_nr = NR }

END {
  # Find the last non-empty line
  end_line = last_nr
  
  # Check if last meaningful lines are speckit footer
  for (i = last_nr; i >= 1; i--) {
    if (lines[i] ~ /^\*\*?Version\*\*?:.*\|.*Ratified/) {
      end_line = i - 1
      break
    }
    if (lines[i] ~ /^<!--/) {
      # Check if this is a Sync Impact Report at the bottom
      if (lines[i+1] ~ /Sync Impact Report/) {
        end_line = i - 1
        break
      }
    }
    # Stop searching after 5 non-empty lines from the bottom
    if (lines[i] != "" && last_nr - i > 5) break
  }
  
  # Trim trailing empty lines
  while (end_line > 0 && lines[end_line] == "") end_line--
  
  # Output
  for (i = 1; i <= end_line; i++) {
    if (i in lines) print lines[i]
  }
}
' "$CONSTITUTION_PATH"
