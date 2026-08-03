#!/usr/bin/env bash
# heading-normalize.sh — Normalize Markdown heading levels in a fragment
# Usage: heading-normalize.sh [TARGET_LEVEL]
#
# Reads Markdown content from stdin, shifts all heading lines so that the
# top-level (minimum) heading becomes TARGET_LEVEL (default: 2 = "##").
#
# Rules:
#   - Only lines outside fenced code blocks (``` or ~~~) are considered headings.
#   - A heading line must start with one or more '#' followed by a space.
#   - Lines inside fenced code blocks (including lines that start with '#') are
#     passed through unchanged — this covers shell/Python/YAML comments,
#     shebangs, and any other '#'-prefixed syntax inside code samples.
#   - If the content contains no heading lines, it is passed through unchanged.
#   - The output is printed to stdout.
#
# Examples:
#   Fragment with H1 top heading → shifted to H2:
#     echo -e "# Title\ntext" | heading-normalize.sh       → "## Title\ntext"
#
#   Fragment with H4 top heading → shifted to H2:
#     echo -e "#### Title\ntext" | heading-normalize.sh    → "## Title\ntext"
#
#   Code blocks are not modified:
#     Fragment with "```\n# comment\n```" passes the comment through verbatim.
set -euo pipefail

TARGET_LEVEL="${1:-2}"

awk -v target="$TARGET_LEVEL" '
BEGIN {
  fence = 0
  min_level = 0
  n = 0
}

# Toggle fence state on ``` or ~~~ at the start of a line.
/^[[:space:]]*(```|~~~)/ { fence = !fence }

# Collect all lines into an array.
{ lines[n++] = $0 }

# Track minimum heading level (only outside fenced blocks).
!fence && /^#+ / {
  # Count leading # characters
  i = 1
  while (substr($0, i, 1) == "#") i++
  level = i - 1
  if (min_level == 0 || level < min_level) min_level = level
}

END {
  # No headings found: output verbatim
  if (min_level == 0) {
    for (i = 0; i < n; i++) print lines[i]
    exit 0
  }

  delta = target - min_level
  fence = 0

  for (i = 0; i < n; i++) {
    line = lines[i]

    # Toggle fence state
    if (line ~ /^[[:space:]]*(```|~~~)/) fence = !fence

    # Apply delta to heading lines outside fenced blocks
    if (!fence && line ~ /^#+ /) {
      # Count leading # characters
      j = 1
      while (substr(line, j, 1) == "#") j++
      current_level = j - 1
      new_level = current_level + delta
      if (new_level < 1) new_level = 1

      # Build new heading prefix
      prefix = ""
      for (k = 0; k < new_level; k++) prefix = prefix "#"
      # Replace leading #s with new prefix (rest of line starts at j)
      line = prefix substr(line, j)
    }

    print line
  }
}
'
