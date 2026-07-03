# Registry Setup Guide

A charter registry is a collection of constitution fragments that can be shared
across multiple Spec Kit projects. This guide explains how to create and maintain
a registry.

## Registry Structure

```
<registry_root>/
├── manifest.yml                    # Required
├── fragments/                      # Required (can be empty)
│   ├── global/
│   │   ├── compliance.md
│   │   ├── security.md
│   │   └── code-quality.md
│   ├── domains/
│   │   ├── finance/
│   │   │   └── regulations.md
│   │   └── ecommerce/
│   │       └── checkout.md
│   └── languages/
│       ├── typescript/
│       │   └── standards.md
│       └── python/
│           └── style.md
└── sub-constitutions/              # Optional
    ├── package-auth.md
    └── package-api.md
```

## Manifest

The `manifest.yml` file is required and describes the registry:

```yaml
version: 1
name: "My Organization Charter Registry"
mandatory_fragments:
  - "global/compliance"
  - "global/security"
recommended_fragments:
  - "global/code-quality"
```

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `version` | Yes | Manifest schema version (currently `1`) |
| `name` | Yes | Human-readable registry name |
| `mandatory_fragments` | No | Fragments that must be included in every project |
| `recommended_fragments` | No | Fragments suggested by default but deselectable |

### Fragment References

Fragment references in `mandatory_fragments` and `recommended_fragments` use the
relative path within `fragments/` without the `.md` extension:

- `global/compliance` → `fragments/global/compliance.md`
- `languages/typescript/standards` → `fragments/languages/typescript/standards.md`

## Writing Fragments

Each fragment is a Markdown file containing constitution rules for a specific
topic.

### Best Practices

1. **Be specific and actionable** — use MUST/SHOULD/MAY language
2. **Keep fragments focused** — one topic per fragment
3. **Avoid overlap** — don't repeat rules across fragments
4. **Use headers** — structure content with Markdown headers
5. **Stay concise** — the AI agent processes the entire constitution

### Example Fragment

```markdown
# TypeScript Standards

## Type Safety

- Strict mode MUST be enabled in tsconfig.json
- `any` type usage MUST be justified with a code comment
- Prefer interfaces over type aliases for object shapes

## Code Style

- ESLint with the organization's shared config MUST be used
- Maximum function length: 50 lines
- Maximum file length: 300 lines

## Dependencies

- Pin exact versions in package.json
- All new dependencies MUST be reviewed and approved
- `npm audit` MUST pass in CI pipeline
```

## Sub-Constitutions

Sub-constitutions are designed for monorepo setups where specific packages have
additional rules.

### Location

Place sub-constitutions in the `sub-constitutions/` directory at the registry
root (NOT inside `fragments/`):

```
<registry_root>/
└── sub-constitutions/
    ├── package-auth.md
    └── package-api.md
```

### Content

Sub-constitutions are regular Markdown files. When composed, Charter
automatically adds a scoping prefix:

```markdown
WHEN WORKING ON <package-name>, FOLLOW THESE INSTRUCTIONS:
```

This tells the AI agent to apply these rules only when working on that specific
package.

### Naming

The file name (without `.md`) becomes the sub-constitution name used in the
selection list and section markers.

## Hosting

### Local Directory

The simplest setup — place the registry in a directory accessible to all
projects:

```
# In the project
registry: ".charter"                      # Relative to project root
registry: "/shared/charter-registry"      # Absolute path
registry: "../shared-charter"             # Relative to project root
```

Best for:
- Single-developer setups
- Monorepos (registry inside the repo)
- Quick prototyping

### Git Repository

Host the registry as a git repository for version control and team sharing:

```
# SSH
registry: "git@github.com:my-org/charter-registry.git"

# HTTPS
registry: "https://github.com/my-org/charter-registry"
```

Best for:
- Multi-repo organizations
- Version-controlled fragment changes
- Team collaboration with review workflows

### Authentication

Charter uses the local system's git credentials:

- **SSH**: Uses your SSH key (`~/.ssh/id_*`)
- **HTTPS**: Uses git credential helpers (e.g., `git credential-manager`)
- **Private repos**: Work automatically if your local git can access them

No additional authentication configuration is needed.

## Versioning Strategy

### Fragment Versioning

Fragments don't have individual version numbers. Instead:

1. Use git tags/releases for the registry as a whole
2. Document changes in a registry CHANGELOG
3. Charter's snapshot mechanism detects when fragments change between composes

### Registry Versioning

The `version` field in `manifest.yml` tracks the schema version, not the content
version. Use git tags for content versioning:

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Maintenance

### Adding a Fragment

1. Create the Markdown file in the appropriate `fragments/` subdirectory
2. Optionally add it to `recommended_fragments` in `manifest.yml`
3. Commit and push
4. Projects run `/speckit.charter.config` to see the new fragment

### Updating a Fragment

1. Edit the fragment file
2. Commit and push
3. Projects run `/speckit.charter.compose update` to get the new version

### Removing a Fragment

1. Remove the file from `fragments/`
2. Remove from `mandatory_fragments` or `recommended_fragments` in `manifest.yml`
3. Commit and push
4. Projects run `/speckit.charter.config` to update their selection

### Making a Fragment Mandatory

Add its path to `mandatory_fragments` in `manifest.yml`:

```yaml
mandatory_fragments:
  - "global/compliance"
  - "global/security"
  - "global/new-mandatory-rule"     # Added
```

Projects must re-run `/speckit.charter.config` — the fragment will appear as
`(MANDATORY)` and cannot be deselected.
