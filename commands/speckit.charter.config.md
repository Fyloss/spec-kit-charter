---
description: "Configure the charter registry and select constitution fragments for composition"
scripts:
  sh: ../../scripts/bash/charter-common.sh
---

# Charter Configuration

Configure the charter fragment registry and select which fragments to include in the project constitution.

## User Input

$ARGUMENTS

## Prerequisites

1. Spec Kit must be initialized in the project (`specify init` has been run)
2. A charter registry must be accessible (local directory or git repository)

## Steps

### Step 1: Determine Registry

The registry is the source of constitution fragments. It can be a local directory or a git repository.

1. Check if a charter configuration already exists by running:

```bash
PROJECT_ROOT="$(pwd)"
CHARTER_CONFIG="${PROJECT_ROOT}/.specify/charter/config.yml"
if [[ -f "$CHARTER_CONFIG" ]]; then
  echo "EXISTING_CONFIG=true"
  grep "^registry:" "$CHARTER_CONFIG" | head -1
else
  echo "EXISTING_CONFIG=false"
  echo "registry: .charter"
fi
```

2. Present the current registry setting to the user:

   - If a config already exists, show: `Current registry: <value>. Confirm or enter a new value.`
   - If no config exists, show: `Default registry: .charter (relative to project root). Confirm or enter a new value.`

3. The user can:
   - **Confirm** the current/default value (press Enter, say "yes", "ok", "confirm", etc.)
   - **Provide a new value**: a relative path, absolute path, or git URL (SSH or HTTPS)

4. Once the registry value is determined, write the configuration:

```bash
bash .specify/extensions/charter/scripts/bash/config-write.sh "<REGISTRY_VALUE>" "$(pwd)"
```

Note: If the script path above does not exist (extension installed differently), use the script content from `scripts/bash/config-write.sh` in the extension source.

### Step 2: Validate Registry

Fetch and validate the registry to ensure it has the correct structure.

```bash
PROJECT_ROOT="$(pwd)"
export PROJECT_ROOT
source .specify/extensions/charter/scripts/bash/charter-common.sh 2>/dev/null || true

# Resolve registry path
CHARTER_CONFIG="${PROJECT_ROOT}/.specify/charter/config.yml"
REGISTRY_VALUE=$(grep "^registry:" "$CHARTER_CONFIG" | sed 's/^registry:[[:space:]]*//' | sed 's/^"\(.*\)"$/\1/')

# Check if git URL
case "$REGISTRY_VALUE" in
  git@*|https://*.git|http://*.git|https://github.com/*|https://gitlab.com/*|git://*)
    REGISTRY_TYPE="git"
    CACHE_DIR="${PROJECT_ROOT}/.specify/charter/.cache/registry"
    if [[ -d "${CACHE_DIR}/.git" ]]; then
      git -C "$CACHE_DIR" fetch --quiet origin 2>&1
      git -C "$CACHE_DIR" reset --quiet --hard origin/HEAD 2>&1
    else
      rm -rf "$CACHE_DIR"
      git clone --quiet --depth 1 "$REGISTRY_VALUE" "$CACHE_DIR" 2>&1
    fi
    REGISTRY_PATH="$CACHE_DIR"
    ;;
  *)
    REGISTRY_TYPE="directory"
    if [[ "$REGISTRY_VALUE" == /* ]]; then
      REGISTRY_PATH="$REGISTRY_VALUE"
    else
      REGISTRY_PATH="${PROJECT_ROOT}/${REGISTRY_VALUE}"
    fi
    ;;
esac

# Validate
if [[ ! -d "$REGISTRY_PATH" ]]; then
  echo "❌ ERROR: Registry path does not exist: $REGISTRY_PATH"
  exit 1
fi

if [[ ! -f "${REGISTRY_PATH}/manifest.yml" ]]; then
  echo "❌ ERROR: Registry is missing required manifest.yml at: $REGISTRY_PATH"
  exit 1
fi

echo "✅ Registry validated successfully"
echo "Registry type: $REGISTRY_TYPE"
echo "Registry path: $REGISTRY_PATH"
```

**If validation fails**: Display the error message to the user and invite them to re-run `/speckit.charter.config` with a valid registry. **Stop execution here.**

**If validation succeeds**: Proceed to Step 3.

### Step 3: List Available Fragments

Read the manifest and enumerate all available fragments, sub-constitutions, and detect any existing local constitution.

```bash
PROJECT_ROOT="$(pwd)"
CHARTER_CONFIG="${PROJECT_ROOT}/.specify/charter/config.yml"
REGISTRY_VALUE=$(grep "^registry:" "$CHARTER_CONFIG" | sed 's/^registry:[[:space:]]*//' | sed 's/^"\(.*\)"$/\1/')

# Resolve registry path (same logic as Step 2)
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
FRAGMENTS_DIR="${REGISTRY_PATH}/fragments"
SUB_CONST_DIR="${REGISTRY_PATH}/sub-constitutions"
CONSTITUTION="${PROJECT_ROOT}/.specify/memory/constitution.md"

echo "=== MANIFEST ==="
cat "$MANIFEST"
echo ""

echo "=== FRAGMENTS ==="
if [[ -d "$FRAGMENTS_DIR" ]]; then
  find "$FRAGMENTS_DIR" -name '*.md' -type f | sort | while read -r f; do
    rel="${f#${FRAGMENTS_DIR}/}"
    name="${rel%.md}"
    echo "$name"
  done
fi
echo ""

echo "=== SUB-CONSTITUTIONS ==="
if [[ -d "$SUB_CONST_DIR" ]]; then
  find "$SUB_CONST_DIR" -name '*.md' -type f | sort | while read -r f; do
    rel="${f#${SUB_CONST_DIR}/}"
    name="${rel%.md}"
    echo "$name"
  done
fi
echo ""

echo "=== LOCAL CONSTITUTION ==="
if [[ -f "$CONSTITUTION" ]]; then
  # Check if it's a placeholder template (contains bracket placeholders like [PROJECT_NAME])
  PLACEHOLDER_COUNT=$(grep -cE '\[(PROJECT_NAME|PRINCIPLE_[0-9]+_NAME|PRINCIPLE_[0-9]+_DESCRIPTION|SECTION_[0-9]+_NAME|SECTION_[0-9]+_CONTENT|CONSTITUTION_VERSION|RATIFICATION_DATE|LAST_AMENDED_DATE|GOVERNANCE_RULES)\]' "$CONSTITUTION" 2>/dev/null || true)
  PLACEHOLDER_COUNT="${PLACEHOLDER_COUNT:-0}"
  PLACEHOLDER_COUNT="$(echo "$PLACEHOLDER_COUNT" | tr -d '[:space:]')"
  if [[ "$PLACEHOLDER_COUNT" -gt 0 ]]; then
    echo "EXISTS=false"
    echo "REASON=placeholder_template"
    echo "PLACEHOLDER_COUNT=$PLACEHOLDER_COUNT"
  else
    echo "EXISTS=true"
    echo "SIZE=$(wc -c < "$CONSTITUTION") bytes"
  fi
else
  echo "EXISTS=false"
fi
```

### Step 4: Present Selection List

Using the data from Step 3, build and present a numbered selection list to the user following this structure:

**Parse the manifest** to identify `mandatory_fragments` and `recommended_fragments` lists.

**Build the selection list** in this exact order:

```
[FRAGMENTS]
<mandatory fragments — NO number, marked (MANDATORY)>
<recommended fragments — numbered, marked (RECOMMENDED)>
<regular fragments — numbered>
[SUB-CONSTITUTIONS]
<sub-constitutions — numbered>
<CURRENT PROJECT CONSTITUTION — numbered, only if constitution.md exists>
```

**Rules:**
- **Mandatory fragments** are listed first WITHOUT a number and marked `(MANDATORY)`. They are always included — the user cannot deselect them.
- **Recommended fragments** are listed next WITH numbers and marked `(RECOMMENDED)`. They are selectable.
- **Regular fragments** are listed after recommended, WITH numbers.
- **Sub-constitutions** are listed under a `[SUB-CONSTITUTIONS]` header, WITH numbers.
- If a **local constitution** exists AND is NOT a placeholder template (see Step 3 — `EXISTS=true`), add it at the end as `<CURRENT PROJECT CONSTITUTION>` WITH a number. It is selectable.
- A constitution is considered a placeholder if it contains bracket-style placeholder tokens like `[PROJECT_NAME]`, `[PRINCIPLE_1_NAME]`, `[CONSTITUTION_VERSION]`, etc. Placeholder files are NOT offered in the selection list.
- Numbering is sequential starting at 1, across all selectable items (recommended, regular fragments, sub-constitutions, and current constitution share the same numbering).

**Example output to show the user:**

```
[FRAGMENTS]
  (MANDATORY) global/compliance
  (MANDATORY) global/security
1. (RECOMMENDED) global/code-quality
2. (RECOMMENDED) languages/typescript/standards
3. domains/finance/regulations
4. domains/ecommerce/checkout
5. languages/python/style
[SUB-CONSTITUTIONS]
6. package-auth
7. package-api
8. <CURRENT PROJECT CONSTITUTION>
```

### Step 5: Collect User Selection

Ask the user to select items by number. Accepted formats:
- Space-separated: `1 2 3 4`
- Comma-separated: `1, 2, 3`
- Dot-separated: `1. 2. 3.`
- Range expressions: `from 3 to 6 plus 8` or `1-4, 7`

Parse the user's selection and combine with mandatory fragments to build the complete section list.

**CRITICAL**: Only items whose numbers appear in the user's selection are included. If `<CURRENT PROJECT CONSTITUTION>` has number N and N is NOT in the user's selection, it must NOT be included in the composition. The same applies to any fragment or sub-constitution — only selected numbers are included.

### Step 6: Show Composition Summary and Confirm

Present the final composition for validation:

```bash
# Calculate total size of all selected content
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

total=0
# For each selected fragment, add its file size
# Example for one fragment:
# size=$(wc -c < "${REGISTRY_PATH}/fragments/<FRAGMENT_NAME>.md")
# total=$((total + size))

# For local constitution (if selected):
# size=$(wc -c < "${PROJECT_ROOT}/.specify/memory/constitution.md")
# total=$((total + size))

echo "TOTAL_BYTES=${total}"
```

Display the summary in this format:

```
========= FINAL PROJECT CONSTITUTION =========
------- COMPOSED --------------
FRAGMENT <fragment_name_1>
FRAGMENT <fragment_name_2>
SUB-CONSTITUTION <sub_constitution_name_1>
<...>
------- PROJECT SPECIFIC ------
<CURRENT PROJECT CONSTITUTION>
===============================================
```

**Rules for the summary:**
- The `------- PROJECT SPECIFIC ------` section and `<CURRENT PROJECT CONSTITUTION>` line are ONLY shown if the user's numbered selection explicitly includes the number assigned to `<CURRENT PROJECT CONSTITUTION>`. If the user did NOT select that number, this section MUST NOT appear in the summary.
- Similarly, each FRAGMENT and SUB-CONSTITUTION line appears ONLY if the user's selection includes its number. Mandatory fragments are always included regardless of selection.
- Do NOT show the content of the constitution — only the label `<CURRENT PROJECT CONSTITUTION>`.
- Each FRAGMENT line shows the fragment name as it appears in the registry (path without `.md`).
- Each SUB-CONSTITUTION line shows the sub-constitution name.

**Size warning:** If the total content size exceeds 32,768 bytes (32 KiB), add this warning before the confirmation prompt:

```
⚠️ The total constitution length will exceed 32 KiB:
Critical information may be overlooked by the agent, and unnecessary tokens increase inference cost.
```

**Confirmation prompt:**

```
Do you confirm this composition? (yes/no/cancel)
```

- **yes**: Proceed to Step 7 (save state).
- **no**: Return to Step 4 (re-display selection list).
- **cancel**: Abort the command entirely.

### Step 7: Save Composition State

On user confirmation, save the composition state to the charter state file.

Write the state as YAML to `.specify/charter/state.yml`:

```yaml
# Charter composition state
# Generated by /speckit.charter.config
# Last configured: <CURRENT_ISO_DATE>

fragments:
  - "<fragment_name_1>"
  - "<fragment_name_2>"
  - "<fragment_name_3>"

sub_constitutions:
  - "<sub_constitution_name_1>"
  - "<sub_constitution_name_2>"

local_constitution: true  # or false
local_constitution_content: |
  <FULL CONTENT OF LOCAL CONSTITUTION WITHOUT SPECKIT METADATA>
```

**Rules for `local_constitution_content`:**
- Only present if `local_constitution: true`
- Must contain the full content of the existing constitution
- **Strip** the Spec Kit top comment (HTML comment block starting with `<!--` that contains "Sync Impact Report")
- **Strip** the Spec Kit bottom metadata line (line starting with `*Version*:` or `**Version**:` containing `Ratified` and `Last Amended`)
- To detect the top comment: check if the first line starts with `<!--` and the second line contains `Sync Impact Report`
- To detect the bottom metadata: check if a line starts with `*Version*` or `**Version**`

To strip these, run:

```bash
CONSTITUTION="${PROJECT_ROOT}/.specify/memory/constitution.md"
if [[ -f "$CONSTITUTION" ]]; then
  awk '
  BEGIN { skip_top=0 }
  NR==1 && /^<!--/ { skip_top=1; next }
  skip_top && /-->/ { skip_top=0; next }
  skip_top { next }
  /^\*\*?Version\*\*?:.*Ratified/ { next }
  { print }
  ' "$CONSTITUTION"
fi
```

Write this state file using:

```bash
mkdir -p "${PROJECT_ROOT}/.specify/charter"
cat > "${PROJECT_ROOT}/.specify/charter/state.yml" << 'STATEEOF'
<GENERATED_YAML_CONTENT>
STATEEOF
```

### Step 8: Display Final Message

After saving the state, display:

```
✅ Composed constitution settings saved.

⚠️  IMPORTANT: Your project constitution has not changed yet.
    To apply this composition, run /speckit.charter.compose
```

## Notes

- The registry can be changed at any time by re-running `/speckit.charter.config`.
- Fragment names correspond to their file paths within the registry's `fragments/` directory, without the `.md` extension (e.g., `languages/typescript/standards`).
- Sub-constitution names correspond to their file paths within the registry's `sub-constitutions/` directory, without the `.md` extension.
- Git registries are cloned/fetched into `.specify/charter/.cache/registry/` and use the default branch.
- Git authentication uses the local system credentials (SSH keys, credential helpers) — no additional authentication is required.
