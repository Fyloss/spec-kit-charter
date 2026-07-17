# Commands Reference

Complete reference for all Charter extension commands.

## /speckit.charter.config

Configure the charter registry and select constitution fragments.

### Usage

```
/speckit.charter.config
```

### Workflow

1. **Registry Selection** — prompted for the registry location
   - Default: `.charter` (relative to project root)
   - Accepts: relative path, absolute path, git SSH URL, git HTTPS URL
   - Validates registry structure (must contain `manifest.yml`)

2. **Distributed sub-constitutions detection** — after the registry is
   validated, Charter scans monorepo packages for
   `<package>/.charter/constitution.md` files and asks whether to enable the
   feature (stored as `distributed_sub_constitutions` in `config.yml`, default
   `false`).

3. **Fragment Selection** — interactive numbered list, each item tagged `|R|`
   (registry) or `|L|` (local)
   - Mandatory fragments: always included, no number, marked `(MANDATORY)`
   - Recommended fragments: numbered, marked `(RECOMMENDED)`, selectable
   - Regular fragments: numbered, selectable
   - Registry sub-constitutions: numbered, `|R|`, under `[SUB-CONSTITUTIONS]`
   - Distributed sub-constitutions: numbered, `|L|`, marked `(detected)` (only
     when the feature is enabled)
   - Current project constitution: numbered, `|L|`, under `[OTHER]`, listed if it
     exists

4. **Summary** — shows the composition summary with size check for information
   only. **No confirmation prompt is shown** — the command only asks for the
   registry (step 1), the distributed enable choice (step 2), and the fragment
   selection (step 3).

After saving, the command reminds you that if the generated constitution is not
valid, `/speckit.charter.restore` can restore the previous constitution.

### Selection Syntax

Multiple formats accepted for selecting items:

| Format | Example |
|--------|---------|
| Space-separated | `1 2 3 4` |
| Comma-separated | `1, 2, 3` |
| Dot-separated | `1. 2. 3.` |
| Range | `from 3 to 6 plus 8` |
| Mixed | `1-4, 7` |

### Output

Saves configuration to:
- `.specify/charter/config.yml` — registry location/type and the `distributed_sub_constitutions` flag
- `.specify/charter/state.yml` — selected fragments, sub-constitutions, distributed sub-constitutions, and local constitution

---

## /speckit.charter.compose

Compose the project constitution from selected fragments.

### Usage

```
/speckit.charter.compose
/speckit.charter.compose update
/speckit.charter.compose update <fragment_name>
```

### Modes

#### Auto-Configuration Mode (no prior config)

Triggered when `/speckit.charter.compose` is run before `/speckit.charter.config`
was ever run — detected by the absence of `.specify/charter/state.yml`.

Instead of erroring out, compose runs an inline configuration flow and then
composes in the same pass:

1. **Registry selection/validation** — prompted for the registry location
   (proposing the current/default `.charter`); the registry is validated. This
   is a required input, not silently defaulted.
2. **Fragment selection** — the interactive numbered list is shown; the user
   selects fragments. This is the second input.
3. **Composition summary** — the selected composition is displayed for
   information. **No yes/no/cancel confirmation is requested.**
4. **Composition** — the flow proceeds automatically to generate the final
   constitution.

Before composing, the flow reminds you that if the generated constitution is not
valid, `/speckit.charter.restore` can restore the previous constitution.

This lets users configure the charter and generate the constitution in a single
`/speckit.charter.compose` step. Once the state file exists, subsequent runs use
the normal modes below.

#### Creation Mode

Triggered when no section markers exist in the current constitution (first-time
compose or non-charter constitution).

- Fetches all fragments from the registry
- Saves snapshots for change detection
- Generates the full constitution via `/speckit.constitution`

#### Override Mode

Triggered when section markers are found in the existing constitution.

- Compares each section against its snapshot
- Warns about locally modified sections
- Asks for confirmation before overwriting

#### Update Mode (`update` argument)

Updates fragments from the registry:

- `update` — refreshes all fragments to latest registry versions
- `update <name>` — refreshes only the named fragment

Saves new snapshots after update. Sub-constitutions ignore `update` because they
are always read fresh on every compose.

#### Recreation Mode (no arguments, with existing sections)

Recomposes using previously saved snapshots:

- Uses snapshot versions for **fragments** (not latest registry)
- Warns if fragment snapshots are missing (falls back to registry)
- Always re-reads registry and distributed sub-constitutions fresh (cacheless)

### Constitution Structure

The generated constitution follows this structure:

```markdown
<!-- Sync Impact Report ... -->    ← Added by /speckit.constitution
<!-- [fragment_1] SECTION -->
<fragment_1 content>

<!-- [fragment_2] SECTION -->
<fragment_2 content>

<!-- [sub_const_1] SECTION -->
WHEN WORKING ON sub_const_1, FOLLOW THESE INSTRUCTIONS:
<registry sub-constitution content>

<!-- [packages/back] SECTION -->
WHEN WORKING ON packages/back, FOLLOW THESE INSTRUCTIONS:
<distributed sub-constitution content>

<!-- [PROJECT SPECIFIC] SECTION -->
<local constitution content>
**Version**: X.Y.Z | ...           ← Added by /speckit.constitution
```

Order: fragments → registry sub-constitutions → distributed sub-constitutions →
project specific.

> Registry and distributed sub-constitutions are **cacheless**: a plain
> `/speckit.charter.compose` always re-reads their latest content, so package
> owners don't need an `update` step. Only fragments are snapshotted.

### Backup

A backup is created before every compose operation:
- Location: `.specify/charter/backups/`
- Format: `constitution-YYYYMMDD-HHMMSS.md.backup`

### Validation

After composition, Charter validates that all expected section markers are
present in the generated file.

---

## /speckit.charter.remove

Remove a fragment, registry sub-constitution, or distributed sub-constitution from the composition.

### Usage

```
/speckit.charter.remove <name>
```

### Arguments

| Argument | Description |
|----------|-------------|
| `name` | Name of the fragment / registry sub-constitution, or the package path of a distributed sub-constitution, to remove |

### Behavior

1. Validates the item exists in the current configuration
2. Checks the fragment is not mandatory (mandatory fragments cannot be removed)
3. Updates the state file
4. Removes the snapshot (fragments only — sub-constitutions are cacheless)
5. Recomposes the constitution via `/speckit.charter.compose`

### Restrictions

- **Mandatory fragments** cannot be removed — they are defined in the registry manifest
- **Local constitution** (`<CURRENT PROJECT CONSTITUTION>`) cannot be removed via this command — re-run `/speckit.charter.config` and deselect it instead
- Removing a distributed sub-constitution takes it out of the composition but never touches the package's `.charter/constitution.md` file

### Examples

```
/speckit.charter.remove languages/typescript/standards
/speckit.charter.remove package-auth
/speckit.charter.remove packages/back
```
