#!/usr/bin/env bash
# test_scripts.sh — Automated tests for charter shell scripts
# Usage: bash tests/test_scripts.sh
#
# Exit codes:
#   0 = all tests passed
#   1 = one or more tests failed
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SCRIPTS_DIR="${ROOT_DIR}/scripts/bash"
FIXTURES_DIR="${SCRIPT_DIR}/fixtures"
TMP_DIR="${SCRIPT_DIR}/tmp"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo -e "${GREEN}  ✓ $1${NC}"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo -e "${RED}  ✗ $1${NC}"
  if [[ -n "${2:-}" ]]; then
    echo -e "${RED}    → $2${NC}"
  fi
}

section() {
  echo ""
  echo -e "${YELLOW}━━━ $1 ━━━${NC}"
}

# ── Setup ───────────────────────────────────────────────────────────────────
setup() {
  rm -rf "$TMP_DIR"
  mkdir -p "$TMP_DIR"

  # Create a mock project structure
  mkdir -p "${TMP_DIR}/project/.specify/memory"
  mkdir -p "${TMP_DIR}/project/.specify/extensions/charter"

  # Copy sample registry as .charter
  cp -r "${FIXTURES_DIR}/sample-registry" "${TMP_DIR}/project/.charter"

  # Write a config
  cat > "${TMP_DIR}/project/.specify/extensions/charter/charter-config.yml" <<EOF
registry: ".charter"
registry_type: "directory"
EOF
}

teardown() {
  rm -rf "$TMP_DIR"
}

# ── Tests ───────────────────────────────────────────────────────────────────

section "charter-common.sh"

test_is_git_url() {
  source "${SCRIPTS_DIR}/charter-common.sh"

  if is_git_url "git@github.com:org/repo.git"; then
    pass "is_git_url: SSH URL"
  else
    fail "is_git_url: SSH URL"
  fi

  if is_git_url "https://github.com/org/repo"; then
    pass "is_git_url: HTTPS GitHub URL"
  else
    fail "is_git_url: HTTPS GitHub URL"
  fi

  if ! is_git_url "/local/path"; then
    pass "is_git_url: local path returns false"
  else
    fail "is_git_url: local path returns false"
  fi

  if ! is_git_url ".charter"; then
    pass "is_git_url: relative path returns false"
  else
    fail "is_git_url: relative path returns false"
  fi
}

test_yaml_field() {
  source "${SCRIPTS_DIR}/charter-common.sh"
  local manifest="${FIXTURES_DIR}/sample-registry/manifest.yml"

  local version
  version="$(yaml_field "$manifest" "version")"
  if [[ "$version" == "1" ]]; then
    pass "yaml_field: reads version"
  else
    fail "yaml_field: reads version" "got: $version"
  fi

  local name
  name="$(yaml_field "$manifest" "name")"
  if [[ "$name" == "Test Company Charter Registry" ]]; then
    pass "yaml_field: reads name"
  else
    fail "yaml_field: reads name" "got: $name"
  fi
}

test_yaml_list() {
  source "${SCRIPTS_DIR}/charter-common.sh"
  local manifest="${FIXTURES_DIR}/sample-registry/manifest.yml"

  local mandatory
  mandatory="$(yaml_list "$manifest" "mandatory_fragments")"
  if echo "$mandatory" | grep -q "global/compliance"; then
    pass "yaml_list: reads mandatory_fragments"
  else
    fail "yaml_list: reads mandatory_fragments" "got: $mandatory"
  fi

  local recommended
  recommended="$(yaml_list "$manifest" "recommended_fragments")"
  if echo "$recommended" | grep -q "global/code-quality"; then
    pass "yaml_list: reads recommended_fragments"
  else
    fail "yaml_list: reads recommended_fragments" "got: $recommended"
  fi
}

test_is_git_url
test_yaml_field
test_yaml_list

# ── Registry Validation ────────────────────────────────────────────────────

section "registry-validate.sh"

test_registry_validate_valid() {
  setup
  local output
  output="$(PROJECT_ROOT="${TMP_DIR}/project" bash "${SCRIPTS_DIR}/registry-validate.sh" "${TMP_DIR}/project" 2>&1)" || true
  if echo "$output" | grep -q "VALID"; then
    pass "registry-validate: valid registry"
  else
    fail "registry-validate: valid registry" "output: $output"
  fi
}

test_registry_validate_missing_manifest() {
  setup
  rm "${TMP_DIR}/project/.charter/manifest.yml"
  local output
  output="$(PROJECT_ROOT="${TMP_DIR}/project" bash "${SCRIPTS_DIR}/registry-validate.sh" "${TMP_DIR}/project" 2>&1)" || true
  if echo "$output" | grep -q "missing required manifest.yml"; then
    pass "registry-validate: detects missing manifest"
  else
    fail "registry-validate: detects missing manifest" "output: $output"
  fi
}

test_registry_validate_valid
test_registry_validate_missing_manifest

# ── Fragment Listing ────────────────────────────────────────────────────────

section "fragment-list.sh"

test_fragment_list() {
  setup
  local output
  output="$(PROJECT_ROOT="${TMP_DIR}/project" bash "${SCRIPTS_DIR}/fragment-list.sh" "${TMP_DIR}/project" 2>&1)" || true

  if echo "$output" | grep -q "mandatory_fragment.*global/compliance"; then
    pass "fragment-list: identifies mandatory fragment"
  else
    fail "fragment-list: identifies mandatory fragment" "output: $output"
  fi

  if echo "$output" | grep -q "recommended_fragment.*global/code-quality"; then
    pass "fragment-list: identifies recommended fragment"
  else
    fail "fragment-list: identifies recommended fragment" "output: $output"
  fi

  if echo "$output" | grep -q "fragment.*languages/typescript/standards"; then
    pass "fragment-list: lists regular fragment"
  else
    fail "fragment-list: lists regular fragment" "output: $output"
  fi

  if echo "$output" | grep -q "sub-constitution.*package-auth"; then
    pass "fragment-list: lists sub-constitution"
  else
    fail "fragment-list: lists sub-constitution" "output: $output"
  fi
}

test_fragment_list

# ── Constitution Parsing ───────────────────────────────────────────────────

section "constitution-parse.sh"

test_parse_no_sections() {
  local output
  output="$(bash "${SCRIPTS_DIR}/constitution-parse.sh" "${FIXTURES_DIR}/sample-constitution.md" 2>&1)"
  if echo "$output" | grep -q "HAS_SECTIONS=false"; then
    pass "constitution-parse: no sections in plain constitution"
  else
    fail "constitution-parse: no sections in plain constitution" "output: $output"
  fi
}

test_parse_with_sections() {
  local output
  output="$(bash "${SCRIPTS_DIR}/constitution-parse.sh" "${FIXTURES_DIR}/sample-composed-constitution.md" 2>&1)"
  if echo "$output" | grep -q "HAS_SECTIONS=true"; then
    pass "constitution-parse: detects sections in composed constitution"
  else
    fail "constitution-parse: detects sections in composed constitution" "output: $output"
  fi

  if echo "$output" | grep -q "SECTION=global/compliance"; then
    pass "constitution-parse: finds global/compliance section"
  else
    fail "constitution-parse: finds global/compliance section" "output: $output"
  fi

  if echo "$output" | grep -q "SECTION=PROJECT SPECIFIC"; then
    pass "constitution-parse: finds PROJECT SPECIFIC section"
  else
    fail "constitution-parse: finds PROJECT SPECIFIC section" "output: $output"
  fi
}

test_parse_nonexistent() {
  local output
  output="$(bash "${SCRIPTS_DIR}/constitution-parse.sh" "/nonexistent/path.md" 2>&1)"
  if echo "$output" | grep -q "FILE_EXISTS=false"; then
    pass "constitution-parse: handles nonexistent file"
  else
    fail "constitution-parse: handles nonexistent file" "output: $output"
  fi
}

test_parse_no_sections
test_parse_with_sections
test_parse_nonexistent

# ── Constitution Extract ───────────────────────────────────────────────────

section "constitution-extract.sh"

test_extract_section() {
  local output
  output="$(bash "${SCRIPTS_DIR}/constitution-extract.sh" "global/compliance" "${FIXTURES_DIR}/sample-composed-constitution.md" 2>&1)"
  if echo "$output" | grep -q "Compliance Standards"; then
    pass "constitution-extract: extracts section content"
  else
    fail "constitution-extract: extracts section content" "output: $output"
  fi
}

test_extract_project_specific() {
  local output
  output="$(bash "${SCRIPTS_DIR}/constitution-extract.sh" "PROJECT SPECIFIC" "${FIXTURES_DIR}/sample-composed-constitution.md" 2>&1)"
  if echo "$output" | grep -q "My Project"; then
    pass "constitution-extract: extracts PROJECT SPECIFIC section"
  else
    fail "constitution-extract: extracts PROJECT SPECIFIC section" "output: $output"
  fi
}

test_extract_section
test_extract_project_specific

# ── Constitution Strip Local ───────────────────────────────────────────────

section "constitution-strip-local.sh"

test_strip_local() {
  local output
  output="$(bash "${SCRIPTS_DIR}/constitution-strip-local.sh" "${FIXTURES_DIR}/sample-constitution.md" 2>&1)"

  if echo "$output" | grep -q "Sync Impact Report"; then
    fail "constitution-strip-local: should strip top comment"
  else
    pass "constitution-strip-local: strips top comment"
  fi

  if echo "$output" | grep -q "Core Principles"; then
    pass "constitution-strip-local: preserves body content"
  else
    fail "constitution-strip-local: preserves body content" "output: $output"
  fi
}

test_strip_local

# ── Config Write ───────────────────────────────────────────────────────────

section "config-write.sh"

test_config_write_directory() {
  setup
  local output
  output="$(bash "${SCRIPTS_DIR}/config-write.sh" ".charter" "${TMP_DIR}/project" 2>&1)"
  if echo "$output" | grep -q "registry_type=directory"; then
    pass "config-write: detects directory type"
  else
    fail "config-write: detects directory type" "output: $output"
  fi

  if [[ -f "${TMP_DIR}/project/.specify/extensions/charter/charter-config.yml" ]]; then
    pass "config-write: creates config file"
  else
    fail "config-write: creates config file"
  fi
}

test_config_write_git() {
  setup
  local output
  output="$(bash "${SCRIPTS_DIR}/config-write.sh" "git@github.com:org/charter.git" "${TMP_DIR}/project" 2>&1)"
  if echo "$output" | grep -q "registry_type=git"; then
    pass "config-write: detects git type"
  else
    fail "config-write: detects git type" "output: $output"
  fi
}

test_config_write_directory
test_config_write_git

# ── Fragment Read ──────────────────────────────────────────────────────────

section "fragment-read.sh"

test_fragment_read() {
  setup
  local output
  output="$(bash "${SCRIPTS_DIR}/fragment-read.sh" "global/compliance" "fragment" "${TMP_DIR}/project" 2>&1)"
  if echo "$output" | grep -q "Compliance Standards"; then
    pass "fragment-read: reads fragment content"
  else
    fail "fragment-read: reads fragment content" "output: $output"
  fi
}

test_fragment_read_sub() {
  setup
  local output
  output="$(bash "${SCRIPTS_DIR}/fragment-read.sh" "package-auth" "sub-constitution" "${TMP_DIR}/project" 2>&1)"
  if echo "$output" | grep -q "authentication"; then
    pass "fragment-read: reads sub-constitution content"
  else
    fail "fragment-read: reads sub-constitution content" "output: $output"
  fi
}

test_fragment_read
test_fragment_read_sub

# ── State Management ──────────────────────────────────────────────────────

section "state-write.sh / state-read.sh"

test_state_write_read() {
  setup
  echo 'fragments:
  - "global/compliance"
  - "global/code-quality"
local_constitution: false' | bash "${SCRIPTS_DIR}/state-write.sh" "${TMP_DIR}/project" 2>&1

  local output
  output="$(bash "${SCRIPTS_DIR}/state-read.sh" "${TMP_DIR}/project" 2>&1)"
  if echo "$output" | grep -q "global/compliance"; then
    pass "state-write/read: writes and reads state"
  else
    fail "state-write/read: writes and reads state" "output: $output"
  fi
}

test_state_write_read

# ── Snapshot Management ───────────────────────────────────────────────────

section "snapshot-save.sh / snapshot-read.sh / snapshot-remove.sh"

test_snapshot_save_read() {
  setup
  local output
  bash "${SCRIPTS_DIR}/snapshot-save.sh" "global/compliance" "fragment" "${TMP_DIR}/project" 2>&1

  output="$(bash "${SCRIPTS_DIR}/snapshot-read.sh" "global/compliance" "fragment" "${TMP_DIR}/project" 2>&1)"
  if echo "$output" | grep -q "Compliance Standards"; then
    pass "snapshot-save/read: saves and reads snapshot"
  else
    fail "snapshot-save/read: saves and reads snapshot" "output: $output"
  fi
}

test_snapshot_remove() {
  setup
  bash "${SCRIPTS_DIR}/snapshot-save.sh" "global/compliance" "fragment" "${TMP_DIR}/project" 2>&1
  bash "${SCRIPTS_DIR}/snapshot-remove.sh" "global/compliance" "fragment" "${TMP_DIR}/project" 2>&1

  local exit_code=0
  bash "${SCRIPTS_DIR}/snapshot-read.sh" "global/compliance" "fragment" "${TMP_DIR}/project" 2>&1 || exit_code=$?
  if [[ "$exit_code" -eq 2 ]]; then
    pass "snapshot-remove: removes snapshot"
  else
    fail "snapshot-remove: removes snapshot" "exit code: $exit_code"
  fi
}

test_snapshot_save_read
test_snapshot_remove

# ── Backup ────────────────────────────────────────────────────────────────

section "constitution-backup.sh"

test_backup() {
  setup
  cp "${FIXTURES_DIR}/sample-constitution.md" "${TMP_DIR}/project/.specify/memory/constitution.md"

  local output
  output="$(bash "${SCRIPTS_DIR}/constitution-backup.sh" "${TMP_DIR}/project" 2>&1)"
  if echo "$output" | grep -q ".md.backup"; then
    pass "constitution-backup: creates backup"
  else
    fail "constitution-backup: creates backup" "output: $output"
  fi

  local backup_count
  backup_count=$(find "${TMP_DIR}/project/.specify/extensions/charter/backups" -name "*.backup" 2>/dev/null | wc -l)
  if [[ "$backup_count" -ge 1 ]]; then
    pass "constitution-backup: backup file exists"
  else
    fail "constitution-backup: backup file exists" "count: $backup_count"
  fi
}

test_backup

# ── Summary ───────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${GREEN}Passed: ${PASS_COUNT}${NC}  ${RED}Failed: ${FAIL_COUNT}${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

teardown

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 1
fi
