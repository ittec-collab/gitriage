#!/usr/bin/env bash
# gitriage — Git repository contribution triage and reporting tool
# Analyzes git history and generates styled reports with rich insights.

set -euo pipefail

VERSION="2.1.0"
PROG_NAME="$(basename "$0")"
# Resolve symlinks so SCRIPT_DIR points to the real install location
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"

# ─── Defaults ────────────────────────────────────────────────────────
RATE=50
CURRENCY="USD"
# Hours per commit — the single knob to tune
HOURS_PER_COMMIT=3
FORMAT="html"
REPO="."
OUTPUT="report.html"
CSS_FILE="report.css"
TOP_PATHS=8
TOP_COMMITS=15
SINCE=""
UNTIL=""
AUTHOR_FILTER=""
INCLUDE_MERGES=false
ANONYMIZE=false
REDACT_EMAILS=false

EXCLUDE_REGEX='package-lock[.]json|yarn[.]lock|pnpm-lock[.]yaml|uv[.]lock|poetry[.]lock|requirements[.]txt$|[.]coverage$|[.]min[.](js|css)$|[.](svg|png|jpg|jpeg|gif|ico|mmdb|woff|woff2|ttf|pyc|lock)$'

# ─── Help ────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
${PROG_NAME} v${VERSION} — Git contribution triage and reporting tool

USAGE:
    ${PROG_NAME} [OPTIONS]

FILTERING:
    -d, --dir <PATH>           Git repository path (default: .)
        --since <DATE>         Only commits after this date (e.g. 2026-01-01)
        --until <DATE>         Only commits before this date
        --author <NAME>        Filter to a single author
        --include-merges       Include merge commits (default: excluded)

RATES & ESTIMATION:
    -r, --rate <NUMBER>        Hourly rate (default: ${RATE})
    -c, --currency <LABEL>     Currency label (default: ${CURRENCY})

OUTPUT:
    -f, --format <FMT>         html | json | csv | markdown | text (default: ${FORMAT})
    -o, --output <FILE>        Output file (default: ${OUTPUT})
        --css <FILE>           CSS file path (default: ${CSS_FILE})
        --top-paths <N>        Top changed paths per author (default: ${TOP_PATHS})
        --top-commits <N>      Recent commits per author (default: ${TOP_COMMITS})

PRIVACY:
        --anonymize            Strip author names, emails, and file paths
        --redact-emails        Only redact email addresses

MISC:
    -h, --help                 Show this help
    -v, --version              Show version

EXAMPLES:
    ${PROG_NAME}
    ${PROG_NAME} --rate 75 --currency EUR
    ${PROG_NAME} --since 2026-01-01 --until 2026-06-30
    ${PROG_NAME} --author "Jane Doe" --format markdown
    ${PROG_NAME} -r 100 -c USD -o team.html --css team.css
    ${PROG_NAME} --format json > report.json

EOF
  exit 0
}

# ─── Argument Parsing ────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--rate)          RATE="$2"; shift 2 ;;
    -c|--currency)      CURRENCY="$2"; shift 2 ;;
    -f|--format)        FORMAT="$2"; shift 2 ;;
    -d|--dir)           REPO="$2"; shift 2 ;;
    -o|--output)        OUTPUT="$2"; shift 2 ;;
    --css)              CSS_FILE="$2"; shift 2 ;;
    --top-paths)        TOP_PATHS="$2"; shift 2 ;;
    --top-commits)      TOP_COMMITS="$2"; shift 2 ;;
    --since)            SINCE="$2"; shift 2 ;;
    --until)            UNTIL="$2"; shift 2 ;;
    --author)           AUTHOR_FILTER="$2"; shift 2 ;;
    --include-merges)   INCLUDE_MERGES=true; shift ;;
    --anonymize)        ANONYMIZE=true; shift ;;
    --redact-emails)    REDACT_EMAILS=true; shift ;;
    -h|--help)          usage ;;
    -v|--version)       echo "${PROG_NAME} v${VERSION}"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done

# ─── Validate ────────────────────────────────────────────────────────
[ -d "$REPO/.git" ] || { echo "Not a git repository: $REPO" >&2; exit 1; }
command -v git >/dev/null || { echo "git not found" >&2; exit 1; }

cd "$REPO"

case "$FORMAT" in
  html|json|csv|markdown|text) ;;
  *) echo "Invalid format: $FORMAT" >&2; exit 1 ;;
esac

# ─── Build git log filter args ───────────────────────────────────────
GIT_FILTER=()
if [ "$INCLUDE_MERGES" = false ]; then
  GIT_FILTER+=(--no-merges)
fi
[ -n "$SINCE" ] && GIT_FILTER+=(--since="$SINCE")
[ -n "$UNTIL" ] && GIT_FILTER+=(--until="$UNTIL")

# ─── Data Collection ─────────────────────────────────────────────────
declare -A AUTHOR_NET AUTHOR_COMMITS AUTHOR_DAYS AUTHOR_FIRST AUTHOR_LAST
declare -A AUTHOR_FILES AUTHOR_ADD AUTHOR_DEL
declare -A AUTHOR_TYPES AUTHOR_LANGS AUTHOR_PRS AUTHOR_REVERTS
declare -A AUTHOR_WEEKDAY AUTHOR_HOUR AUTHOR_HOURS

TOTAL_COMMITS=0
TOTAL_NET=0
TOTAL_ADD=0
TOTAL_DEL=0
TOTAL_PRS=0
TOTAL_REVERTS=0
TOTAL_FILES=0

# Collect authors (respecting mailmap if present)
if [ -f .mailmap ]; then
  AUTHORS=$(git log "${GIT_FILTER[@]}" --format="%aN" --use-mailmap | sort -u)
else
  AUTHORS=$(git log "${GIT_FILTER[@]}" --format="%an" | sort -u)
fi

# Apply author filter
if [ -n "$AUTHOR_FILTER" ]; then
  AUTHORS=$(echo "$AUTHORS" | grep -i "$AUTHOR_FILTER" || true)
fi

while IFS= read -r author; do
  if [ -z "$author" ]; then continue; fi

  # Commit count
  commits=$(git log "${GIT_FILTER[@]}" --author="$author" --format="%H" | wc -l)
  if [ "$commits" -eq 0 ]; then continue; fi

  # Active days, first, last
  days=$(git log "${GIT_FILTER[@]}" --author="$author" --format="%ad" --date=short | sort -u | wc -l)
  first=$(git log "${GIT_FILTER[@]}" --author="$author" --format="%ad" --date=short | sort | head -1)
  last=$(git log "${GIT_FILTER[@]}" --author="$author" --format="%ad" --date=short | sort | tail -1)

  # Lines added/deleted/files (with exclusions)
  stats=$(git log "${GIT_FILTER[@]}" --author="$author" --pretty="AUTHOR:%an" --numstat \
    | awk -v ex="$EXCLUDE_REGEX" '
      /^AUTHOR:/ { next }
      /^[0-9]+\t[0-9]+\t/ {
        if ($3 ~ ex) next
        add += $1; del += $2; files++
      }
      END { printf "%d %d %d", add, del, files }
    ')

  add=$(echo "$stats" | cut -d' ' -f1)
  del=$(echo "$stats" | cut -d' ' -f2)
  files=$(echo "$stats" | cut -d' ' -f3)
  net=$((add + del))

  # Hours estimate: commits × HOURS_PER_COMMIT
  hours=$(awk -v c="$commits" -v hpc="$HOURS_PER_COMMIT" 'BEGIN { h = c * hpc; if (h < 1) h = 1; printf "%d", h }')
  AUTHOR_HOURS["$author"]=$hours

  AUTHOR_NET["$author"]=$net
  AUTHOR_COMMITS["$author"]=$commits
  AUTHOR_DAYS["$author"]=$days
  AUTHOR_FIRST["$author"]=$first
  AUTHOR_LAST["$author"]=$last
  AUTHOR_FILES["$author"]=$files
  AUTHOR_ADD["$author"]=$add
  AUTHOR_DEL["$author"]=$del

  TOTAL_COMMITS=$((TOTAL_COMMITS + commits))
  TOTAL_NET=$((TOTAL_NET + net))
  TOTAL_ADD=$((TOTAL_ADD + add))
  TOTAL_DEL=$((TOTAL_DEL + del))
  TOTAL_FILES=$((TOTAL_FILES + files))

  # Commit type breakdown (conventional commits)
  types=$(git log "${GIT_FILTER[@]}" --author="$author" --format="%s" \
    | grep -oP '^(feat|fix|docs|refactor|style|test|chore|perf|ci|build|revert)(?=\()' \
    | sort | uniq -c | sort -rn | head -6 | awk '{printf "%s:%s ", $2, $1}' || true)
  AUTHOR_TYPES["$author"]="$types"

  # Language / file extension breakdown
  langs=$(git log "${GIT_FILTER[@]}" --author="$author" --name-only --format="" \
    | grep -oP '\.[a-zA-Z0-9]+$' | sort | uniq -c | sort -rn | head -5 \
    | awk '{printf "%s:%s ", $2, $1}' || true)
  AUTHOR_LANGS["$author"]="$langs"

  # PR and revert detection
  prs=$(git log "${GIT_FILTER[@]}" --author="$author" --format="%s" \
    | grep -cP '^Merge pull request|^Merge branch|\(#[0-9]+\)[[:space:]]*$' || true)
  reverts=$(git log "${GIT_FILTER[@]}" --author="$author" --format="%s" \
    | grep -cP '^[Rr]evert[ :]' || true)
  AUTHOR_PRS["$author"]=$prs
  AUTHOR_REVERTS["$author"]=$reverts
  TOTAL_PRS=$((TOTAL_PRS + prs))
  TOTAL_REVERTS=$((TOTAL_REVERTS + reverts))

  # Work patterns (weekday + hour)
  weekday=$(git log "${GIT_FILTER[@]}" --author="$author" --format="%ad" --date=format:"%A" \
    | sort | uniq -c | sort -rn | head -3 | awk '{printf "%s:%s ", $2, $1}')
  hour=$(git log "${GIT_FILTER[@]}" --author="$author" --format="%ad" --date=format:"%H" \
    | sort | uniq -c | sort -rn | head -3 | awk '{printf "%s:00:%s ", $2, $1}')
  AUTHOR_WEEKDAY["$author"]="$weekday"
  AUTHOR_HOUR["$author"]="$hour"

done <<< "$AUTHORS"

# Sort authors by net lines descending
SORTED_AUTHORS=$(for a in "${!AUTHOR_NET[@]}"; do echo "${AUTHOR_NET[$a]} $a"; done | sort -rn | awk '{$1=""; sub(/^ /,""); print}')

REPO_NAME=$(basename "$(pwd)")
GENERATED_AT=$(date -u +"%Y-%m-%d %H:%M UTC")
DATE_RANGE=""
[ -n "$SINCE" ] && DATE_RANGE="from $SINCE"
[ -n "$UNTIL" ] && DATE_RANGE="$DATE_RANGE to $UNTIL"
[ -z "$DATE_RANGE" ] && DATE_RANGE="all time"

# ─── Helpers ─────────────────────────────────────────────────────────
_hash6() {
  if command -v md5sum >/dev/null 2>&1; then
    printf '%s' "$1" | md5sum | cut -c1-6
  elif command -v md5 >/dev/null 2>&1; then
    printf '%s' "$1" | md5 -q | cut -c1-6
  else
    printf '%s' "$1" | cksum | cut -c1-6
  fi
}

html_escape() {
  local s="$1"
  if [ "$ANONYMIZE" = true ]; then
    s="anon-$(_hash6 "$s")"
  fi
  if [ "$REDACT_EMAILS" = true ]; then
    s=$(printf '%s' "$s" | sed 's/<[^>]*>//g')
  fi
  printf '%s' "$s" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

format_number() {
  printf "%'d" "$1" 2>/dev/null || printf "%d" "$1"
}

# ─── Load output writers ─────────────────────────────────────────────
source "${SCRIPT_DIR}/gitriage.lib.sh"

case "$FORMAT" in
  html)     write_html_report ;;
  json)     write_json_report ;;
  csv)      write_csv_report ;;
  markdown) write_markdown_report ;;
  text)     write_text_report ;;
esac
