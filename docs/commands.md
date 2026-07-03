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

2. **Fragment Selection** — interactive numbered list
   - Mandatory fragments: always included, no number, marked `(MANDATORY)`
   - Recommended fragments: numbered, marked `(RECOMMENDED)`, selectable
   - Regular fragments: numbered, selectable
   - Sub-constitutions: numbered, selectable, listed under `[SUB-CONSTITUTIONS]`
   - Current project constitution: numbered, listed if exists

3. **Confirmation** — shows composition summary with size check
   - `yes` — save configuration
   - `no` — return to fragment selection
   - `cancel` — abort

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
- `.specify/charter/config.yml` — registry location
- `.specify/charter/state.yml` — selected fragments and local constitution

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

Saves new snapshots after update.

#### Recreation Mode (no arguments, with existing sections)

Recomposes using previously saved snapshots:

- Uses snapshot versions (not latest registry)
- Warns if snapshots are missing for any fragment
- Falls back to registry for missing snapshots

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
<sub_const_1 content>
<!-- [PROJECT SPECIFIC] SECTION -->
<local constitution content>
**Version**: X.Y.Z | ...           ← Added by /speckit.constitution
```

### Backup

A backup is created before every compose operation:
- Location: `.specify/charter/backups/`
- Format: `constitution-YYYYMMDD-HHMMSS.md.backup`

### Validation

After composition, Charter validates that all expected section markers are
present in the generated file.

---

## /speckit.charter.remove

Remove a fragment or sub-constitution from the composition.

### Usage

```
/speckit.charter.remove <fragment_name>
```

### Arguments

| Argument | Description |
|----------|-------------|
| `fragment_name` | Name of the fragment or sub-constitution to remove |

### Behavior

1. Validates the fragment exists in the current configuration
2. Checks the fragment is not mandatory (mandatory fragments cannot be removed)
3. Updates the state file
4. Removes the snapshot
5. Recomposes the constitution via `/speckit.charter.compose`

### Restrictions

- **Mandatory fragments** cannot be removed — they are defined in the registry manifest
- **Local constitution** (`<CURRENT PROJECT CONSTITUTION>`) cannot be removed via this command — re-run `/speckit.charter.config` and deselect it instead

### Examples

```
/speckit.charter.remove languages/typescript/standards
/speckit.charter.remove package-auth
```
