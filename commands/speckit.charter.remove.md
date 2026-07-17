---
description: "Remove a fragment or sub-constitution section from the composed constitution"
scripts:
  sh: ../../scripts/bash/charter-common.sh
---

# Charter Remove

Remove a named fragment or sub-constitution from the charter composition and regenerate the constitution.

## User Input

$ARGUMENTS

The argument MUST be the name of a fragment, registry sub-constitution, or distributed sub-constitution to remove (e.g., `global/compliance`, `package-auth`, `packages/back`).

## Prerequisites

1. Charter must be configured — `.specify/charter/state.yml` must exist
2. The named fragment/sub-constitution must exist in the current configuration

## Steps

### Step 1: Parse and Validate Arguments

The argument is the name of the fragment or sub-constitution to remove.

```bash
bash .specify/extensions/charter/scripts/bash/state-check.sh "$(pwd)"
```

If the output is `STATE_EXISTS=false`, the charter is not configured — display
the error below and stop:

```
❌ ERROR: No charter configuration found.
Run /speckit.charter.config first.
```

Identify the target section name from the arguments. Verify it exists in the `fragments`, `sub_constitutions`, or `distributed_sub_constitutions` list in the state file.

If the section is not found in the state, display:

```
❌ ERROR: "<SECTION_NAME>" is not in the current composition.
Available sections:
  Fragments: <list>
  Sub-constitutions: <list>
  Distributed sub-constitutions: <list>
```

### Step 2: Check for Mandatory Fragments

Before removing, verify the fragment is not mandatory. `fragment-is-mandatory.sh`
checks the target against the registry manifest's mandatory list:

```bash
bash .specify/extensions/charter/scripts/bash/fragment-is-mandatory.sh "<SECTION_NAME>" "$(pwd)"
```

It prints `MANDATORY=true` and exits `0` if the fragment is mandatory, or prints
`MANDATORY=false` and exits `1` otherwise.

If the fragment is mandatory, display:

```
❌ ERROR: "<FRAGMENT_NAME>" is a mandatory fragment and cannot be removed.
Mandatory fragments are defined in the registry manifest and must be included in all compositions.
```

Stop execution.

### Step 3: Update State File

Remove the fragment/sub-constitution from the state file:

1. Read the current state
2. Remove the target from the `fragments`, `sub_constitutions`, or `distributed_sub_constitutions` list
3. Write the updated state back

Write the updated YAML to `.specify/charter/state.yml`.

### Step 4: Remove Snapshot (fragments only)

Only **fragments** have snapshots. Registry and distributed sub-constitutions are
cacheless, so there is no snapshot to remove for them.

```bash
TARGET_NAME="<SECTION_NAME>"
TYPE="<TYPE>"   # fragment | sub-constitution | distributed (known from the state list it was in)
if [[ "$TYPE" == "fragment" ]]; then
  bash .specify/extensions/charter/scripts/bash/snapshot-remove.sh "$TARGET_NAME" "fragment" "$(pwd)"
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

- Removing an item updates both the state file and the actual constitution
- The mandatory fragment check uses the registry manifest — mandatory fragments cannot be removed
- Distributed sub-constitutions are removed by their package path (e.g. `packages/back`); this removes them from the composition but never touches the package's `.charter/constitution.md` file
- The `<CURRENT PROJECT CONSTITUTION>` (local constitution) cannot be removed via this command — to remove it, re-run `/speckit.charter.config` and deselect it
- A backup of the previous constitution is created automatically during recomposition
