# Architecture

Design decisions and data flow for the Charter extension.

## Overview

Charter is a Spec Kit extension that composes project constitutions from modular
fragments stored in a centralized registry. It works by:

1. Reading fragment definitions from a registry (directory or git repo)
2. Letting the user select which fragments to include
3. Assembling the fragments into a single constitution
4. Delegating the actual file generation to `/speckit.constitution`
5. Tracking fragment versions for change detection

## Design Principles

### 1. Delegate to Core

Charter does NOT write the constitution file directly. It builds a prompt
containing all fragment content and invokes `/speckit.constitution` to generate
the file. This ensures:

- Spec Kit's Sync Impact Report and version metadata are properly managed
- Compatibility with future `/speckit.constitution` improvements
- Consistent constitution format across charter and non-charter projects

### 2. Scripts Over LLM

Heavy operations (file I/O, validation, comparison, parsing) use shell scripts
rather than LLM reasoning. This:

- Reduces token consumption
- Ensures deterministic behavior
- Makes operations reproducible and testable

### 3. Section Markers

HTML comments (`<!-- [NAME] SECTION -->`) serve as section delimiters in the
generated constitution. They enable:

- Identifying which fragment produced each section
- Extracting individual sections for comparison
- Replacing specific sections during updates
- Preserving project-specific content during recomposition

### 4. Snapshot-Based Change Detection (fragments only)

Rather than tracking fragment hashes, Charter saves full **fragment** content as
"snapshots" after each compose. On subsequent composes, it compares each fragment
section in the constitution against its snapshot to detect local modifications.
This approach:

- Works without a database or complex state
- Handles content normalization naturally
- Provides clear diff capabilities

Sub-constitutions (registry and distributed) are intentionally **not**
snapshotted — see “Cacheless sub-constitutions” below.

### 5. Cacheless Sub-Constitutions

Both registry sub-constitutions (`sub-constitutions/<name>.md`) and distributed
sub-constitutions (`<package>/.charter/constitution.md`) are read **fresh from
their source on every compose**. There is no snapshot and no change-detection
prompt for them. This lets package owners update their rules and have a plain
`/speckit.charter.compose` propagate the change immediately — without
`compose update` or per-package update commands. Only fragments retain the
snapshot mechanism.

## Data Flow

### Configuration Flow

```
User → /speckit.charter.config
  ├── Select registry (path or git URL)
  ├── Validate registry (manifest.yml check)
  ├── Detect distributed sub-constitutions + enable/disable feature
  ├── List fragments (mandatory/recommended/optional) + sub-constitutions
  │     + distributed sub-constitutions (when enabled)
  ├── User selects items
  ├── Show composition summary
  └── Save state.yml
```

### Composition Flow

```
User → /speckit.charter.compose
  ├── Read state.yml
  ├── Backup existing constitution
  ├── Check for section markers (mode detection)
  │   ├── No markers → CREATION mode
  │   └── Has markers → OVERRIDE mode
  │       ├── Compare sections vs snapshots
  │       └── Warn about modifications
  ├── Resolve content sources
  │   ├── Fragments: Creation/Update → Registry; Recreation → Snapshots (registry fallback)
  │   └── Sub-constitutions (registry + distributed) → always fresh (cacheless)
  ├── Save snapshots (fragments only)
  ├── Build prompt with section markers
  ├── Invoke /speckit.constitution
  └── Validate output
```

### Update Flow

```
User → /speckit.charter.compose update [name]
  ├── Fetch latest from registry
  ├── Save new snapshots
  ├── Build prompt with updated content
  ├── Invoke /speckit.constitution
  └── Validate output
```

## File Layout

All Charter data lives under `.specify/charter/`:

```
.specify/charter/
├── config.yml                   # Registry location/type + distributed_sub_constitutions flag
├── state.yml                    # Selected fragments, sub-constitutions, distributed sub-constitutions, local constitution
├── .gitignore                   # Excludes .cache/ from version control
├── .cache/
│   └── registry/                # Cloned git registry (if git-based)
├── snapshots/                   # Saved fragment versions (fragments only — sub-constitutions are cacheless)
│   └── fragment/
│       ├── global/
│       │   ├── compliance.md
│       │   └── code-quality.md
│       └── languages/
│           └── typescript/
│               └── standards.md
└── backups/                     # Constitution backups
    ├── constitution-20260630-143022.md.backup
    └── constitution-20260630-150105.md.backup
```

### Why `.specify/charter/` (and not `.specify/extensions/charter/`)?

The extension install directory (`.specify/extensions/charter/`) holds only the
extension's **scripts and commands**. That directory is managed by Spec Kit and
is wiped/reset on `specify extension update|remove` (only `*-config.yml` files
survive). Storing persistent data there would lose state, snapshots, and
backups on every update.

Instead, Charter keeps all persistent data in a separate `.specify/charter/`
directory:
- **Persists** across extension updates and removals (Spec Kit never touches it)
- **Survives** `specify init --here --force` (Spec Kit only overwrites its own
  template files, never unknown directories)
- **Per-project** — each project has its own configuration
- **Git-versioned** — `config.yml`, `state.yml`, `snapshots/`, and `backups/`
  are meant to be committed; the disposable `.cache/` is gitignored

### .gitignore

Charter automatically writes `.specify/charter/.gitignore` containing:

```gitignore
# Disposable cache (cloned registries, downloads) — do not version.
.cache/
```

Everything else under `.specify/charter/` (config, state, snapshots, backups)
should be version-controlled so team members share the same fragment selection
and pinned versions.

## Registry Resolution

### Local Directory

Direct filesystem access — the directory is used as-is (or resolved relative to
project root).

### Git Repository

The registry is cloned into `.cache/registry/` with `--depth 1` for efficiency.
On subsequent fetches:

1. `git fetch origin` to get latest
2. `git reset --hard origin/HEAD` to update working tree

Authentication uses the local system's git credentials (SSH keys, credential
helpers). No additional auth is configured by Charter.

## Interaction with /speckit.constitution

Charter builds a prompt that instructs `/speckit.constitution` to write the
constitution with specific content. The key instruction is to preserve the HTML
comment section markers exactly as provided.

`/speckit.constitution` adds its own metadata:
- **Top**: Sync Impact Report as an HTML comment
- **Bottom**: Version, Ratified, Last Amended metadata line

Charter is aware of this metadata and:
- Strips it when reading the local constitution for preservation
- Ignores it during section extraction and comparison
- Lets `/speckit.constitution` manage it autonomously

## Distributed Sub-Constitutions

Distributed sub-constitutions target monorepos where each package maintains its
own rules in-tree, at `<package>/.charter/constitution.md`.

### Detection

`distributed-detect.sh` recursively searches from the project root (up to 5
package-directory levels) for files matching `*/.charter/constitution.md`. It
prunes `.git`, `node_modules`, and `.specify`, and skips the root itself. Each
match yields a package path (the directory containing the `.charter` folder),
e.g. `packages/back`.

### Why the `.charter/constitution.md` convention?

Detection only matches files inside a `.charter` folder. This deliberately
avoids a package's own Spec Kit constitution
(`<package>/.specify/memory/constitution.md`) and any bare
`<package>/constitution.md`. The reasons:

- **No conflicting usage** — a monorepo may use Spec Kit at the root *and* inside
  individual packages (e.g. submodules that each use Spec Kit). Reading the
  package Spec Kit constitution would risk duplicating fragment content already
  composed at the root.
- **Future-proofing** — it avoids coupling Charter to the internal format and
  evolution of the Spec Kit constitution file.

### Opt-in and cacheless

The feature is opt-in via the `distributed_sub_constitutions` flag in
`config.yml` (default `false`), set during configuration. Selected package paths
are stored in the `distributed_sub_constitutions` list in `state.yml`. Content is
read fresh via `distributed-read.sh` on every compose (cacheless), so it never
goes through the snapshot store.

## Limitations

- Fragment content is included verbatim — no variable substitution or templating
- The 32 KiB warning is advisory — Charter does not enforce a size limit
- Sub-constitutions use a name-based scoping prefix, not directory-based
- Snapshot comparison (fragments only) is exact string match — formatting changes are detected as modifications
- Distributed sub-constitutions are detected up to 5 package-directory levels deep
