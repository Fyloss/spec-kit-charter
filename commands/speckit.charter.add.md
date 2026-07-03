---
description: "Add a new fragment from the registry to the composition and rebuild the constitution"
scripts:
  sh: ../../scripts/bash/charter-common.sh
---

# Charter Add

Add a new fragment or sub-constitution from the registry to the current composition state and rebuild the constitution.

## User Input

$ARGUMENTS

The argument MAY be the name of a fragment or sub-constitution to add (e.g., `global/code-quality`, `package-auth`). If not provided, the user will be asked to select from available options.

## Prerequisites

1. Charter must be configured — `.specify/charter/state.yml` must exist (run `/speckit.charter.config` first)
2. The registry must be accessible

## Steps

### Step 1: Validate State

```bash
bash .specify/extensions/charter/scripts/bash/state-check.sh "$(pwd)"
```

If the output is `STATE_EXISTS=false`, the charter is not configured — display the
error below and stop:

```
❌ ERROR: No charter configuration found.
Run /speckit.charter.config first to configure the registry and select fragments.
```

### Step 2: Resolve Registry and List Available Fragments

```bash
echo "=== ALL REGISTRY FRAGMENTS & SUB-CONSTITUTIONS ==="
# Tab-separated: TYPE<TAB>CATEGORY<TAB>PATH<TAB>NAME
# TYPE = mandatory_fragment | recommended_fragment | fragment | sub-constitution
bash .specify/extensions/charter/scripts/bash/fragment-list.sh "$(pwd)"
```

The currently selected fragments and sub-constitutions were already printed by
`state-check.sh` in Step 1 (the `fragments:` and `sub_constitutions:` lists in
the state).

### Step 3: Present Available (Not Yet Selected) Fragments

From the output of Step 2, compute the **difference** between all registry items and currently selected items. Only items NOT already in the state are available for addition.

Build a numbered selection list of available items:

```
Available fragments to add:
[FRAGMENTS]
1. global/security
2. domains/finance/regulations
3. languages/python/style
[SUB-CONSTITUTIONS]
4. package-monitoring
5. package-logging
```

**Rules:**
- Only show items that are NOT already in the state file (neither in `fragments` nor `sub_constitutions` lists)
- Number sequentially starting at 1
- Group by type: fragments first, then sub-constitutions

If the argument already specifies a valid fragment name that is NOT in the current state, skip the selection list and use that name directly.

If the argument specifies a name that is ALREADY in the state, display:

```
❌ ERROR: "<NAME>" is already in the current composition.
Current fragments: <list>
Current sub-constitutions: <list>
```

If no items are available (all registry items are already selected), display:

```
ℹ️  All available fragments from the registry are already in the composition.
```

### Step 4: Ask User to Select Fragment

If no valid argument was provided, ask the user to select from the numbered list:

```
Select the fragment to add (enter number or name):
```

The user can provide either a number from the list or the full fragment name.

Validate the selection:
- If a number: must be within the displayed range
- If a name: must match an available (not yet selected) fragment/sub-constitution from the registry

### Step 5: Ask for Position

Once the fragment is identified, determine where to place it in the composition.

Display the current composition order:

```
Current composition order:
1. global/compliance (fragment)
2. global/code-quality (fragment)
3. languages/typescript/standards (fragment)
4. package-auth (sub-constitution)
5. <CURRENT PROJECT CONSTITUTION>

Where should "<NEW_FRAGMENT>" be placed?
(Examples: "after 2", "before 3", "between 1 and 2", "at the end", "after global/code-quality")
Default: at the end (before local constitution if present)
```

**Rules for the position display:**
- Show all fragments in order from the state file, numbered sequentially
- Show all sub-constitutions after fragments, continuing the numbering
- If `local_constitution: true`, show `<CURRENT PROJECT CONSTITUTION>` as the last item
- The local constitution is ALWAYS the last section — the new fragment cannot be placed after it

**Parse the user's position response:**
- `"after N"` or `"after <name>"` — insert after position N or after the named item
- `"before N"` or `"before <name>"` — insert before position N or before the named item
- `"between N and M"` or `"between <name1> and <name2>"` — insert between those positions
- `"at the end"`, `"end"`, `"last"`, or empty/default — append at the end of the appropriate list (fragments or sub-constitutions), but always before the local constitution
- `"at the beginning"`, `"first"`, `"start"` — insert at position 1

**CRITICAL**: The local constitution (`<!-- [PROJECT SPECIFIC] SECTION -->`) is ALWAYS the very last section in the final constitution. No fragment or sub-constitution can be placed after it. If the user requests a position after the local constitution, respond:

```
⚠️ The local constitution is always the last section. Placing "<NEW_FRAGMENT>" just before it instead.
```

**Position resolution logic:**
- Fragments are inserted into the `fragments` list in state.yml
- Sub-constitutions are inserted into the `sub_constitutions` list in state.yml
- The position number maps to the combined ordered list (fragments then sub-constitutions)
- When inserting a fragment, compute the index within the `fragments` array
- When inserting a sub-constitution, compute the index within the `sub_constitutions` array

### Step 6: Update State File

Add the new fragment/sub-constitution to the state file at the determined position.

1. Read the current state
2. Insert the new item at the correct position in the appropriate list (`fragments` or `sub_constitutions`)
3. Write the updated state back

Write the updated YAML to `.specify/charter/state.yml`.

### Step 7: Fetch and Save Snapshot

Fetch the fragment content from the registry and save a snapshot. The type
(`fragment` or `sub-constitution`) is known from the selection made in the
previous steps. `snapshot-save.sh` copies the registry version into the snapshot
store, and `fragment-read.sh` prints the content to embed:

```bash
FRAG_NAME="<NEW_FRAGMENT_NAME>"
TYPE="<TYPE>"   # fragment | sub-constitution

bash .specify/extensions/charter/scripts/bash/snapshot-save.sh "$FRAG_NAME" "$TYPE" "$(pwd)"

echo "CONTENT:"
bash .specify/extensions/charter/scripts/bash/fragment-read.sh "$FRAG_NAME" "$TYPE" "$(pwd)"
```

### Step 8: Recompose Constitution

Invoke `/speckit.charter.compose` to rebuild the constitution with the newly added fragment at the correct position.

This ensures the constitution file is regenerated consistently using the same composition pipeline.

### Step 9: Display Result

```
✅ Fragment "<NEW_FRAGMENT_NAME>" added to the composition at position <POSITION>.
   The constitution has been regenerated.

Current composition:
  1. <fragment_1>
  2. <fragment_2>
  ...
  N. <CURRENT PROJECT CONSTITUTION>
```

## Notes

- Adding a fragment updates both the state file and the actual constitution (via recomposition)
- The local constitution is always the last section — new items are placed before it by default
- If the fragment is already in the composition, the command refuses and suggests using `/speckit.charter.compose update <name>` instead
- A backup of the previous constitution is created automatically during recomposition
- The position is determined by the combined order of fragments + sub-constitutions in the state file
