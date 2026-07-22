#!/usr/bin/env bash
# distributed-detect.sh — Detect distributed sub-constitutions in monorepo packages
# Usage: distributed-detect.sh [PROJECT_ROOT]
#
# Recursively searches (up to 5 package-directory levels deep) for
# "<package>/.charter/constitution.md" files and prints each package path — the
# directory that CONTAINS the .charter folder — relative to PROJECT_ROOT, one
# per line, sorted and de-duplicated.
#
# Only files inside a ".charter" folder are considered. This is deliberate: it
# avoids picking up a package's own Spec Kit constitution (e.g.
# "packages/x/.specify/memory/constitution.md" or a bare
# "packages/x/constitution.md"), which is a different, unrelated file.
#
# The root registry directory (a package path of ".") is skipped, and the
# .specify, .git and node_modules directories are never traversed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-.}"
source "${SCRIPT_DIR}/charter-common.sh"

ROOT_ABS="$(cd "$PROJECT_ROOT" && pwd)"

# -maxdepth 7 = up to 5 package-directory levels + ".charter" + "constitution.md".
find "$ROOT_ABS" -maxdepth 7 \
  \( -name .git -o -name node_modules -o -name .specify \) -prune -o \
  -type f -path '*/.charter/constitution.md' -print 2>/dev/null |
while IFS= read -r file; do
  charter_dir="$(dirname "$file")"   # <pkg>/.charter
  pkg_dir="$(dirname "$charter_dir")" # <pkg>
  # Skip the project root itself (root registry, not a package).
  [[ "$pkg_dir" == "$ROOT_ABS" ]] && continue
  rel="${pkg_dir#"$ROOT_ABS"/}"
  echo "$rel"
done | sort -u
