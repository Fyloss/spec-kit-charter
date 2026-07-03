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

1. Spec Kit must be initialized in the project
2. Charter should be configured — `.specify/charter/state.yml` should exist. If it does **not** exist (the user never ran `/speckit.charter.config`), this command runs an inline configuration flow first (see **Step 1**), so a single `/speckit.charter.compose` invocation both configures and composes.

## Steps

### Step 1: Validate State (with inline configuration fallback)

```bash
bash .specify/extensions/charter/scripts/bash/state-check.sh "$(pwd)"
```

**If the state file exists (`STATE_EXISTS=true`):** the charter is already
configured. Proceed directly to **Step 2**.

**If the state file does NOT exist (`STATE_EXISTS=false`):** the user is running
`/speckit.charter.compose` without ever having run `/speckit.charter.config`.
Instead of stopping, run the inline configuration flow below (Step 1a) to
configure the charter and then continue seamlessly into the composition. This
lets a single `/speckit.charter.compose` invocation configure **and** compose in
one pass.

> This fallback requires two inputs from the user, exactly like
> `/speckit.charter.config`:
> 1. **The registry value** — the flow asks for it (offering the current/default
>    `.charter` as the proposed value); it does NOT silently accept the default.
> 2. **The fragment selection.**
>
> After the selection, the flow displays the composition summary **for
> information only — no confirmation is requested** — and proceeds automatically
> all the way to generating the final constitution.

#### Step 1a: Inline Configuration Flow

This flow mirrors `/speckit.charter.config` (Steps 1–7) but **skips the final
yes/no/cancel confirmation** — after the fragment selection the summary is shown
for information and the flow continues automatically.

**1a.1 — Determine and validate the registry**

Ask the user for the registry value (this is a required input, just like the
standalone config command — do not skip it). Check for an existing registry
configuration to propose as the default; otherwise propose `.charter`:

```bash
bash .specify/extensions/charter/scripts/bash/registry-default.sh "$(pwd)"
```

Present the current/default registry to the user and let them confirm it or
enter a new value (relative path, absolute path, or git URL). Then write the
configuration:

```bash
bash .specify/extensions/charter/scripts/bash/config-write.sh "<REGISTRY_VALUE>" "$(pwd)"
```

Validate the registry (clones/refreshes git registries, resolves the local path,
and checks `manifest.yml` and its required fields):

```bash
bash .specify/extensions/charter/scripts/bash/registry-validate.sh "$(pwd)"
```

If validation fails (non-zero exit), display the error and stop. If it succeeds,
continue.

**1a.2 — List available fragments**

Enumerate fragments, sub-constitutions, and detect any existing non-placeholder
local constitution (identical to `/speckit.charter.config` Step 3):

```bash
# Fragments + sub-constitutions, tab-separated: TYPE<TAB>CATEGORY<TAB>PATH<TAB>NAME
bash .specify/extensions/charter/scripts/bash/fragment-list.sh "$(pwd)"

# Detect an existing local constitution.
# Exit code: 0 = placeholder (skip), 1 = usable, 2 = no file.
bash .specify/extensions/charter/scripts/bash/constitution-is-placeholder.sh
echo "placeholder_check_exit=$?"
```

The `TYPE` column from `fragment-list.sh` identifies mandatory and recommended
fragments. Treat the local constitution as selectable only when
`constitution-is-placeholder.sh` exits with code `1`.

**1a.3 — Present the selection list and collect the selection**

Build and present the numbered selection list exactly as in
`/speckit.charter.config` Steps 4–5:

```
[FRAGMENTS]
  (MANDATORY) <mandatory fragments — no number>
1. (RECOMMENDED) <recommended fragments>
2. <regular fragments>
[SUB-CONSTITUTIONS]
3. <sub-constitutions>
4. <CURRENT PROJECT CONSTITUTION>   ← only if a non-placeholder constitution exists
```

Rules:
- Mandatory fragments are always included and are not numbered.
- Recommended, regular fragments, sub-constitutions, and the current
  constitution share one sequential numbering starting at 1.
- Placeholder constitutions are NOT offered.

Ask the user to select items. Accepted formats: space-separated (`1 2 3`),
comma-separated (`1, 2, 3`), dot-separated (`1. 2. 3.`), ranges
(`from 3 to 6 plus 8`, `1-4, 7`). Only selected numbers are included; mandatory
fragments are always included regardless of selection.

**This fragment selection is the only required user input for the fallback
flow.**

**1a.4 — Save the composition state**

Assemble the state YAML (fragments, sub_constitutions, local_constitution, and
the stripped local_constitution_content) exactly as in
`/speckit.charter.config` Step 6.

Get the stripped local constitution content (only if the user selected
`<CURRENT PROJECT CONSTITUTION>`):

```bash
bash .specify/extensions/charter/scripts/bash/constitution-strip-local.sh
```

Write the assembled YAML to the state file (content via stdin):

```bash
bash .specify/extensions/charter/scripts/bash/state-write.sh "$(pwd)" << 'STATEEOF'
<GENERATED_YAML_CONTENT>
STATEEOF
```

**1a.5 — Show the composition summary (informational, NO confirmation)**

Compute the total size from the saved state:

```bash
bash .specify/extensions/charter/scripts/bash/compose-size-check.sh "$(pwd)"
```

Display the composition summary in the standard format:

```
========= FINAL PROJECT CONSTITUTION =========
------- COMPOSED --------------
FRAGMENT <fragment_name_1>
FRAGMENT <fragment_name_2>
SUB-CONSTITUTION <sub_constitution_name_1>
------- PROJECT SPECIFIC ------
<CURRENT PROJECT CONSTITUTION>
===============================================
```

- Show the `------- PROJECT SPECIFIC ------` section and
  `<CURRENT PROJECT CONSTITUTION>` line ONLY if the user selected that number.
- Each FRAGMENT/SUB-CONSTITUTION line appears only if its number was selected;
  mandatory fragments always appear.
- If `compose-size-check.sh` reports `EXCEEDS_32K=true`, show the size warning.

**Do NOT ask for yes/no/cancel confirmation.**

Then continue to **Step 2** to perform the composition. Do not display the
"settings saved / run /speckit.charter.compose" message from the standalone
config command — composition proceeds immediately in this combined flow.

### Step 2: Create Backup

Before any modification, back up the existing constitution. The script writes a
timestamped copy to `.specify/charter/backups/` (and no-ops if there's no
constitution yet), printing the backup path:

```bash
bash .specify/extensions/charter/scripts/bash/constitution-backup.sh "$(pwd)"
```

### Step 3: Detect Current Mode

Read the existing constitution and check for section markers:

```bash
bash .specify/extensions/charter/scripts/bash/constitution-parse.sh
```

`constitution-parse.sh` prints `FILE_EXISTS=true|false`, `HAS_SECTIONS=true|false`,
and the list of section names found.

**Determine the mode:**

- **CREATION MODE**: If no section markers are found (new project or non-charter constitution). Go to **Step 5**.
- **OVERRIDE MODE**: If section markers ARE found (previously composed constitution). Go to **Step 4**.

### Step 4: Override Mode — Detect Local Modifications

In override mode, compare each fragment section in the current constitution against the saved snapshots to detect manual edits.

`snapshot-detect-modified.sh` reads the fragment and sub-constitution lists from
`state.yml`, diffs each section against its snapshot, and reports the result:

```bash
bash .specify/extensions/charter/scripts/bash/snapshot-detect-modified.sh "$(pwd)"
```

It prints `MODIFIED=true` followed by one `MODIFIED_SECTION=<name>` line per
changed section, or `MODIFIED=false`.

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

Before proceeding, if the constitution contains a `<!-- [PROJECT SPECIFIC] SECTION -->` marker, extract its current content and update the `local_constitution_content` in the state file. This ensures the latest local constitution edits are always preserved:

```bash
bash .specify/extensions/charter/scripts/bash/constitution-extract.sh "PROJECT SPECIFIC" .specify/memory/constitution.md
```

Write the extracted content back into `local_constitution_content` via `state-write.sh`.

### Step 5: Resolve Content Sources

Determine whether to use registry versions or snapshot versions for each fragment.

**Parse the arguments to determine sub-mode:**

**If arguments contain `update`:**
- **UPDATE MODE**: Fetch latest versions from the registry and save new snapshots.
- If a specific fragment name follows `update` (e.g., `update global/compliance`), only update THAT fragment — leave all others using their current snapshot versions.

**If no `update` argument AND we're in Override Mode (HAS_SECTIONS=true):**
- **RECREATION MODE**: Use previously saved snapshots. Check which fragments in the state are missing a snapshot:

```bash
bash .specify/extensions/charter/scripts/bash/snapshot-list-missing.sh "$(pwd)"
```

It prints `MISSING_SNAPSHOTS=true` followed by one `MISSING=<name>` line per
missing snapshot, or `MISSING_SNAPSHOTS=false`.

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

For UPDATE MODE with a specific fragment name, refresh the registry cache and read ONLY that fragment. Its type (`fragment` or `sub-constitution`) is known from the appropriate list in `state.yml`:

```bash
# Refresh the registry cache (no-op for local path registries)
bash .specify/extensions/charter/scripts/bash/registry-fetch.sh "$(pwd)" >/dev/null

# Read the fragment from the registry (<TYPE> = fragment | sub-constitution)
bash .specify/extensions/charter/scripts/bash/fragment-read.sh "<FRAGMENT_NAME>" "<TYPE>" "$(pwd)"
```

For full compose (CREATION or RECREATION MODE), read ALL fragments and build the complete constitution content. For each fragment / sub-constitution listed in `state.yml`, read the content from:
- **CREATION MODE / UPDATE MODE** — the registry: `fragment-read.sh <NAME> <TYPE> "$(pwd)"`
- **RECREATION MODE** — the snapshot: `snapshot-read.sh <NAME> <TYPE> "$(pwd)"` (exit code `2` means the snapshot is missing; fall back to `fragment-read.sh`)

### Step 7: Save Snapshots

For CREATION MODE and UPDATE MODE, save snapshots of all fragments being used. `snapshot-save.sh` copies the current registry version into the snapshot store:

```bash
# For each fragment used:
bash .specify/extensions/charter/scripts/bash/snapshot-save.sh "<FRAGMENT_NAME>" "fragment" "$(pwd)"

# For each sub-constitution used:
bash .specify/extensions/charter/scripts/bash/snapshot-save.sh "<SUB_CONSTITUTION_NAME>" "sub-constitution" "$(pwd)"
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

After `/speckit.constitution` completes, validate the generated constitution.
`constitution-validate-sections.sh` derives the expected sections from `state.yml`
(fragments + sub-constitutions + the PROJECT SPECIFIC section when a local
constitution is included) and verifies each has a section marker:

```bash
bash .specify/extensions/charter/scripts/bash/constitution-validate-sections.sh "$(pwd)"
```

It prints `VALID=true` on success, or `VALID=false` with one `MISSING=<name>`
line per absent section (and exits non-zero). Surface any missing sections to the
user and suggest re-running the compose command.

### Step 11: Display Result

If validation passes:

```
✅ Composed constitution successfully generated and compliant with configuration.

ℹ️  If the generated constitution is not valid, you can restore the previous
    constitution by running /speckit.charter.restore
```

If validation has warnings, display them and suggest running the compose command again.

For UPDATE MODE with a single fragment, also confirm:

```
✅ Fragment "<FRAGMENT_NAME>" updated successfully in the constitution.
```

## Notes

- Backups are stored in `.specify/charter/backups/` with timestamps
- Snapshots are stored in `.specify/charter/snapshots/` organized by type
- The local constitution content in the state file is updated each time compose runs in override mode
- Section markers (`<!-- [NAME] SECTION -->`) are the backbone of the update mechanism — never remove them manually
- The `/speckit.constitution` command adds its own metadata (Sync Impact Report, version line) — this is expected and should not be confused with charter sections
