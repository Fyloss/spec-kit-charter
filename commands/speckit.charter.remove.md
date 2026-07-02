---
description: "Remove a fragment or sub-constitution section from the composed constitution"
scripts:
  sh: ../../scripts/bash/charter-common.sh
---

# Charter Remove

Remove a named fragment or sub-constitution from the charter composition and regenerate the constitution.

## User Input

$ARGUMENTS

The argument MUST be the name of a fragment or sub-constitution to remove (e.g., `global/compliance`, `package-auth`).

## Prerequisites

1. Charter must be configured — `.specify/charter/state.yml` must exist
2. The named fragment/sub-constitution must exist in the current configuration

## Steps

### Step 1: Parse and Validate Arguments

The argument is the name of the fragment or sub-constitution to remove.

```bash
PROJECT_ROOT="$(pwd)"
STATE_FILE="${PROJECT_ROOT}/.specify/charter/state.yml"

if [[ ! -f "$STATE_FILE" ]]; then
  echo "❌ ERROR: No charter configuration found."
  echo "Run /speckit.charter.config first."
  exit 1
fi

echo "=== CURRENT STATE ==="
cat "$STATE_FILE"
```

Identify the target section name from the arguments. Verify it exists in either the `fragments` or `sub_constitutions` list in the state file.

If the section is not found in the state, display:

```
❌ ERROR: "<SECTION_NAME>" is not in the current composition.
Available sections:
  Fragments: <list>
  Sub-constitutions: <list>
```

### Step 2: Check for Mandatory Fragments

Before removing, verify the fragment is not mandatory:

```bash
PROJECT_ROOT="$(pwd)"
CHARTER_CONFIG="${PROJECT_ROOT}/.specify/charter/config.yml"
REGISTRY_VALUE=$(grep "^registry:" "$CHARTER_CONFIG" | sed 's/^registry:[[:space:]]*//' | sed 's/^"\(.*\)"$/\1/')

case "$REGISTRY_VALUE" in
  git@*|https://*.git|http://*.git|https://github.com/*|https://gitlab.com/*|git://*)
    REGISTRY_PATH="${PROJECT_ROOT}/.specify/charter/.cache/registry"
    ;;
  *)
    if [[ "$REGISTRY_VALUE" == /* ]]; then
      REGISTRY_PATH="$REGISTRY_VALUE"
    else
      REGISTRY_PATH="${PROJECT_ROOT}/${REGISTRY_VALUE}"
    fi
    ;;
esac

MANIFEST="${REGISTRY_PATH}/manifest.yml"
if [[ -f "$MANIFEST" ]]; then
  echo "=== MANDATORY FRAGMENTS ==="
  sed -n '/^mandatory_fragments:/,/^[^ ]/p' "$MANIFEST" | grep -E '^\s*-\s' | sed 's/^\s*-\s*//' | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/"
fi
```

If the fragment is mandatory, display:

```
❌ ERROR: "<FRAGMENT_NAME>" is a mandatory fragment and cannot be removed.
Mandatory fragments are defined in the registry manifest and must be included in all compositions.
```

Stop execution.

### Step 3: Update State File

Remove the fragment/sub-constitution from the state file:

1. Read the current state
2. Remove the target from the `fragments` or `sub_constitutions` list
3. Write the updated state back

Write the updated YAML to `.specify/charter/state.yml`.

### Step 4: Remove Snapshot

```bash
PROJECT_ROOT="$(pwd)"
SNAPSHOTS_DIR="${PROJECT_ROOT}/.specify/charter/snapshots"
TARGET_NAME="<SECTION_NAME>"

# Try fragment snapshot
SNAP="${SNAPSHOTS_DIR}/fragment/${TARGET_NAME}.md"
if [[ -f "$SNAP" ]]; then
  rm "$SNAP"
  echo "Snapshot removed: $SNAP"
fi

# Try sub-constitution snapshot
SNAP="${SNAPSHOTS_DIR}/sub-constitution/${TARGET_NAME}.md"
if [[ -f "$SNAP" ]]; then
  rm "$SNAP"
  echo "Snapshot removed: $SNAP"
fi
```

### Step 5: Recompose Constitution

After removing the section from the state, invoke `/speckit.charter.compose` to regenerate the constitution without the removed section.

This ensures the constitution file is updated consistently using the same composition pipeline.

### Step 6: Display Result

```
✅ Fragment "<SECTION_NAME>" removed from the composition.
   The constitution has been regenerated.
```

## Notes

- Removing a fragment updates both the state file and the actual constitution
- The mandatory fragment check uses the registry manifest — mandatory fragments cannot be removed
- The `<CURRENT PROJECT CONSTITUTION>` (local constitution) cannot be removed via this command — to remove it, re-run `/speckit.charter.config` and deselect it
- A backup of the previous constitution is created automatically during recomposition
