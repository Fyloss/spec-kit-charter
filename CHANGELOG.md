# Changelog

All notable changes to the Charter extension will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
- `/speckit.charter.compose` now runs an inline configuration flow when no
  charter configuration exists yet (`.specify/charter/state.yml` missing).
  Instead of erroring out, it prompts for the registry value and the fragment
  selection, displays the composition summary without asking for confirmation,
  reminds the user that `/speckit.charter.restore` can undo the change, and
  proceeds automatically to generate the constitution — letting users configure
  and compose in a single step.

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
- `/speckit.charter.config` no longer asks for a yes/no/cancel confirmation
  after the composition summary. It now only requests the registry value and the
  fragment selection; the summary is shown for information and the configuration
  is saved automatically.
- `/speckit.charter.config` now reminds the user that `/speckit.charter.restore`
  can restore the previous constitution if the generated one is not valid.

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
