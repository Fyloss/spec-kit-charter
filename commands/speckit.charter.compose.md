---
description: "Compose and generate the project constitution from selected charter fragments"
scripts:
  sh: ../../scripts/bash/charter-common.sh
---

# Charter Compose

Compose the project constitution from the configured charter fragments and invoke `/speckit.constitution` to generate the final file.

## User Input

$ARGUMENTS

Parse arguments for:
- `update` — Update mode: only refresh fragments from the registry without overriding local modifications. Can optionally be followed by a fragment name to update a single fragment: `update <FRAGMENT_NAME>`
- No arguments — Full compose (creation or recreation mode)

## Prerequisites

1. Charter must be configured — `.specify/extensions/charter/state.yml` must exist (run `/speckit.charter.config` first)
2. Spec Kit must be initialized in the project

## Steps

### Step 1: Validate State

```bash
PROJECT_ROOT="$(pwd)"
STATE_FILE="${PROJECT_ROOT}/.specify/extensions/charter/state.yml"

if [[ ! -f "$STATE_FILE" ]]; then
  echo "❌ ERROR: No charter configuration found."
  echo "Run /speckit.charter.config first to configure the registry and select fragments."
  exit 1
fi

echo "=== STATE ==="
cat "$STATE_FILE"
```

If the state file doesn't exist, display the error and stop.

### Step 2: Create Backup

Before any modification, back up the existing constitution:

```bash
PROJECT_ROOT="$(pwd)"
CONSTITUTION="${PROJECT_ROOT}/.specify/memory/constitution.md"
BACKUP_DIR="${PROJECT_ROOT}/.specify/extensions/charter/backups"

if [[ -f "$CONSTITUTION" ]]; then
  mkdir -p "$BACKUP_DIR"
  TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
  cp "$CONSTITUTION" "${BACKUP_DIR}/constitution-${TIMESTAMP}.md.backup"
  echo "✅ Backup created: ${BACKUP_DIR}/constitution-${TIMESTAMP}.md.backup"
else
  echo "ℹ️  No existing constitution to back up."
fi
```

### Step 3: Detect Current Mode

Read the existing constitution and check for section markers:

```bash
PROJECT_ROOT="$(pwd)"
CONSTITUTION="${PROJECT_ROOT}/.specify/memory/constitution.md"

if [[ -f "$CONSTITUTION" ]]; then
  echo "FILE_EXISTS=true"
  # Check for section markers
  SECTIONS=$(grep -E '^\s*<!-- \[.+\] SECTION -->' "$CONSTITUTION" 2>/dev/null || true)
  if [[ -n "$SECTIONS" ]]; then
    echo "HAS_SECTIONS=true"
    echo "$SECTIONS"
  else
    echo "HAS_SECTIONS=false"
  fi
else
  echo "FILE_EXISTS=false"
  echo "HAS_SECTIONS=false"
fi
```

**Determine the mode:**

- **CREATION MODE**: If no section markers are found (new project or non-charter constitution). Go to **Step 5**.
- **OVERRIDE MODE**: If section markers ARE found (previously composed constitution). Go to **Step 4**.

### Step 4: Override Mode — Detect Local Modifications

In override mode, compare each fragment section in the current constitution against the saved snapshots to detect manual edits.

```bash
PROJECT_ROOT="$(pwd)"
CONSTITUTION="${PROJECT_ROOT}/.specify/memory/constitution.md"
SNAPSHOTS_DIR="${PROJECT_ROOT}/.specify/extensions/charter/snapshots"
STATE_FILE="${PROJECT_ROOT}/.specify/extensions/charter/state.yml"

# Read fragment list from state
FRAGMENTS=$(sed -n '/^fragments:/,/^[^ ]/p' "$STATE_FILE" | grep -E '^\s*-\s' | sed 's/^\s*-\s*//' | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/")
SUB_CONSTS=$(sed -n '/^sub_constitutions:/,/^[^ ]/p' "$STATE_FILE" | grep -E '^\s*-\s' | sed 's/^\s*-\s*//' | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/")

MODIFIED_SECTIONS=""

for frag in $FRAGMENTS; do
  [[ -z "$frag" ]] && continue
  SNAPSHOT="${SNAPSHOTS_DIR}/fragment/${frag}.md"
  if [[ -f "$SNAPSHOT" ]]; then
    # Extract section from constitution
    SECTION_CONTENT=$(awk -v section="$frag" '
    BEGIN { in_section=0 }
    /^[[:space:]]*<!-- \[/ {
      match($0, /\[([^\]]+)\]/, arr)
      if (arr[1] == section) { in_section=1; next }
      else if (in_section) { exit }
    }
    in_section && /^\*\*?Version\*\*?:/ { exit }
    in_section { print }
    ' "$CONSTITUTION" 2>/dev/null || true)

    SNAPSHOT_CONTENT=$(cat "$SNAPSHOT")
    if [[ "$SECTION_CONTENT" != "$SNAPSHOT_CONTENT" ]]; then
      MODIFIED_SECTIONS="${MODIFIED_SECTIONS}${frag}\n"
    fi
  fi
done

for sub in $SUB_CONSTS; do
  [[ -z "$sub" ]] && continue
  SNAPSHOT="${SNAPSHOTS_DIR}/sub-constitution/${sub}.md"
  if [[ -f "$SNAPSHOT" ]]; then
    # Extract section — look for the sub-constitution prefix line too
    SECTION_CONTENT=$(awk -v section="$sub" '
    BEGIN { in_section=0 }
    /^[[:space:]]*<!-- \[/ {
      match($0, /\[([^\]]+)\]/, arr)
      if (arr[1] == section) { in_section=1; next }
      else if (in_section) { exit }
    }
    in_section && /^WHEN WORKING ON / { next }
    in_section && /^\*\*?Version\*\*?:/ { exit }
    in_section { print }
    ' "$CONSTITUTION" 2>/dev/null || true)

    SNAPSHOT_CONTENT=$(cat "$SNAPSHOT")
    if [[ "$SECTION_CONTENT" != "$SNAPSHOT_CONTENT" ]]; then
      MODIFIED_SECTIONS="${MODIFIED_SECTIONS}${sub}\n"
    fi
  fi
done

if [[ -n "$MODIFIED_SECTIONS" ]]; then
  echo "MODIFIED=true"
  echo -e "MODIFIED_SECTIONS:\n${MODIFIED_SECTIONS}"
else
  echo "MODIFIED=false"
fi
```

**If modifications are detected (`MODIFIED=true`):**

Display a warning:

```
⚠️ WARNING: The following sections have been modified since the last composition:
  - <section_name_1>
  - <section_name_2>

Recomposing will OVERWRITE these modifications with the registry versions.

Options:
  - Enter "yes" to proceed and overwrite all modifications
  - Enter "no" to cancel
  - To update only specific fragments, cancel and run:
    /speckit.charter.compose update <FRAGMENT_NAME>
```

- If user answers **"no"**: Stop execution with a cancellation message.
- If user answers **"yes"**: Proceed to Step 5.

**Also in Override Mode — Update local constitution in state:**

Before proceeding, if the constitution contains a `<!-- [PROJECT SPECIFIC] SECTION -->` marker, extract its current content (stripping the section comment) and update the `local_constitution_content` in the state file. This ensures the latest local constitution edits are always preserved.

### Step 5: Resolve Content Sources

Determine whether to use registry versions or snapshot versions for each fragment.

**Parse the arguments to determine sub-mode:**

**If arguments contain `update`:**
- **UPDATE MODE**: Fetch latest versions from the registry and save new snapshots.
- If a specific fragment name follows `update` (e.g., `update global/compliance`), only update THAT fragment — leave all others using their current snapshot versions.

**If no `update` argument AND we're in Override Mode (HAS_SECTIONS=true):**
- **RECREATION MODE**: Use previously saved snapshots. For each fragment in the state, check if a snapshot exists:

```bash
PROJECT_ROOT="$(pwd)"
SNAPSHOTS_DIR="${PROJECT_ROOT}/.specify/extensions/charter/snapshots"
STATE_FILE="${PROJECT_ROOT}/.specify/extensions/charter/state.yml"

MISSING=""
FRAGMENTS=$(sed -n '/^fragments:/,/^[^ ]/p' "$STATE_FILE" | grep -E '^\s*-\s' | sed 's/^\s*-\s*//' | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/")
for frag in $FRAGMENTS; do
  [[ -z "$frag" ]] && continue
  if [[ ! -f "${SNAPSHOTS_DIR}/fragment/${frag}.md" ]]; then
    MISSING="${MISSING}${frag}\n"
  fi
done

SUB_CONSTS=$(sed -n '/^sub_constitutions:/,/^[^ ]/p' "$STATE_FILE" | grep -E '^\s*-\s' | sed 's/^\s*-\s*//' | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/")
for sub in $SUB_CONSTS; do
  [[ -z "$sub" ]] && continue
  if [[ ! -f "${SNAPSHOTS_DIR}/sub-constitution/${sub}.md" ]]; then
    MISSING="${MISSING}${sub}\n"
  fi
done

if [[ -n "$MISSING" ]]; then
  echo "MISSING_SNAPSHOTS=true"
  echo -e "MISSING:\n${MISSING}"
else
  echo "MISSING_SNAPSHOTS=false"
fi
```

If snapshots are missing, warn the user:

```
⚠️ WARNING: Snapshots are missing for the following fragments:
  - <fragment_name>

These will be fetched from the latest registry version.
Proceed? (yes/no)
```

- **no**: Stop execution.
- **yes**: Use registry versions for missing fragments, snapshots for the rest.

**If no `update` argument AND we're in Creation Mode (HAS_SECTIONS=false):**
- **CREATION MODE**: Fetch all fragments from the registry and save snapshots.

### Step 6: Build Constitution Content

For UPDATE MODE with a specific fragment name, read ONLY that fragment from the registry:

```bash
PROJECT_ROOT="$(pwd)"
CHARTER_CONFIG="${PROJECT_ROOT}/.specify/extensions/charter/charter-config.yml"
REGISTRY_VALUE=$(grep "^registry:" "$CHARTER_CONFIG" | sed 's/^registry:[[:space:]]*//' | sed 's/^"\(.*\)"$/\1/')

case "$REGISTRY_VALUE" in
  git@*|https://*.git|http://*.git|https://github.com/*|https://gitlab.com/*|git://*)
    REGISTRY_PATH="${PROJECT_ROOT}/.specify/extensions/charter/.registry-cache"
    # Refresh registry
    git -C "$REGISTRY_PATH" fetch --quiet origin 2>&1 || true
    git -C "$REGISTRY_PATH" reset --quiet --hard origin/HEAD 2>&1 || true
    ;;
  *)
    if [[ "$REGISTRY_VALUE" == /* ]]; then
      REGISTRY_PATH="$REGISTRY_VALUE"
    else
      REGISTRY_PATH="${PROJECT_ROOT}/${REGISTRY_VALUE}"
    fi
    ;;
esac

# Read a specific fragment
FRAG_NAME="<FRAGMENT_NAME>"
# Determine if it's a fragment or sub-constitution from the state file
FRAG_FILE="${REGISTRY_PATH}/fragments/${FRAG_NAME}.md"
SUB_FILE="${REGISTRY_PATH}/sub-constitutions/${FRAG_NAME}.md"

if [[ -f "$FRAG_FILE" ]]; then
  echo "TYPE=fragment"
  cat "$FRAG_FILE"
elif [[ -f "$SUB_FILE" ]]; then
  echo "TYPE=sub-constitution"
  cat "$SUB_FILE"
else
  echo "❌ ERROR: Fragment not found: $FRAG_NAME"
  exit 1
fi
```

For full compose (CREATION or RECREATION MODE), read ALL fragments and build the complete constitution content.

For each fragment and sub-constitution listed in the state file, read the content from:
- **CREATION MODE / UPDATE MODE**: The registry directly
- **RECREATION MODE**: The snapshot directory (with registry fallback for missing snapshots)

### Step 7: Save Snapshots

For CREATION MODE and UPDATE MODE, save snapshots of all fragments being used:

```bash
PROJECT_ROOT="$(pwd)"
SNAPSHOTS_DIR="${PROJECT_ROOT}/.specify/extensions/charter/snapshots"
CHARTER_CONFIG="${PROJECT_ROOT}/.specify/extensions/charter/charter-config.yml"
REGISTRY_VALUE=$(grep "^registry:" "$CHARTER_CONFIG" | sed 's/^registry:[[:space:]]*//' | sed 's/^"\(.*\)"$/\1/')

case "$REGISTRY_VALUE" in
  git@*|https://*.git|http://*.git|https://github.com/*|https://gitlab.com/*|git://*)
    REGISTRY_PATH="${PROJECT_ROOT}/.specify/extensions/charter/.registry-cache"
    ;;
  *)
    if [[ "$REGISTRY_VALUE" == /* ]]; then
      REGISTRY_PATH="$REGISTRY_VALUE"
    else
      REGISTRY_PATH="${PROJECT_ROOT}/${REGISTRY_VALUE}"
    fi
    ;;
esac

# For each fragment: save snapshot
# Example for one fragment:
FRAG_NAME="<FRAGMENT_NAME>"
SNAPSHOT_FILE="${SNAPSHOTS_DIR}/fragment/${FRAG_NAME}.md"
mkdir -p "$(dirname "$SNAPSHOT_FILE")"
cp "${REGISTRY_PATH}/fragments/${FRAG_NAME}.md" "$SNAPSHOT_FILE"

# For each sub-constitution: save snapshot
SUB_NAME="<SUB_CONSTITUTION_NAME>"
SNAPSHOT_FILE="${SNAPSHOTS_DIR}/sub-constitution/${SUB_NAME}.md"
mkdir -p "$(dirname "$SNAPSHOT_FILE")"
cp "${REGISTRY_PATH}/sub-constitutions/${SUB_NAME}.md" "$SNAPSHOT_FILE"
```

### Step 8: Prepare Prompt for /speckit.constitution

Build a complete prompt for `/speckit.constitution` that contains ALL the content to write. The prompt must instruct the constitution command to write the file with the exact content and section markers.

**CRITICAL: The prompt must include section markers as HTML comments.**

The structure of the final constitution.md MUST be:

```
<!-- [<FRAGMENT_NAME_1>] SECTION -->
<CONTENT_OF_FRAGMENT_1>
<!-- [<FRAGMENT_NAME_2>] SECTION -->
<CONTENT_OF_FRAGMENT_2>
<!-- [<SUB_CONSTITUTION_NAME_1>] SECTION -->
WHEN WORKING ON <SUB_CONSTITUTION_NAME_1>, FOLLOW THESE INSTRUCTIONS:
<CONTENT_OF_SUB_CONSTITUTION_1>
<!-- [<SUB_CONSTITUTION_NAME_2>] SECTION -->
WHEN WORKING ON <SUB_CONSTITUTION_NAME_2>, FOLLOW THESE INSTRUCTIONS:
<CONTENT_OF_SUB_CONSTITUTION_2>
<!-- [PROJECT SPECIFIC] SECTION -->
<CONTENT_OF_LOCAL_CONSTITUTION>
```

**Rules for the prompt:**
- Fragment names use the registry path (e.g., `global/compliance`, `languages/typescript/standards`)
- Each section starts with its HTML comment marker on its own line
- Sub-constitutions have the prefix line `WHEN WORKING ON <NAME>, FOLLOW THESE INSTRUCTIONS:` after the section marker
- The local constitution section uses `PROJECT SPECIFIC` as its section name
- The local constitution content is from the state file's `local_constitution_content` field
- Section markers are crucial for subsequent override/update detection
- Do NOT include any placeholder tokens — all content must be concrete
- The order must match: fragments first (in the order from state.yml), then sub-constitutions, then project-specific

Build the prompt as a **string in memory** (do NOT save it to a file). The prompt should be:

```
Write the following content as the project constitution. This is a composed constitution from charter fragments. Preserve the exact section markers (HTML comments) as they are essential for future updates. Do not add, remove, or modify any section markers. Write the content exactly as provided below, maintaining all formatting. The section comments (<!-- [NAME] SECTION -->) MUST be preserved exactly as shown.

<FULL_CONSTITUTION_CONTENT_WITH_SECTION_MARKERS>
```

### Step 9: Execute /speckit.constitution

Execute the `/speckit.constitution` command with the prepared prompt.

**IMPORTANT**: The invocation method depends on the agent/integration:
- In Copilot/Claude: invoke `/speckit.constitution <prompt>`
- The full content must be passed as the argument

After execution, the `/speckit.constitution` command will write the constitution file and add its own Spec Kit metadata (Sync Impact Report comment at top, version/ratified/amended line at bottom). This is expected and correct.

### Step 10: Validate Output

After `/speckit.constitution` completes, validate the generated constitution:

```bash
PROJECT_ROOT="$(pwd)"
CONSTITUTION="${PROJECT_ROOT}/.specify/memory/constitution.md"
STATE_FILE="${PROJECT_ROOT}/.specify/extensions/charter/state.yml"

if [[ ! -f "$CONSTITUTION" ]]; then
  echo "❌ VALIDATION FAILED: constitution.md was not created"
  exit 1
fi

# Check that all expected section markers are present
EXPECTED_SECTIONS=""
FRAGMENTS=$(sed -n '/^fragments:/,/^[^ ]/p' "$STATE_FILE" | grep -E '^\s*-\s' | sed 's/^\s*-\s*//' | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/")
for frag in $FRAGMENTS; do
  [[ -z "$frag" ]] && continue
  EXPECTED_SECTIONS="${EXPECTED_SECTIONS}${frag}\n"
done

SUB_CONSTS=$(sed -n '/^sub_constitutions:/,/^[^ ]/p' "$STATE_FILE" | grep -E '^\s*-\s' | sed 's/^\s*-\s*//' | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/")
for sub in $SUB_CONSTS; do
  [[ -z "$sub" ]] && continue
  EXPECTED_SECTIONS="${EXPECTED_SECTIONS}${sub}\n"
done

HAS_LOCAL=$(grep "^local_constitution:" "$STATE_FILE" | sed 's/^local_constitution:[[:space:]]*//')
if [[ "$HAS_LOCAL" == "true" ]]; then
  EXPECTED_SECTIONS="${EXPECTED_SECTIONS}PROJECT SPECIFIC\n"
fi

MISSING=""
while IFS= read -r section; do
  [[ -z "$section" ]] && continue
  if ! grep -q "<!-- \[${section}\] SECTION -->" "$CONSTITUTION" 2>/dev/null; then
    MISSING="${MISSING}${section}\n"
  fi
done < <(echo -e "$EXPECTED_SECTIONS")

if [[ -n "$MISSING" ]]; then
  echo "⚠️  VALIDATION WARNING: Missing section markers:"
  echo -e "$MISSING"
  echo "The constitution may need manual correction."
else
  echo "✅ VALIDATION PASSED: All section markers present"
fi
```

### Step 11: Display Result

If validation passes:

```
✅ Composed constitution successfully generated and compliant with configuration.
```

If validation has warnings, display them and suggest running the compose command again.

For UPDATE MODE with a single fragment, also confirm:

```
✅ Fragment "<FRAGMENT_NAME>" updated successfully in the constitution.
```

## Notes

- Backups are stored in `.specify/extensions/charter/backups/` with timestamps
- Snapshots are stored in `.specify/extensions/charter/snapshots/` organized by type
- The local constitution content in the state file is updated each time compose runs in override mode
- Section markers (`<!-- [NAME] SECTION -->`) are the backbone of the update mechanism — never remove them manually
- The `/speckit.constitution` command adds its own metadata (Sync Impact Report, version line) — this is expected and should not be confused with charter sections
