# Charter: Constitution Composer for Spec Kit

A [Spec Kit](https://github.com/github/spec-kit) extension that enables modular
composition of project constitutions from shared fragment registries.

## Problem

Organizations with multiple applications using Spec Kit often share common
governance rules (security policies, coding standards, domain regulations).
Without Charter, each project maintains its own constitution independently,
leading to:

- **Inconsistency** — shared rules diverge across projects
- **Maintenance burden** — updating a common rule requires editing every project
- **No modularity** — constitutions are monolithic, mixing shared and project-specific rules

## What Charter Does

Charter introduces a **registry-based composition model** for constitutions:

1. **Centralize shared rules** as reusable fragments in a registry (local directory or git repo)
2. **Select fragments** per project — mandatory, recommended, and optional
3. **Compose** a final constitution by assembling selected fragments + project-specific rules
4. **Track changes** — detect when fragments are modified locally vs. updated in the registry
5. **Support monorepos** — scope rules to packages via central registry sub-constitutions or in-tree distributed sub-constitutions


<p align="center" style="margin-top: 30px">
  <img src=".github/assets/summary-graph.png" alt="Features summary graph"  width="600">
</p>

## Installation

```bash
# From Spec Kit Catalog
specify extension add charter

# From GitHub release
specify extension add charter --from https://github.com/Fyloss/spec-kit-charter/archive/refs/tags/v0.4.0.zip
```

## Quick Start

### 1. Set Up a Registry

Create a fragment registry (local directory or git repo):

```
.charter/
├── manifest.yml
├── fragments/
│   ├── global/
│   │   ├── compliance.md
│   │   └── code-quality.md
│   └── languages/
│       └── typescript/
│           └── standards.md
└── sub-constitutions/
    ├── package-auth.md
    └── package-api.md
```

Create `manifest.yml`:

```yaml
version: 1
name: "My Organization Charter Registry"
mandatory_fragments:
  - "global/compliance"
recommended_fragments:
  - "global/code-quality"
```

### 2. Configure Charter

```
/speckit.charter.config
```

This command will:
- Ask for the registry location (defaults to `.charter` in the project root)
- Validate the registry structure
- List available fragments for selection
- Save your composition choices

### 3. Compose the Constitution

```
/speckit.charter.compose
```

This command will:
- Back up the existing constitution
- Assemble all selected fragments
- Invoke `/speckit.constitution` to generate the final file
- Validate the output

### Express Mode — Configure and Compose in One Step

You can skip step 2 entirely. If no configuration exists yet, running
`/speckit.charter.compose` directly will perform the configuration inline:

```
/speckit.charter.compose
```

The combined flow:

1. **Asks for the registry value** (proposing the current/default `.charter`) —
   first input
2. Shows the fragment list and asks for your **selection** — second input
3. Displays the composition summary (no confirmation prompt)
4. Proceeds automatically to generate the constitution

If the generated constitution is not valid, run `/speckit.charter.restore` to
restore the previous constitution.

Use this when you want to go from a fresh registry to a composed constitution
without switching commands.

## Commands

| Command | Description |
|---------|-------------|
| `/speckit.charter.config` | Configure registry and select fragments |
| `/speckit.charter.compose` | Compose constitution from selected fragments |
| `/speckit.charter.compose update` | Update all fragments from registry |
| `/speckit.charter.compose update <name>` | Update a single fragment |
| `/speckit.charter.add <name>` | Add a new fragment from the registry |
| `/speckit.charter.remove <name>` | Remove a fragment from the composition |
| `/speckit.charter.restore` | Restore constitution to last backup |

## Registry Structure

```
<registry_root>/
├── manifest.yml                    # Required: registry metadata
├── fragments/                      # Constitution fragments
│   ├── global/                     # Organization-wide rules
│   │   ├── compliance.md
│   │   └── security.md
│   ├── domains/                    # Domain-specific rules
│   │   ├── finance/
│   │   │   └── regulations.md
│   │   └── ecommerce/
│   │       └── checkout.md
│   └── languages/                  # Language/tech-specific rules
│       ├── typescript/
│       │   └── standards.md
│       └── python/
│           └── style.md
└── sub-constitutions/              # Monorepo package-specific rules
    ├── package-auth.md
    └── package-api.md
```

### Manifest Format

```yaml
version: 1
name: "Organization Charter Registry"
mandatory_fragments:
  - "global/compliance"             # Always included, cannot be deselected
recommended_fragments:
  - "global/code-quality"           # Pre-selected, can be deselected
```

## Constitution Output

The composed constitution uses HTML comment markers to delimit sections:

```markdown
<!-- [global/compliance] SECTION -->
<compliance fragment content>

<!-- [global/code-quality] SECTION -->
<code quality fragment content>

<!-- [package-auth] SECTION -->
WHEN WORKING ON package-auth, FOLLOW THESE INSTRUCTIONS:
<package-auth sub-constitution content>

<!-- [PROJECT SPECIFIC] SECTION -->
<existing project-specific constitution content>
```

These markers enable:
- Section-level update detection
- Individual fragment replacement
- Preservation of project-specific rules during recomposition

## Monorepo Support

Charter offers two complementary mechanisms for monorepos:

### 1. Registry sub-constitutions (centralized)

Sub-constitutions in the registry's `sub-constitutions/` directory are scoped to
a specific package with a prefix line:

```markdown
WHEN WORKING ON <package-name>, FOLLOW THESE INSTRUCTIONS:
```

Use these when you want package rules stored **centrally in the registry** rather
than inside the packages.

### 2. Distributed sub-constitutions (in-tree)

Distributed sub-constitutions let each package own its rules **next to its code**,
in a `<package>/.charter/constitution.md` file:

```
/                         # monorepo root (Spec Kit installed here)
├── .specify/
├── .charter/             # registry (fragments + central sub-constitutions)
└── packages/
    ├── front/
    │   ├── .charter/
    │   │   └── constitution.md   # front's distributed sub-constitution
    │   └── ...                   # front's code
    └── back/
        ├── .charter/
        │   └── constitution.md   # back's distributed sub-constitution
        └── ...                   # back's code
```

During configuration, Charter recursively scans (up to 5 package levels) for
`<package>/.charter/constitution.md` files and, once you enable the feature,
offers them for selection alongside registry fragments. In the composed
constitution each one becomes a scoped section keyed by its package path:

```markdown
<!-- [packages/back] SECTION -->
WHEN WORKING ON packages/back, FOLLOW THESE INSTRUCTIONS:
<content of packages/back/.charter/constitution.md>
```

**Why only files inside a `.charter` folder?** Detection deliberately ignores a
package's own Spec Kit constitution (e.g. `packages/x/.specify/memory/constitution.md`
or a bare `packages/x/constitution.md`). This avoids conflicts when Spec Kit is
used both at the monorepo root and inside individual packages (e.g. a monorepo of
submodules that each use Spec Kit), and avoids interfering with future evolution
of the Spec Kit constitution file.

Enable distributed sub-constitutions during `/speckit.charter.config` (the flag
`distributed_sub_constitutions` is stored in `config.yml`, default `false`).

### Cacheless sub-constitutions

Both registry and distributed sub-constitutions are **cacheless**: every
`/speckit.charter.compose` re-reads their latest on-disk content. Package owners
can edit their `.charter/constitution.md` and simply re-run
`/speckit.charter.compose` — no `update` step is needed. Only fragments are
snapshotted for change detection.

## Storage Locations

Charter stores all persistent data under `.specify/charter/` — a dedicated
directory that lives **outside** the extension install dir so it survives
`specify extension update`/`remove` and project re-inits. Commit it to git.

| Data | Location | Purpose |
|------|----------|---------|
| Config | `.specify/charter/config.yml` | Registry path/type and the `distributed_sub_constitutions` flag |
| State | `.specify/charter/state.yml` | Selected fragments, sub-constitutions, distributed sub-constitutions, and local constitution |
| Snapshots | `.specify/charter/snapshots/` | Saved fragment versions for change detection |
| Backups | `.specify/charter/backups/` | Constitution backups before recomposition |
| Registry cache | `.specify/charter/.cache/registry/` | Cloned git registry (gitignored) |

## Documentation

- [Usage Guide](docs/usage.md) — detailed usage instructions
- [Registry Setup](docs/registry-setup.md) — how to create and maintain a registry
- [Commands Reference](docs/commands.md) — full command documentation
- [Architecture](docs/architecture.md) — design decisions and data flow

## Compatibility

- Spec Kit: >= 0.11.9
- Git: optional (required only for git-based registries)
- OS: Linux, macOS, Windows (via Git Bash / WSL)

## License

MIT — see [LICENSE](LICENSE)
