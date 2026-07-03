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
registry value and the fragment selection:

```
========= FINAL PROJECT CONSTITUTION =========
------- COMPOSED --------------
FRAGMENT global/compliance
FRAGMENT global/code-quality
FRAGMENT languages/typescript/standards
SUB-CONSTITUTION package-auth
------- PROJECT SPECIFIC ------
<CURRENT PROJECT CONSTITUTION>
===============================================
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

For monorepo projects, add sub-constitutions to the registry:

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

This tells the AI agent to apply those rules only when working on that specific
package.

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
