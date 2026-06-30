#!/usr/bin/env bash
# charter-common.sh — Shared utilities for the Charter extension
# All scripts source this file for common paths and helpers.
set -euo pipefail

# ── Paths ───────────────────────────────────────────────────────────────────
# PROJECT_ROOT must be set by the caller (defaults to current directory)
PROJECT_ROOT="${PROJECT_ROOT:-.}"

CHARTER_EXT_DIR="${PROJECT_ROOT}/.specify/extensions/charter"
CHARTER_CONFIG="${CHARTER_EXT_DIR}/charter-config.yml"
CHARTER_STATE="${CHARTER_EXT_DIR}/state.yml"
CHARTER_SNAPSHOTS_DIR="${CHARTER_EXT_DIR}/snapshots"
CHARTER_BACKUPS_DIR="${CHARTER_EXT_DIR}/backups"
CONSTITUTION_PATH="${PROJECT_ROOT}/.specify/memory/constitution.md"

# ── Helpers ─────────────────────────────────────────────────────────────────

# Print an error message to stderr and exit
die() {
  echo "❌ ERROR: $*" >&2
  exit 1
}

# Print a warning message to stderr
warn() {
  echo "⚠️  WARNING: $*" >&2
}

# Print an info message
info() {
  echo "ℹ️  $*"
}

# Ensure a directory exists
ensure_dir() {
  mkdir -p "$1"
}

# Check if a value looks like a git URL
is_git_url() {
  local val="$1"
  case "$val" in
    git@*|https://*.git|http://*.git|https://github.com/*|https://gitlab.com/*|git://*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Read a YAML field using grep/sed (no yq dependency for portability)
# Usage: yaml_field "file.yml" "field_name"
yaml_field() {
  local file="$1" field="$2"
  grep -E "^${field}:" "$file" 2>/dev/null | head -1 | sed "s/^${field}:[[:space:]]*//" | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/"
}

# Read a YAML list field — returns one item per line (simple flat lists only)
# Usage: yaml_list "file.yml" "field_name"
yaml_list() {
  local file="$1" field="$2"
  sed -n "/^${field}:/,/^[^ ]/p" "$file" | grep -E '^\s*-\s' | sed 's/^\s*-\s*//' | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/"
}

# Get the registry path from config
get_registry() {
  if [[ -f "$CHARTER_CONFIG" ]]; then
    yaml_field "$CHARTER_CONFIG" "registry"
  else
    echo ".charter"
  fi
}

# Get the registry type from config (or auto-detect)
get_registry_type() {
  local registry
  registry="$(get_registry)"
  if is_git_url "$registry"; then
    echo "git"
  else
    echo "directory"
  fi
}

# Resolve registry to a local path (clone if git, return path if directory)
# Sets REGISTRY_LOCAL_PATH on success
resolve_registry_path() {
  local registry registry_type
  registry="$(get_registry)"
  registry_type="$(get_registry_type)"

  if [[ "$registry_type" == "git" ]]; then
    REGISTRY_LOCAL_PATH="${CHARTER_EXT_DIR}/.registry-cache"
    # Clone or update
    if [[ -d "${REGISTRY_LOCAL_PATH}/.git" ]]; then
      git -C "$REGISTRY_LOCAL_PATH" fetch --quiet origin 2>/dev/null || die "Failed to fetch registry: $registry"
      git -C "$REGISTRY_LOCAL_PATH" reset --quiet --hard origin/HEAD 2>/dev/null || true
    else
      rm -rf "$REGISTRY_LOCAL_PATH"
      git clone --quiet --depth 1 "$registry" "$REGISTRY_LOCAL_PATH" 2>/dev/null || die "Failed to clone registry: $registry"
    fi
  else
    # Resolve relative paths against project root
    if [[ "$registry" == /* ]]; then
      REGISTRY_LOCAL_PATH="$registry"
    else
      REGISTRY_LOCAL_PATH="${PROJECT_ROOT}/${registry}"
    fi
  fi
}
