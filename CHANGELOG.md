# Changelog

All notable changes to the Charter extension will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
