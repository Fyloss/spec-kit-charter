# Usage Guide

This guide covers the day-to-day usage of the Charter extension for composing
project constitutions from shared fragment registries.

## Prerequisites

- Spec Kit installed and initialized (`specify init`)
- A charter registry accessible (local directory or git repository)
- The charter extension installed (`specify extension add charter`)

## First-Time Setup

### 1. Configure the Registry

Run the configuration command:

```
/speckit.charter.config
```

You'll be prompted for:

1. **Registry location** — defaults to `.charter` relative to the project root.
   Accepts:
   - Relative path: `.charter`, `../shared-charter`
   - Absolute path: `/opt/charter-registry`
   - Git SSH URL: `git@github.com:my-org/charter-registry.git`
   - Git HTTPS URL: `https://github.com/my-org/charter-registry`

2. **Fragment selection** — choose which fragments to include:
   - Mandatory fragments are always included (cannot be deselected)
   - Recommended fragments are pre-selected but can be removed
   - Regular fragments and sub-constitutions are optional

### 2. Review the Summary

After selecting fragments, you'll see a composition summary shown for
information — there is **no confirmation prompt**. The command only asks for the
registry value, the distributed-sub-constitutions enable choice, and the
fragment selection:

```
========= FINAL PROJECT CONSTITUTION =========
[FRAGMENT] |R| global/compliance
[FRAGMENT] |R| global/code-quality
[FRAGMENT] |R| languages/typescript/standards
[SUB-CONSTITUTION] |R| package-auth
[SUB-CONSTITUTION] |L| packages/back
[OTHER] |L| <CURRENT PROJECT CONSTITUTION>
===============================================

Sources:
[R]: Registry
[L]: Local
```

The configuration is saved automatically. If the generated constitution later
turns out to be invalid, run `/speckit.charter.restore` to restore the previous
constitution.

### 3. Compose the Constitution

```
/speckit.charter.compose
```

This generates the final constitution file at `.specify/memory/constitution.md`
with section markers for future updates.

### Quick Setup (Config + Compose in One Step)

If you run `/speckit.charter.compose` **before** ever running
`/speckit.charter.config`, Charter detects that no configuration exists
(`.specify/charter/state.yml` is missing) and runs the configuration inline
before composing:

```
/speckit.charter.compose
```

The combined flow:

1. **Asks for the registry value** (proposing the current/default `.charter`) —
   a required input, not silently defaulted.
2. Prompts for **fragment selection** — the second input.
3. Displays the composition summary **for information only — no confirmation is
   asked**.
4. Proceeds automatically to generate the constitution.

Before composing, it reminds you that `/speckit.charter.restore` can restore the
previous constitution if the generated one is not valid.

This is equivalent to running `/speckit.charter.config` followed by
`/speckit.charter.compose`, but in a single step. Once the state file exists,
`/speckit.charter.compose` behaves normally (update/recreation/override modes).

## Updating Fragments

### Update All Fragments

When the registry has been updated with new fragment versions:

```
/speckit.charter.compose update
```

This fetches the latest versions from the registry and regenerates the
constitution.

### Update a Single Fragment

To update only one fragment without touching others:

```
/speckit.charter.compose update languages/typescript/standards
```

### Handling Local Modifications

If you've manually edited fragment sections in the constitution, Charter will
detect this during recomposition:

```
⚠️ WARNING: The following sections have been modified since the last composition:
  - global/code-quality

Recomposing will OVERWRITE these modifications with the registry versions.
```

You can:
- Confirm to overwrite
- Cancel and update individual fragments instead
- Port your changes to the registry fragment first

## Removing Fragments

To remove a fragment from the composition:

```
/speckit.charter.remove languages/typescript/standards
```

This removes the fragment from the state and regenerates the constitution.
Mandatory fragments cannot be removed.

## Changing the Registry

To switch to a different registry or update the registry URL:

```
/speckit.charter.config
```

Re-running the config command lets you change the registry and re-select
fragments.

## Preserving Project-Specific Rules

If your project has an existing constitution before installing Charter, the
`<CURRENT PROJECT CONSTITUTION>` option in the selection list lets you preserve
those rules. They are placed in a `<!-- [PROJECT SPECIFIC] SECTION -->` section
at the end of the composed constitution.

The Spec Kit metadata (Sync Impact Report comment, version/ratified/amended
line) is automatically stripped from the preserved content — these are managed
by the `/speckit.constitution` command.

## Working with Monorepos

Charter offers two ways to scope rules to packages in a monorepo. You can use
either or both.

### Registry sub-constitutions (centralized)

Add sub-constitutions to the registry's `sub-constitutions/` directory:

```
.charter/
└── sub-constitutions/
    ├── package-auth.md
    ├── package-api.md
    └── package-ui.md
```

Each sub-constitution is wrapped with a scoping prefix in the final constitution:

```markdown
<!-- [package-auth] SECTION -->
WHEN WORKING ON package-auth, FOLLOW THESE INSTRUCTIONS:
<content of package-auth.md>
```

Use this when you prefer to keep package rules **centrally in the registry**.

### Distributed sub-constitutions (in-tree)

Let each package own its rules next to its code, in a
`<package>/.charter/constitution.md` file:

```
packages/
├── front/
│   ├── .charter/
│   │   └── constitution.md   # front's rules
│   └── ...
└── back/
    ├── .charter/
    │   └── constitution.md   # back's rules
    └── ...
```

Enable the feature during `/speckit.charter.config`:

1. After choosing the registry, Charter scans for
   `<package>/.charter/constitution.md` files (recursive, up to 5 package
   levels) and lists any it finds:

   ```
   Distributed sub-constitutions found:
     packages/front
     packages/back

   Enable distributed sub-constitutions? (yes/no) [default: no]
   ```

2. Answer `yes` to enable. The detected packages then appear in the selection
   list tagged `|L|` and marked `(detected)`; select the ones you want.

In the composed constitution each becomes a scoped section keyed by its package
path:

```markdown
<!-- [packages/back] SECTION -->
WHEN WORKING ON packages/back, FOLLOW THESE INSTRUCTIONS:
<content of packages/back/.charter/constitution.md>
```

**Only `.charter/constitution.md` files are detected.** A package's own Spec Kit
constitution (`<package>/.specify/memory/constitution.md`) and any bare
`<package>/constitution.md` are ignored on purpose — this prevents conflicts when
Spec Kit is used both at the monorepo root and inside individual packages.

### Keeping sub-constitutions up to date (cacheless)

Both registry and distributed sub-constitutions are **cacheless**: a plain
`/speckit.charter.compose` always re-reads their latest content. A package owner
can edit `packages/back/.charter/constitution.md` and simply run:

```
/speckit.charter.compose
```

This refreshes every sub-constitution (registry and distributed) while leaving
fragments on their pinned snapshots — no `update` argument needed. To also
refresh fragments, use `/speckit.charter.compose update`.

## Size Management

Charter warns when the total composed constitution exceeds 32 KiB:

```
⚠️ The total constitution length will exceed 32 KiB:
Critical information may be overlooked by the agent, and unnecessary tokens
increase inference cost.
```

To reduce size:
- Remove non-essential fragments
- Consolidate related fragments in the registry
- Keep fragment content concise and actionable
