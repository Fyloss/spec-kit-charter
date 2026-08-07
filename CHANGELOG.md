# Changelog

All notable changes to the Charter extension will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **BREAKING: Registry sub-constitution filenames now use `_` (underscore) as
  the path separator instead of `-` (dash).** The `WHEN WORKING ON` path is now
  derived by replacing `_` with `/` in the filename stem, leaving `-` free for
  readability within a segment (e.g. `package_auth-gateway.md` →
  `WHEN WORKING ON package/auth-gateway`). Previously `packages-auth.md` mapped
  to `packages/auth`; rename existing registry sub-constitution files to use
  `_` instead of `-` between path segments (e.g. `packages-auth.md` →
  `packages_auth.md`).

## [0.5.1] - 2026-08-03

### Fixed

- `extension.yml` still declared version `0.1.0`, well behind the actual
  released state. Bumped to `0.5.1` and updated the GitHub release link in
  README.md to match.

## [0.5.0] - 2026-08-03

### Added

- **Heading normalization in compose.** Each section's top heading is
  automatically shifted to H2 in the final constitution, preserving internal
  relative depth. A fragment authored with `# Title` and a sub-constitution with
  `#### Title` both produce `## Title` in the composed output. Registry files,
  snapshots, and distributed package files are never modified — only the
  assembled constitution content is normalized.

- **Typed section markers.** Section markers now carry a type tag so the origin
  of each section is identifiable at a glance in the composed constitution:
  - `<!-- [F] global/compliance SECTION -->` — fragment
  - `<!-- [SC] sub-constitutions/packages-auth SECTION -->` — registry sub-constitution
  - `<!-- [DSC] packages/auth/.charter/constitution SECTION -->` — distributed sub-constitution
  - `<!-- [PS] PROJECT SPECIFIC SECTION -->` — project-specific local content

  `constitution-parse.sh` and `constitution-extract.sh` remain backwards-compatible
  with the legacy `<!-- [NAME] SECTION -->` format so existing constitutions can
  still be overridden or updated before recomposition.

- **Heading-agnostic snapshot comparison.** `snapshot-compare.sh` now strips
  leading `#` characters from heading lines before diffing, preventing false
  "modified" warnings caused by the auto-indent applied during compose. Real
  content changes are still detected correctly.

- **Improved sub-constitution prefix lines.**
  - Registry sub-constitutions: the `WHEN WORKING ON` path is now derived from
    the filename by replacing `-` with `/` (e.g. `packages-auth.md` → `WHEN WORKING ON packages/auth`).
  - Distributed sub-constitutions: the `WHEN WORKING ON` path is the package
    root (e.g. `packages/auth`), not the full `.charter/constitution` path.

- **New state ID formats** for sub-constitutions:
  - Registry sub-constitutions are stored as `sub-constitutions/<stem>` (e.g.
    `sub-constitutions/packages-auth`) to encode their type.
  - Distributed sub-constitutions are stored as `<pkg>/.charter/constitution`
    (e.g. `packages/auth/.charter/constitution`) to encode the full source path.

### Fixed

- Heading normalization and snapshot comparison now track fenced code blocks
  (` ``` ` / `~~~`) so `#`-prefixed shell/Python/YAML comments and shebangs
  inside code samples are never mistaken for Markdown headings — previously
  this could mis-indent fragment content or hide a real content change behind
  a false "unmodified" snapshot comparison.
- Replaced the GNU-only `sed 's/^#\+.../'` heading-stripping in
  `snapshot-compare.sh` with a portable `awk` implementation, since the `\+`
  extension silently becomes a no-op on BSD/macOS `sed`.

### Changed

- **BREAKING:** Existing composed constitutions use the old
  `<!-- [NAME] SECTION -->` marker format. Run `/speckit.charter.compose` once
  to regenerate the constitution with the new typed markers. Back up first if
  needed — `/speckit.charter.restore` can revert the change.
- **BREAKING:** `state.yml` sub-constitution ID format changed. If you have an
  existing `state.yml`, re-run `/speckit.charter.config` to regenerate it with
  the new IDs, or update it manually: change `- packages-auth` under
  `sub_constitutions` to `- sub-constitutions/packages-auth`, and change
  `- packages/back` under `distributed_sub_constitutions` to
  `- packages/back/.charter/constitution`.

## [0.4.1] - 2026-07-22

### Added

- **Distributed sub-constitutions** for monorepos. Charter can now detect
  `<package>/.charter/constitution.md` files in monorepo packages (recursive, up
  to 5 package levels) during configuration and offer them for selection. The
  feature is opt-in via the `distributed_sub_constitutions` flag in `config.yml`
  (default `false`); selected package paths are stored in the
  `distributed_sub_constitutions` list in `state.yml`. Each selected package is
  composed as a scoped section keyed by its package path
  (`<!-- [packages/back] SECTION -->` + `WHEN WORKING ON packages/back, ...`).
  Detection only matches files inside a `.charter` folder, deliberately ignoring
  a package's own Spec Kit constitution
  (`<package>/.specify/memory/constitution.md`) to avoid conflicts when Spec Kit
  is used both at the monorepo root and inside packages.
- `/speckit.charter.add` and `/speckit.charter.remove` now support distributed
  sub-constitutions (referenced by package path, e.g. `packages/back`).
- New scripts: `distributed-detect.sh`, `distributed-read.sh`, and
  `config-distributed-set.sh`.

### Changed

- **Sub-constitutions are now cacheless.** Registry sub-constitutions and
  distributed sub-constitutions are re-read fresh from their source on every
  `/speckit.charter.compose`, so a plain compose refreshes all of them without an
  `update` step. Only fragments retain the snapshot / change-detection mechanism.
- The fragment selection list and composition summary now tag every item by
  source: `|R|` (registry) and `|L|` (local). The current project constitution is
  now grouped under `[OTHER]` and tagged `|L|`.
- The composition summary no longer uses the `------- COMPOSED -------` /
  `------- PROJECT SPECIFIC ------` separators; it lists each item as
  `[FRAGMENT] |R| <name>`, `[SUB-CONSTITUTION] |R|/|L| <name>`, or
  `[OTHER] |L| <CURRENT PROJECT CONSTITUTION>`, followed by a source legend.
- `config.yml` now includes the `distributed_sub_constitutions` flag; it is
  preserved across registry changes.

### Fixed

- Added path traversal validation (`validate_package_path` in
  `charter-common.sh`) for distributed package paths, applied in
  `compose-size-check.sh` and `constitution-validate-sections.sh`.
- Fixed missing executable permissions on the newly added
  `config-distributed-set.sh` and `distributed-detect.sh` scripts.

## [0.3.1] - 2026-07-03

### Fixed

- Removed the unused `config-template.yml` file and its stale reference in
  `tests/test_manifest.py`.

## [0.3.0] - 2026-07-03

### Added

- `/speckit.charter.compose` now runs an inline configuration flow when no
  charter configuration exists yet (`.specify/charter/state.yml` missing).
  Instead of erroring out, it prompts for the registry value and the fragment
  selection, displays the composition summary without asking for confirmation,
  reminds the user that `/speckit.charter.restore` can undo the change, and
  proceeds automatically to generate the constitution — letting users configure
  and compose in a single step.

### Changed

- `/speckit.charter.config` no longer asks for a yes/no/cancel confirmation
  after the composition summary. It now only requests the registry value and the
  fragment selection; the summary is shown for information and the configuration
  is saved automatically.
- `/speckit.charter.config` now reminds the user that `/speckit.charter.restore`
  can restore the previous constitution if the generated one is not valid.
- Charter commands now delegate to modular helper scripts (`backup-list.sh`,
  `backup-preview.sh`, `backup-restore.sh`, `constitution-validate-sections.sh`,
  `fragment-is-mandatory.sh`, `registry-default.sh`, `snapshot-detect-modified.sh`,
  `snapshot-list-missing.sh`, `state-check.sh`) instead of inline logic.

### Fixed

- The restoration reminder in the inline configuration flow is now shown at the
  correct step, after composition completes rather than before.
- Constitution sections are now separated by a trailing blank line, and section
  extraction trims trailing blank lines to avoid duplicated separators.

## [0.2.0] - 2026-07-02

### Changed

- **BREAKING:** Charter now stores all persistent data under `.specify/charter/`
  instead of `.specify/extensions/charter/`. The extension install directory is
  wiped by `specify extension update`/`remove` (only `*-config.yml` survives),
  which previously destroyed `state.yml`, `snapshots/`, and `backups/`. The new
  location lives outside the extension lifecycle and survives updates and
  `specify init --here --force`.
- Renamed the config file from `charter-config.yml` to `config.yml`.
- Renamed the registry cache from `.registry-cache/` to `.cache/registry/`.
- A `.specify/charter/.gitignore` is now generated automatically to exclude the
  disposable `.cache/` while keeping config, state, snapshots, and backups
  version-controlled.
- Removed the Spec Kit `config:` declaration from `extension.yml` (Charter reads
  its own config from `.specify/charter/config.yml`).

## [0.1.0] - 2026-06-30

### Added

- `/speckit.charter.config` command — configure registry and select fragments
- `/speckit.charter.compose` command — compose and generate constitution from fragments
- `/speckit.charter.remove` command — remove a fragment section
- Support for local directory registries
- Support for git repository registries (SSH and HTTPS)
- Fragment selection with mandatory, recommended, and optional categories
- Sub-constitution support for monorepo setups
- Local constitution preservation during composition
- Section-aware constitution structure with HTML comment delimiters
- Fragment snapshot management for change detection
- Constitution backup before recomposition
- Size warning when composed constitution exceeds 32 KiB
- Comprehensive shell scripts for registry operations
- Full test suite with fixtures
