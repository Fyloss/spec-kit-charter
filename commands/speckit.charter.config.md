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
bash .specify/extensions/charter/scripts/bash/registry-default.sh "$(pwd)"
```

It prints `EXISTING_CONFIG=true|false` and a `registry: <value>` line (the
existing registry, or the default `.charter` proposal).

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

### Step 2: Validate Registry

Fetch and validate the registry. The script clones/refreshes git registries,
resolves the local path, and verifies the structure (`manifest.yml` present with
required `version` and `name` fields):

```bash
bash .specify/extensions/charter/scripts/bash/registry-validate.sh "$(pwd)"
```

On success it prints `VALID` along with `name=` and `version=`. On failure it
prints the error to stderr and exits non-zero.

**If validation fails**: Display the error message to the user and invite them to re-run `/speckit.charter.config` with a valid registry. **Stop execution here.**

**If validation succeeds**: Proceed to Step 3.

### Step 3: List Available Fragments

Enumerate all available fragments and sub-constitutions, and detect any existing
local constitution.

```bash
# Fragments + sub-constitutions, tab-separated: TYPE<TAB>CATEGORY<TAB>PATH<TAB>NAME
# TYPE is one of: mandatory_fragment | recommended_fragment | fragment | sub-constitution
bash .specify/extensions/charter/scripts/bash/fragment-list.sh "$(pwd)"

# Detect an existing local constitution.
# Exit code: 0 = placeholder (skip), 1 = usable constitution, 2 = no file.
bash .specify/extensions/charter/scripts/bash/constitution-is-placeholder.sh
echo "placeholder_check_exit=$?"
```

`fragment-list.sh` already tags mandatory and recommended fragments via the
`TYPE` column (read from the registry `manifest.yml`), so no separate manifest
parsing is needed. Treat the local constitution as selectable only when
`constitution-is-placeholder.sh` exits with code `1` (usable, not a placeholder).

### Step 4: Present Selection List

Using the data from Step 3, build and present a numbered selection list to the user following this structure:

**Use the `TYPE` column** from `fragment-list.sh` to identify mandatory and
recommended fragments (no separate manifest parsing needed).

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

### Step 6: Save Composition State

Build the composition state and write it to `.specify/charter/state.yml`.

The YAML structure is:

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
  <LOCAL CONSTITUTION CONTENT WITHOUT SPECKIT METADATA>
```

**Rules for `local_constitution_content`:**
- Only present if `local_constitution: true` (the user selected
  `<CURRENT PROJECT CONSTITUTION>`).
- Obtain the stripped content (Sync Impact Report header and the
  `Version/Ratified/Last Amended` footer removed) with:

```bash
bash .specify/extensions/charter/scripts/bash/constitution-strip-local.sh
```

Write the assembled YAML to the state file (the script reads the content from
stdin):

```bash
bash .specify/extensions/charter/scripts/bash/state-write.sh "$(pwd)" << 'STATEEOF'
<GENERATED_YAML_CONTENT>
STATEEOF
```

### Step 7: Show Composition Summary

Present the final composition for information. **Do NOT ask for confirmation** —
the only inputs this command requests are the registry value (Step 1) and the
fragment selection (Step 5).

Compute the total size (reads the just-saved state, sums all selected fragment
content plus the local constitution):

```bash
bash .specify/extensions/charter/scripts/bash/compose-size-check.sh "$(pwd)"
```

This outputs `TOTAL_BYTES=<n>` and `EXCEEDS_32K=true|false`.

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

**Size warning:** If `EXCEEDS_32K=true`, add this warning:

```
⚠️ The total constitution length will exceed 32 KiB:
Critical information may be overlooked by the agent, and unnecessary tokens increase inference cost.
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
