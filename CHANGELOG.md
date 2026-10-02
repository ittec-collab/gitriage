# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Hours estimation now uses a weighted formula:
  `hours = 0.3×(days×5) + 0.2×(commits×1.5) + 0.5×(lines/500)`
- Hours and payment columns display single values (no ranges)
- Minimum hour floor reduced from 4 to 1

### Fixed
- PR detection now catches squash merges (`Title (#123)`)
- Revert detection now catches `revert:` prefix (case-insensitive)


## [2.0.0] - 2026-10-02

### Added
- Date range filtering (`--since`, `--until`)
- Author filtering (`--author`)
- Automatic `.mailmap` support
- Commit type analysis (feat/fix/docs/refactor/chore)
- Language detection from file extensions
- PR and revert detection
- Work pattern analysis (weekdays, hours)
- Markdown output format
- Privacy flags: `--anonymize`, `--redact-emails`
- `--include-merges` option

### Changed
- Renamed project from `git-report` to `gitriage`
- Improved HTML layout with richer author cards
- Better number formatting

### Fixed
- `set -e` bailout on `[ ... ] && ...` patterns
- `grep -oP` failure on authors with no matching commits

## [1.0.0] - 2026-10-01

### Added
- Initial release
- HTML, JSON, CSV, text output formats
- Configurable rate and currency
- Payment estimation
