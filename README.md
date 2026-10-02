<div align="center">

# gitriage

**Git contribution triage and reporting tool**

Analyze git history and generate rich, styled reports with commit types,
language breakdown, work patterns, PR detection, payment estimation, and more.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/bash-4.0%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-linux%20%7C%20macOS-lightgrey.svg)](#requirements)
[![Version](https://img.shields.io/badge/version-2.1.0-orange.svg)](CHANGELOG.md)

</div>

---

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Options](#options)
- [Output Formats](#output-formats)
- [Examples](#examples)
- [Author Identity & .mailmap](#author-identity--mailmap)
- [Privacy](#privacy)
- [How It Works](#how-it-works)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- **Multi-format output** — HTML, JSON, CSV, Markdown, plain text
- **Rich HTML report** — dark theme, responsive, zero external dependencies
- **Date filtering** — `--since` / `--until` for periodic reports
- **Author filtering** — focus on a single contributor
- **`.mailmap` support** — automatically merges duplicate identities
- **Commit type analysis** — feat/fix/docs/refactor/chore breakdown
- **Language detection** — top file extensions per author
- **PR & revert detection** — from merge and revert message patterns
- **Work patterns** — top weekdays and hours per contributor
- **Payment estimation** — configurable rate and currency
- **Privacy controls** — `--anonymize` and `--redact-emails`
- **Works on any git host** — GitHub, GitLab, Bitbucket, Gitea, local repos

---

## Requirements

- **Bash** 4.0 or later (for associative arrays)
- **Git** 2.x or later
- **awk**, **sed**, **grep** (standard on Linux and macOS)

No Python, Node, or any runtime dependencies.

### Tested on

| Platform | Status |
|---|---|
| Linux (Ubuntu, Debian, Fedora, Arch) | ✅ |
| macOS (Intel & Apple Silicon) | ✅ |
| WSL2 | ✅ |

> **Note:** macOS ships with bash 3.2 by default. Install a newer bash via
> Homebrew (`brew install bash`) before running `gitriage`.

---

## Installation

### Option 1: Manual (recommended)

```bash
git clone https://github.com/yourname/gitriage.git
cd gitriage
chmod +x gitriage.sh
```

Run from anywhere:

```bash
/path/to/gitriage/gitriage.sh --dir /path/to/repo
```

### Option 2: Makefile

```bash
cd gitriage
sudo make install
```

This installs:

- `gitriage` binary to `/usr/local/bin/`
- library and CSS to `/usr/local/share/gitriage/`

Then run:

```bash
gitriage --help
```

Uninstall:

```bash
sudo make uninstall
```

### Option 3: Add to PATH

```bash
echo 'export PATH="$HOME/gitriage:$PATH"' >> ~/.bashrc
source ~/.bashrc
gitriage.sh --help
```

---

## Quick Start

```bash
# Run on the current repository with default settings
./gitriage.sh

# Open the generated report
xdg-open report.html      # Linux
open report.html          # macOS
start report.html         # Windows (WSL)
```

That's it. The tool generates `report.html` and `report.css` next to the
script, and you're ready to inspect contributor activity.

---

## Usage

```
gitriage [OPTIONS]
```

### Filtering

| Flag | Description |
|---|---|
| `-d, --dir <PATH>` | Path to git repository (default: `.`) |
| `--since <DATE>` | Only commits after this date (e.g. `2026-01-01`) |
| `--until <DATE>` | Only commits before this date |
| `--author <NAME>` | Filter to a single author (case-insensitive) |
| `--include-merges` | Include merge commits (default: excluded) |

### Rates & Estimation

| Flag | Description |
|---|---|
| `-r, --rate <NUMBER>` | Hourly rate (default: `50`) |
| `-c, --currency <LABEL>` | Currency label, e.g. `USD`, `EUR`, `BTC` (default: `USD`) |

**Hours estimation:** `hours = commits × HOURS_PER_COMMIT` (default `3`).
Edit `HOURS_PER_COMMIT` at the top of `gitriage.sh` to tune the multiplier.

### Output

| Flag | Description |
|---|---|
| `-f, --format <FMT>` | `html`, `json`, `csv`, `markdown`, `text` (default: `html`) |
| `-o, --output <FILE>` | Output file (default: `report.html`) |
| `--css <FILE>` | CSS file path (default: `report.css`) |
| `--top-paths <N>` | Top changed paths per author (default: `8`) |
| `--top-commits <N>` | Recent commits per author (default: `15`) |

### Privacy

| Flag | Description |
|---|---|
| `--anonymize` | Hash author names and strip file paths |
| `--redact-emails` | Remove email addresses from author names |

### Misc

| Flag | Description |
|---|---|
| `-h, --help` | Show help |
| `-v, --version` | Show version |

---

## Output Formats

### HTML (default)

A styled, responsive, single-page report with:

- Summary stat cards (contributors, commits, lines, PRs, reverts)
- Contribution table (commits, added, deleted, net, files, days)
- Share & payment estimate with distribution bars
- Commit-type and language tags per author
- Work pattern analysis (top weekdays and hours)
- Top changed paths per author
- Recent commits per author

CSS is written to a separate file so you can theme it easily.

### JSON

Structured output for piping into other tools:

```bash
./gitriage.sh --format json | jq '.authors[] | {name, commits, net}'
```

### CSV

Excel/Google Sheets friendly:

```bash
./gitriage.sh --format csv > report.csv
```

### Markdown

Perfect for pull request comments or project docs:

```bash
./gitriage.sh --format markdown > CONTRIBUTORS.md
```

### Text

Fast terminal-friendly output:

```bash
./gitriage.sh --format text
```

---

## Examples

### Monthly report

```bash
./gitriage.sh --since 2026-09-01 --until 2026-09-30
```

### Single author, markdown output

```bash
./gitriage.sh --author "Jane Doe" --format markdown
```

### Custom rate and currency

```bash
./gitriage.sh --rate 75 --currency EUR
```

### Custom output filenames

```bash
./gitriage.sh -o team-october.html --css team-october.css
```

### Anonymized, shareable report

```bash
./gitriage.sh --anonymize -o public-report.html
```

### Analyze a different repository

```bash
./gitriage.sh --dir ~/projects/other-repo
```

### Combine filters

```bash
./gitriage.sh \
  --since 2026-01-01 \
  --until 2026-06-30 \
  --author "Jane" \
  --rate 100 \
  --currency USD \
  -o q2-report.html
```

### Pipe JSON into jq

```bash
# Total payment across the team
./gitriage.sh -f json | jq '[.authors[].est_payment] | add'

# Sort authors by commits
./gitriage.sh -f json | jq -r '.authors | sort_by(.commits) | reverse[] | "\(.name): \(.commits)"'
```

---

## Author Identity & .mailmap

Git identifies authors by **name + email**. If the same person commits with
different emails (work vs personal), they appear as separate contributors.

To merge them, create a `.mailmap` file at the repository root:

```
Jane Doe <jane@work.com> <jane@personal.com>
Jane Doe <jane@work.com> Jane Doe <jane.doe@old.com>
```

`gitriage` picks up `.mailmap` automatically — no flag needed.

**Verify your mailmap works:**

```bash
git shortlog -sne --all | head
```

After adding `.mailmap`, the duplicate entries should collapse into one.

---

## Privacy

Two flags for sanitizing reports before sharing:

### `--anonymize`

- Replaces author names with `anon-<hash>`
- Strips email addresses from author strings

### `--redact-emails`

- Keeps author names but removes `<email>` parts

Use `--anonymize` for public reports, `--redact-emails` for internal
reports that shouldn't leak contact info.

---

## How It Works

1. **Collect** — runs `git log` on all branches (excluding merges by default)
2. **Parse** — extracts commits, dates, authors, file paths via `git log --numstat`
3. **Filter** — excludes generated files (lockfiles, coverage, minified, binaries)
4. **Aggregate** — builds per-author maps of commits, lines, files, types, languages
5. **Estimate** — computes share and payment (hours = commits × HOURS_PER_COMMIT)
6. **Render** — writes the chosen output format

> **Time estimation is approximate.** Git does not record time spent — only
> commit timestamps. The tool assumes `HOURS_PER_COMMIT` (default 3) hours
> of work per commit, which is a rough proxy and can skew if contributors
> make many small commits or few large ones. Use a time tracker for
> precise billing.

### Excluded files

By default, `gitriage` excludes these from line counts:

- Lockfiles: `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `uv.lock`, `poetry.lock`
- Generated: `requirements.txt`, `.coverage`
- Minified: `*.min.js`, `*.min.css`
- Binaries and assets: `*.svg`, `*.png`, `*.jpg`, `*.ico`, `*.woff`, `*.mmdb`, `*.pyc`

To customize, edit `EXCLUDE_REGEX` in `gitriage.sh`.

---

## Project Structure

```
gitriage/
├── gitriage.sh          # Main script — parsing, data collection, CLI
├── gitriage.lib.sh      # Output writers (HTML, JSON, CSV, Markdown, text)
├── report.css           # Stylesheet for HTML output
├── README.md            # This file
├── LICENSE              # MIT
├── CHANGELOG.md         # Version history
├── CONTRIBUTING.md      # Contribution guidelines
├── Makefile             # Install / uninstall / lint / test targets
├── .gitignore
├── .editorconfig
└── .github/
    └── workflows/
        └── shellcheck.yml
```

After a run on a repository, the following files appear next to the target
repository (not in `gitriage/`):

```
report.html      # the report
report.css       # the stylesheet
```

---

## Contributing

Contributions welcome. Please:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Run `make lint` (requires `shellcheck`)
4. Run `make test` on a real repository
5. Commit with a clear message
6. Open a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for full guidelines.

### Development setup

```bash
git clone https://github.com/yourname/gitriage.git
cd gitriage
chmod +x gitriage.sh

# Lint
make lint

# Test
make test
```

---

## License

[MIT](LICENSE) © 2026 gitriage contributors

---

<div align="center">

**If you find this useful, give it a ⭐**

</div>