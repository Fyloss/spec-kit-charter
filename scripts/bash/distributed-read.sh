#!/usr/bin/env bash
# distributed-read.sh — Read a distributed sub-constitution's content
# Usage: distributed-read.sh <PACKAGE_PATH> [PROJECT_ROOT]
#
# PACKAGE_PATH is the package directory relative to the project root
# (e.g. "packages/back"). Reads "<PACKAGE_PATH>/.charter/constitution.md".
#
# Distributed sub-constitutions are cacheless: this always reads the current
# on-disk file so package owners can update their rules and have them picked up
# on the next compose without any snapshot/update step.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_PATH="${1:?Usage: distributed-read.sh <PACKAGE_PATH> [PROJECT_ROOT]}"
PROJECT_ROOT="${2:-.}"
source "${SCRIPT_DIR}/charter-common.sh"

FILE="${PROJECT_ROOT}/${PACKAGE_PATH}/.charter/constitution.md"

if [[ ! -f "$FILE" ]]; then
  die "Distributed sub-constitution not found: $FILE"
fi

cat "$FILE"
