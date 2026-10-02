#!/usr/bin/env bash
# gitriage.lib.sh — Output writers for gitriage
# Sourced by gitriage.sh

# ─── HTML Report ─────────────────────────────────────────────────────
write_html_report() {
  local css_dir
  css_dir=$(dirname "$OUTPUT")
  local css_basename
  css_basename=$(basename "$CSS_FILE")

  if [ ! -f "$CSS_FILE" ]; then
    local default_css="${SCRIPT_DIR}/report.css"
    if [ -f "$default_css" ]; then
      mkdir -p "$css_dir"
      cp "$default_css" "$CSS_FILE"
    else
      echo "CSS file not found: $CSS_FILE" >&2
      exit 1
    fi
  fi

  local css_href
  if [ "$(cd "$(dirname "$CSS_FILE")" && pwd)" = "$(cd "$css_dir" && pwd)" ]; then
    css_href="$css_basename"
  else
    css_href="$CSS_FILE"
  fi

  {
    cat <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Contribution Report — $(html_escape "$REPO_NAME")</title>
<link rel="stylesheet" href="$(html_escape "$css_href")">
</head>
<body>
<div class="container">

  <header class="header">
    <div>
      <h1>Contribution Report</h1>
      <p class="repo-name">$(html_escape "$REPO_NAME")</p>
    </div>
    <div class="header-right">
      <span class="badge">Rate <strong>${RATE} ${CURRENCY}/h</strong></span>
      <span class="badge">Range <strong>${DATE_RANGE}</strong></span>
    </div>
  </header>

  <section class="stats">
    <div class="stat"><div class="stat-label">Contributors</div><div class="stat-value accent">$(echo "$SORTED_AUTHORS" | grep -c .)</div></div>
    <div class="stat"><div class="stat-label">Total Commits</div><div class="stat-value">$(format_number "$TOTAL_COMMITS")</div></div>
    <div class="stat"><div class="stat-label">Lines Changed</div><div class="stat-value yellow">$(format_number "$TOTAL_NET")</div></div>
    <div class="stat"><div class="stat-label">Pull Requests</div><div class="stat-value cyan">$(format_number "$TOTAL_PRS")</div></div>
    <div class="stat"><div class="stat-label">Reverts</div><div class="stat-value red">$(format_number "$TOTAL_REVERTS")</div></div>
  </section>

  <h2 class="section-title">Contribution Summary</h2>
  <div class="table-wrap">
    <table>
      <thead><tr>
        <th>Author</th><th class="num">Commits</th><th class="num">Added</th>
        <th class="num">Deleted</th><th class="num">Net</th><th class="num">Files</th>
        <th class="num">Days</th><th>First</th><th>Last</th>
      </tr></thead>
      <tbody>
HTML

    while IFS= read -r author; do
      if [ -z "$author" ]; then continue; fi
      cat <<ROW
        <tr>
          <td class="author">$(html_escape "$author")</td>
          <td class="num">$(format_number "${AUTHOR_COMMITS[$author]}")</td>
          <td class="num add">+$(format_number "${AUTHOR_ADD[$author]}")</td>
          <td class="num del">−$(format_number "${AUTHOR_DEL[$author]}")</td>
          <td class="num">$(format_number "${AUTHOR_NET[$author]}")</td>
          <td class="num">$(format_number "${AUTHOR_FILES[$author]}")</td>
          <td class="num">${AUTHOR_DAYS[$author]}</td>
          <td>${AUTHOR_FIRST[$author]}</td>
          <td>${AUTHOR_LAST[$author]}</td>
        </tr>
ROW
    done <<< "$SORTED_AUTHORS"

    cat <<HTML
      </tbody>
    </table>
  </div>

  <h2 class="section-title">Share &amp; Payment Estimate</h2>
  <div class="table-wrap">
    <table>
      <thead><tr>
        <th>Author</th><th class="num">Net</th><th class="num">Share</th>
        <th>Distribution</th><th class="num">Est. Hours</th>
        <th class="num">Payment (${CURRENCY})</th>
      </tr></thead>
      <tbody>
HTML

    while IFS= read -r author; do
      if [ -z "$author" ]; then continue; fi
      local net=${AUTHOR_NET[$author]}
      local days=${AUTHOR_DAYS[$author]}
      local commits=${AUTHOR_COMMITS[$author]}
      local files=${AUTHOR_FILES[$author]}
      local hours pay_low share
      hours=${AUTHOR_HOURS[$author]}
      pay_low=$((hours * RATE))
      share=$(awk -v n="$net" -v tn="$TOTAL_NET" -v c="$commits" -v tc="$TOTAL_COMMITS" -v f="$files" -v tf="$TOTAL_FILES" 'BEGIN { ns=(tn>0)?n/tn:0; cs=(tc>0)?c/tc:0; fs=(tf>0)?f/tf:0; printf "%.1f", (0.5*ns+0.3*cs+0.2*fs)*100 }')
      local bar_width
      bar_width=$(awk -v s="$share" 'BEGIN { printf "%.0f", s * 2 }')
      if [ "$bar_width" -lt 4 ]; then bar_width=4; fi

      cat <<ROW
        <tr>
          <td class="author">$(html_escape "$author")</td>
          <td class="num">$(format_number "$net")</td>
          <td class="num share">${share}%</td>
          <td><span class="bar" style="width:${bar_width}px"></span></td>
          <td class="num">${hours}</td>
          <td class="num pay">$(format_number "$pay_low")</td>
        </tr>
ROW
    done <<< "$SORTED_AUTHORS"

    cat <<HTML
      </tbody>
    </table>
  </div>

  <h2 class="section-title">Commit Types &amp; Languages</h2>
  <div class="authors">
HTML

    while IFS= read -r author; do
      if [ -z "$author" ]; then continue; fi
      local initial
      initial=$(printf '%s' "$author" | cut -c1 | tr '[:lower:]' '[:upper:]')
      cat <<CARD
    <div class="author-card">
      <h3><span class="avatar">${initial}</span> $(html_escape "$author")</h3>
      <div class="card-section">
        <div class="card-section-title">Commit types</div>
        <div class="tags">
CARD
      for pair in ${AUTHOR_TYPES[$author]}; do
        local t="${pair%%:*}"
        local c="${pair##*:}"
        printf '          <span class="tag tag-%s">%s <b>%s</b></span>\n' "$t" "$t" "$c"
      done
      cat <<CARD
        </div>
      </div>
      <div class="card-section">
        <div class="card-section-title">Languages</div>
        <div class="tags">
CARD
      for pair in ${AUTHOR_LANGS[$author]}; do
        local l="${pair%%:*}"
        local c="${pair##*:}"
        printf '          <span class="tag tag-lang">%s <b>%s</b></span>\n' "$l" "$c"
      done
      cat <<CARD
        </div>
      </div>
      <div class="card-section">
        <div class="card-section-title">PRs / Reverts</div>
        <div class="tags">
          <span class="tag tag-feat">PRs <b>${AUTHOR_PRS[$author]}</b></span>
          <span class="tag tag-fix">Reverts <b>${AUTHOR_REVERTS[$author]}</b></span>
        </div>
      </div>
    </div>
CARD
    done <<< "$SORTED_AUTHORS"

    cat <<HTML
  </div>

  <h2 class="section-title">Work Patterns</h2>
  <div class="authors">
HTML

    while IFS= read -r author; do
      if [ -z "$author" ]; then continue; fi
      local initial
      initial=$(printf '%s' "$author" | cut -c1 | tr '[:lower:]' '[:upper:]')
      cat <<CARD
    <div class="author-card">
      <h3><span class="avatar">${initial}</span> $(html_escape "$author")</h3>
      <div class="card-section">
        <div class="card-section-title">Top weekdays</div>
        <div class="tags">
CARD
      for pair in ${AUTHOR_WEEKDAY[$author]}; do
        local d="${pair%%:*}"
        local c="${pair##*:}"
        printf '          <span class="tag">%s <b>%s</b></span>\n' "$d" "$c"
      done
      cat <<CARD
        </div>
      </div>
      <div class="card-section">
        <div class="card-section-title">Top hours</div>
        <div class="tags">
CARD
      for pair in ${AUTHOR_HOUR[$author]}; do
        local h="${pair%%:*}"
        local c="${pair##*:}"
        printf '          <span class="tag">%s <b>%s</b></span>\n' "$h" "$c"
      done
      cat <<CARD
        </div>
      </div>
    </div>
CARD
    done <<< "$SORTED_AUTHORS"

    cat <<HTML
  </div>

  <h2 class="section-title">Top Changed Paths per Author</h2>
  <div class="authors">
HTML

    while IFS= read -r author; do
      if [ -z "$author" ]; then continue; fi
      local initial
      initial=$(printf '%s' "$author" | cut -c1 | tr '[:lower:]' '[:upper:]')
      cat <<CARD
    <div class="author-card">
      <h3><span class="avatar">${initial}</span> $(html_escape "$author")</h3>
      <ul class="path-list">
CARD
      git log "${GIT_FILTER[@]}" --author="$author" --name-only --format="" \
        | grep -v '^$' \
        | awk -F/ '{
            if (NF >= 3) print $1"/"$2"/"$3
            else if (NF == 2) print $1"/"$2
            else print $1
          }' \
        | sort | uniq -c | sort -rn | head -"$TOP_PATHS" \
        | while read -r count path; do
            printf '        <li><span class="path">%s</span><span class="count">%s</span></li>\n' \
              "$(html_escape "$path")" "$count"
          done
      printf '      </ul>\n    </div>\n'
    done <<< "$SORTED_AUTHORS"

    cat <<HTML
  </div>

  <h2 class="section-title">Recent Commits per Author</h2>
  <div class="authors">
HTML

    while IFS= read -r author; do
      if [ -z "$author" ]; then continue; fi
      local initial
      initial=$(printf '%s' "$author" | cut -c1 | tr '[:lower:]' '[:upper:]')
      local total=${AUTHOR_COMMITS[$author]}
      cat <<CARD
    <div class="author-card">
      <h3><span class="avatar">${initial}</span> $(html_escape "$author")</h3>
      <ul class="commit-list">
CARD
      git log "${GIT_FILTER[@]}" --author="$author" \
        --format="%ad|%s" --date=short | head -"$TOP_COMMITS" \
        | while IFS='|' read -r date msg; do
            printf '        <li><span class="date">%s</span><span class="msg">%s</span></li>\n' \
              "$(html_escape "$date")" "$(html_escape "$msg")"
          done
      if [ "$total" -gt "$TOP_COMMITS" ]; then
        printf '        <li class="more">… and %d more commits</li>\n' "$((total - TOP_COMMITS))"
      fi
      printf '      </ul>\n    </div>\n'
    done <<< "$SORTED_AUTHORS"

    cat <<HTML
  </div>

  <footer class="footer">
    Generated by gitriage v${VERSION} · ${GENERATED_AT}
  </footer>

</div>
</body>
</html>
HTML
  } > "$OUTPUT"

  echo "HTML report: $OUTPUT"
  echo "CSS file:    $CSS_FILE"
}

# ─── JSON Report ─────────────────────────────────────────────────────
write_json_report() {
  echo "{"
  echo "  \"repository\": \"$(json_escape "$REPO_NAME")\","
  echo "  \"generated_at\": \"$GENERATED_AT\","
  echo "  \"date_range\": \"$(json_escape "$DATE_RANGE")\","
  echo "  \"rate\": $RATE,"
  echo "  \"currency\": \"$(json_escape "$CURRENCY")\","
  
  echo "  \"totals\": { \"commits\": $TOTAL_COMMITS, \"net_lines\": $TOTAL_NET, \"added\": $TOTAL_ADD, \"deleted\": $TOTAL_DEL, \"prs\": $TOTAL_PRS, \"reverts\": $TOTAL_REVERTS },"
  echo "  \"authors\": ["
  local first=1
  while IFS= read -r author; do
    if [ -z "$author" ]; then continue; fi
    [ $first -eq 0 ] && echo ","
    first=0
    local net=${AUTHOR_NET[$author]}
    local days=${AUTHOR_DAYS[$author]}
    local commits=${AUTHOR_COMMITS[$author]}
    local files=${AUTHOR_FILES[$author]}
    local hours pay_low share
    hours=${AUTHOR_HOURS[$author]}
    pay_low=$((hours * RATE))
    share=$(awk -v n="$net" -v tn="$TOTAL_NET" -v c="$commits" -v tc="$TOTAL_COMMITS" -v f="$files" -v tf="$TOTAL_FILES" 'BEGIN { ns=(tn>0)?n/tn:0; cs=(tc>0)?c/tc:0; fs=(tf>0)?f/tf:0; printf "%.1f", (0.5*ns+0.3*cs+0.2*fs)*100 }')
    printf '    {"name":"%s","commits":%d,"added":%d,"deleted":%d,"net":%d,"files":%d,"active_days":%d,"first_commit":"%s","last_commit":"%s","share_percent":%s,"est_hours":%d,"est_payment":%d,"prs":%d,"reverts":%d,"commit_types":"%s","languages":"%s"}' \
      "$(json_escape "$author")" "${AUTHOR_COMMITS[$author]}" "${AUTHOR_ADD[$author]}" \
      "${AUTHOR_DEL[$author]}" "$net" "${AUTHOR_FILES[$author]}" "$days" \
      "${AUTHOR_FIRST[$author]}" "${AUTHOR_LAST[$author]}" "$share" \
      "$hours" "$pay_low" \
      "${AUTHOR_PRS[$author]}" "${AUTHOR_REVERTS[$author]}" \
      "${AUTHOR_TYPES[$author]}" "${AUTHOR_LANGS[$author]}"
  done <<< "$SORTED_AUTHORS"
  echo ""
  echo "  ]"
  echo "}"
}

# ─── CSV Report ──────────────────────────────────────────────────────
write_csv_report() {
  echo "author,commits,added,deleted,net,files,active_days,first_commit,last_commit,share_percent,est_hours,est_payment,prs,reverts,currency"
  while IFS= read -r author; do
    if [ -z "$author" ]; then continue; fi
    local net=${AUTHOR_NET[$author]}
    local days=${AUTHOR_DAYS[$author]}
    local commits=${AUTHOR_COMMITS[$author]}
    local files=${AUTHOR_FILES[$author]}
    local hours pay_low share
    hours=${AUTHOR_HOURS[$author]}
    pay_low=$((hours * RATE))
    share=$(awk -v n="$net" -v tn="$TOTAL_NET" -v c="$commits" -v tc="$TOTAL_COMMITS" -v f="$files" -v tf="$TOTAL_FILES" 'BEGIN { ns=(tn>0)?n/tn:0; cs=(tc>0)?c/tc:0; fs=(tf>0)?f/tf:0; printf "%.1f", (0.5*ns+0.3*cs+0.2*fs)*100 }')
    echo "\"$author\",${AUTHOR_COMMITS[$author]},${AUTHOR_ADD[$author]},${AUTHOR_DEL[$author]},$net,${AUTHOR_FILES[$author]},$days,${AUTHOR_FIRST[$author]},${AUTHOR_LAST[$author]},$share,$hours,$pay_low,${AUTHOR_PRS[$author]},${AUTHOR_REVERTS[$author]},\"$CURRENCY\""
  done <<< "$SORTED_AUTHORS"
}

# ─── Markdown Report ─────────────────────────────────────────────────
write_markdown_report() {
  echo "# Contribution Report — ${REPO_NAME}"
  echo ""
  echo "**Generated:** ${GENERATED_AT}  "
  echo "**Date range:** ${DATE_RANGE}  "
  echo "**Rate:** ${RATE} ${CURRENCY}/h  "
  echo ""
  echo "| Author | Commits | Added | Deleted | Net | Files | Days | Share | Est. Hours | Payment (${CURRENCY}) |"
  echo "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|"
  while IFS= read -r author; do
    if [ -z "$author" ]; then continue; fi
    local net=${AUTHOR_NET[$author]}
    local days=${AUTHOR_DAYS[$author]}
    local commits=${AUTHOR_COMMITS[$author]}
    local files=${AUTHOR_FILES[$author]}
    local hours pay_low share
    hours=${AUTHOR_HOURS[$author]}
    pay_low=$((hours * RATE))
    share=$(awk -v n="$net" -v tn="$TOTAL_NET" -v c="$commits" -v tc="$TOTAL_COMMITS" -v f="$files" -v tf="$TOTAL_FILES" 'BEGIN { ns=(tn>0)?n/tn:0; cs=(tc>0)?c/tc:0; fs=(tf>0)?f/tf:0; printf "%.1f", (0.5*ns+0.3*cs+0.2*fs)*100 }')
    echo "| ${author} | ${AUTHOR_COMMITS[$author]} | +${AUTHOR_ADD[$author]} | −${AUTHOR_DEL[$author]} | ${net} | ${AUTHOR_FILES[$author]} | ${days} | ${share}% | ${hours} | ${pay_low} |"
  done <<< "$SORTED_AUTHORS"
  echo ""
  echo "## Commit Types"
  echo ""
  while IFS= read -r author; do
    if [ -z "$author" ]; then continue; fi
    echo "### ${author}"
    echo ""
    echo "- **Types:** ${AUTHOR_TYPES[$author]:-none}"
    echo "- **Languages:** ${AUTHOR_LANGS[$author]:-none}"
    echo "- **PRs:** ${AUTHOR_PRS[$author]}  |  **Reverts:** ${AUTHOR_REVERTS[$author]}"
    echo "- **Weekdays:** ${AUTHOR_WEEKDAY[$author]:-n/a}"
    echo "- **Hours:** ${AUTHOR_HOUR[$author]:-n/a}"
    echo ""
  done <<< "$SORTED_AUTHORS"
  echo "---"
  echo "Generated by gitriage v${VERSION}"
}

# ─── Text Report ─────────────────────────────────────────────────────
write_text_report() {
  printf "%-25s %8s %10s %10s %8s %8s %8s\n" "Author" "Commits" "Added" "Deleted" "Net" "Days" "PRs"
  printf "%-25s %8s %10s %10s %8s %8s %8s\n" "-------------------------" "--------" "----------" "----------" "--------" "--------" "--------"
  while IFS= read -r author; do
    if [ -z "$author" ]; then continue; fi
    printf "%-25s %8d %10d %10d %8d %8d %8d\n" \
      "$author" "${AUTHOR_COMMITS[$author]}" "${AUTHOR_ADD[$author]}" \
      "${AUTHOR_DEL[$author]}" "${AUTHOR_NET[$author]}" "${AUTHOR_DAYS[$author]}" \
      "${AUTHOR_PRS[$author]}"
  done <<< "$SORTED_AUTHORS"
}