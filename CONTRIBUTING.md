# Contributing to gitriage

Thanks for your interest in improving gitriage! This document explains
how to report bugs, propose features, and submit pull requests.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Features](#suggesting-features)
- [Development Setup](#development-setup)
- [Coding Guidelines](#coding-guidelines)
- [Commit Message Convention](#commit-message-convention)
- [Submitting a Pull Request](#submitting-a-pull-request)
- [Testing](#testing)
- [License](#license)

---

## Code of Conduct

Be respectful, constructive, and patient. We're all here to build a
useful tool. Harassment, personal attacks, and dismissive behavior
are not welcome.

---

## Reporting Bugs

Before opening an issue, please:

1. **Search existing issues** — your bug may already be reported.
2. **Update to the latest version** — check `gitriage --version`.
3. **Reproduce on a small repo** — if possible, use a minimal example.

When opening an issue, include:

- **Environment**: OS, bash version (`bash --version`), git version
- **Command**: the exact command you ran
- **Expected**: what you thought would happen
- **Actual**: what actually happened
- **Output**: full error message, if any

Example:

```
OS: Ubuntu 24.04
Bash: 5.2.21
Git: 2.43.0
Command: ./gitriage.sh --rate 100 --currency EUR
Expected: HTML report generated
Actual: "Not a git repository: ." error
```

---

## Suggesting Features

Feature requests are welcome. Please describe:

- **The problem** you're trying to solve (not just the solution)
- **Your use case** — who benefits and how
- **Alternatives** you've considered

Keep in mind the project's principles:

- **Zero external dependencies** (bash, git, awk, sed, grep only)
- **Single-file friendly** (no build step)
- **Fast on large repos**
- **Portable** (Linux, macOS, WSL)

---

## Development Setup

```bash
git clone https://github.com/yourname/gitriage.git
cd gitriage
chmod +x gitriage.sh
```

Requirements for development:

- Bash 4.0+
- Git 2.x+
- `shellcheck` (for linting)
- `awk`, `sed`, `grep`

Install `shellcheck`:

```bash
# Debian/Ubuntu
sudo apt install shellcheck

# Fedora
sudo dnf install ShellCheck

# macOS
brew install shellcheck
```

---

## Coding Guidelines

### Bash style

- **2-space indent**, no tabs
- **Quote everything**: `"$var"`, not `$var`
- **Use `[[ ]]`** for conditionals, not `[ ]`
- **Use `$()`** for command substitution, not backticks
- **Prefer `if ...; then ...; fi`** over `[ ... ] && ...` (breaks under `set -e`)
- **Declare locals** in functions: `local x=...`
- **No useless `cat`**: use `cmd < file`, not `cat file | cmd`

### Functions

- Keep functions focused on one task
- Use descriptive names: `write_html_report`, not `whr`
- Document complex logic with short comments

### Compatibility

- Must work with **bash 4.0+** (associative arrays)
- No GNU-specific flags unless guarded (`grep -P` is used — document it)
- macOS: `md5sum` is not available — `md5` is used as fallback

### Variables

- **Uppercase** for globals/constants: `RATE`, `HOURS_PER_COMMIT`
- **lowercase** for locals: `net`, `hours`, `share`
- `AUTHOR_*` prefix for per-author associative arrays

---

## Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

| Type | When to use |
|---|---|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code change without behavior change |
| `perf` | Performance improvement |
| `test` | Adding or fixing tests |
| `chore` | Maintenance (deps, config, tooling) |
| `ci` | CI/CD changes |
| `style` | Formatting, whitespace |

### Examples

```
feat: add --since and --until date filters
fix: prevent crash on authors with no commits
docs: update README for v2.1.0
refactor: extract hours calculation into function
```

Keep the subject **under 72 characters**, use **imperative mood**
("add", not "added"), and **no period** at the end.

For breaking changes, add `!` after the type: `feat!: drop --hours-low`.

---

## Submitting a Pull Request

1. **Fork** the repository
2. **Create a branch**:
   ```bash
   git checkout -b feature/my-feature
   ```
3. **Make changes** following the guidelines above
4. **Lint**:
   ```bash
   shellcheck -x -S warning gitriage.sh gitriage.lib.sh
   ```
5. **Test** on a real repository:
   ```bash
   ./gitriage.sh --dir /path/to/repo
   ./gitriage.sh --dir /path/to/repo --format text
   ./gitriage.sh --dir /path/to/repo --format json
   ./gitriage.sh --dir /path/to/repo --format csv
   ./gitriage.sh --dir /path/to/repo --format markdown
   ```
6. **Commit** with a conventional message
7. **Push** and open the PR

### PR checklist

- [ ] Code follows the style guide
- [ ] `shellcheck` passes with no warnings
- [ ] Tested on a real repository
- [ ] README/CHANGELOG updated if behavior changed
- [ ] Commit messages follow Conventional Commits

---

## Testing

There is no automated test suite yet — test manually:

```bash
# Basic
./gitriage.sh --dir /path/to/repo

# Filters
./gitriage.sh --dir /path/to/repo --since 2026-01-01
./gitriage.sh --dir /path/to/repo --author "Jane Doe"

# Formats
for fmt in html json csv markdown text; do
  ./gitriage.sh --dir /path/to/repo -f "$fmt" > /tmp/out.$fmt
  echo "$fmt: $(wc -c < /tmp/out.$fmt) bytes"
done

# Privacy
./gitriage.sh --dir /path/to/repo --anonymize -o /tmp/anon.html
./gitriage.sh --dir /path/to/repo --redact-emails -o /tmp/redacted.html

# Edge cases
./gitriage.sh --dir /tmp/empty-repo   # should fail gracefully
./gitriage.sh --rate 0                # should produce zero payments
```

---

## License

By contributing, you agree that your contributions will be licensed
under the MIT License — see [LICENSE](LICENSE).
