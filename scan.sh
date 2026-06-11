#!/usr/bin/env bash
# AIR Blackbox Compliance Scan - GitHub Action entrypoint
# Runs air-compliance scan, parses results, posts PR comment, sets outputs.
set -euo pipefail

# ============================================================
# Config from inputs
# ============================================================
SCAN_PATH="${INPUT_PATH:-.}"
THRESHOLD="${INPUT_THRESHOLD:-0}"
FAIL_ON="${INPUT_FAIL_ON:-none}"
FRAMEWORKS="${INPUT_FRAMEWORKS:-eu-ai-act}"
POST_COMMENT="${INPUT_COMMENT:-true}"
GEN_BADGE="${INPUT_BADGE:-false}"
JSON_OUTPUT="${INPUT_JSON_OUTPUT:-}"

# ============================================================
# Run the scan
# ============================================================
echo "::group::AIR Blackbox Compliance Scan"
echo "Scanning: ${SCAN_PATH}"
echo "Threshold: ${THRESHOLD}"
echo "Fail on: ${FAIL_ON}"
echo "Frameworks: ${FRAMEWORKS}"

# Build the scan command
SCAN_CMD="air-compliance scan ${SCAN_PATH} --json"

# Add framework flags if not default
if [ "${FRAMEWORKS}" != "eu-ai-act" ]; then
  IFS=',' read -ra FW_ARRAY <<< "${FRAMEWORKS}"
  for fw in "${FW_ARRAY[@]}"; do
    fw_trimmed=$(echo "${fw}" | xargs)
    SCAN_CMD="${SCAN_CMD} --standard ${fw_trimmed}"
  done
fi

# Run scan, capture output (don't fail on non-zero exit from scanner)
SCAN_RESULT_FILE=$(mktemp)
set +e
eval "${SCAN_CMD}" > "${SCAN_RESULT_FILE}" 2>&1
SCAN_EXIT=$?
set -e

# Try to extract JSON from the output (scanner may print non-JSON lines before it)
SCAN_JSON=""
if [ -f "${SCAN_RESULT_FILE}" ]; then
  # Get the last line that looks like JSON (starts with {)
  SCAN_JSON=$(grep -E '^\{' "${SCAN_RESULT_FILE}" | tail -1 || true)
fi

# If no JSON output, try the full file
if [ -z "${SCAN_JSON}" ] && [ -f "${SCAN_RESULT_FILE}" ]; then
  SCAN_JSON=$(cat "${SCAN_RESULT_FILE}")
fi

echo "::endgroup::"

# ============================================================
# Parse results
# ============================================================
if ! echo "${SCAN_JSON}" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
  echo "::error::Scanner did not produce valid JSON output."
  echo "Raw output:"
  cat "${SCAN_RESULT_FILE}"
  rm -f "${SCAN_RESULT_FILE}"

  # Set default outputs so downstream steps don't break
  echo "score=0" >> "$GITHUB_OUTPUT"
  echo "total-findings=0" >> "$GITHUB_OUTPUT"
  echo "high-findings=0" >> "$GITHUB_OUTPUT"
  echo "medium-findings=0" >> "$GITHUB_OUTPUT"
  echo "low-findings=0" >> "$GITHUB_OUTPUT"
  echo "passed=false" >> "$GITHUB_OUTPUT"
  exit 1
fi

# Extract metrics with Python (available in all GitHub Actions runners)
PARSED=$(echo "${SCAN_JSON}" | python3 -c "
import sys, json

data = json.load(sys.stdin)

# Handle both flat and nested result formats
score = data.get('score', data.get('overall_score', 0))
findings = data.get('findings', [])

high = sum(1 for f in findings if f.get('severity', '').lower() == 'high')
medium = sum(1 for f in findings if f.get('severity', '').lower() == 'medium')
low = sum(1 for f in findings if f.get('severity', '').lower() == 'low')
total = len(findings)

# Article scores for the summary table
articles = data.get('articles', [])
article_lines = []
for a in articles:
    num = a.get('number', a.get('article', ''))
    title = a.get('title', a.get('name', ''))
    art_score = a.get('score', 0)
    passed = a.get('checks_passed', 0)
    total_checks = a.get('checks_total', 0)
    status = ':white_check_mark:' if art_score >= 70 else ':warning:' if art_score >= 50 else ':x:'
    article_lines.append(f'| Art. {num} | {title} | {art_score}% | {passed}/{total_checks} | {status} |')

article_table = chr(10).join(article_lines)

# Top findings for the comment
finding_lines = []
for f in findings[:10]:
    sev = f.get('severity', 'low').upper()
    name = f.get('name', f.get('check', 'Unknown'))
    art = f.get('article', '')
    emoji = ':red_circle:' if sev == 'HIGH' else ':orange_circle:' if sev == 'MEDIUM' else ':large_blue_circle:'
    finding_lines.append(f'| {emoji} {sev} | {name} | Art. {art} |')

finding_table = chr(10).join(finding_lines)
more_text = f'_... and {total - 10} more findings_' if total > 10 else ''

# Score emoji
if score >= 80:
    score_emoji = ':white_check_mark:'
elif score >= 60:
    score_emoji = ':warning:'
else:
    score_emoji = ':x:'

print(f'SCORE={score}')
print(f'TOTAL={total}')
print(f'HIGH={high}')
print(f'MEDIUM={medium}')
print(f'LOW={low}')
print(f'SCORE_EMOJI={score_emoji}')
print(f'ARTICLE_TABLE={article_table}')
print(f'FINDING_TABLE={finding_table}')
print(f'MORE_TEXT={more_text}')
")

# Parse into variables
SCORE=$(echo "${PARSED}" | grep '^SCORE=' | cut -d= -f2)
TOTAL=$(echo "${PARSED}" | grep '^TOTAL=' | cut -d= -f2)
HIGH=$(echo "${PARSED}" | grep '^HIGH=' | cut -d= -f2)
MEDIUM=$(echo "${PARSED}" | grep '^MEDIUM=' | cut -d= -f2)
LOW=$(echo "${PARSED}" | grep '^LOW=' | cut -d= -f2)

echo "Score: ${SCORE}/100"
echo "Findings: ${HIGH} high, ${MEDIUM} medium, ${LOW} low (${TOTAL} total)"

# ============================================================
# Set outputs
# ============================================================
echo "score=${SCORE}" >> "$GITHUB_OUTPUT"
echo "total-findings=${TOTAL}" >> "$GITHUB_OUTPUT"
echo "high-findings=${HIGH}" >> "$GITHUB_OUTPUT"
echo "medium-findings=${MEDIUM}" >> "$GITHUB_OUTPUT"
echo "low-findings=${LOW}" >> "$GITHUB_OUTPUT"

# ============================================================
# Write JSON output if requested
# ============================================================
if [ -n "${JSON_OUTPUT}" ]; then
  echo "${SCAN_JSON}" > "${JSON_OUTPUT}"
  echo "JSON results written to ${JSON_OUTPUT}"
fi

# ============================================================
# Post PR comment
# ============================================================
if [ "${POST_COMMENT}" = "true" ] && [ -n "${GITHUB_TOKEN:-}" ]; then
  # Only post on pull requests
  if [ -n "${GITHUB_EVENT_NAME:-}" ] && [ "${GITHUB_EVENT_NAME}" = "pull_request" ]; then
    PR_NUMBER=$(python3 -c "
import json, os
with open(os.environ.get('GITHUB_EVENT_PATH', '/dev/null')) as f:
    event = json.load(f)
    print(event.get('pull_request', {}).get('number', ''))
" 2>/dev/null || true)

    if [ -n "${PR_NUMBER}" ]; then
      # Build the comment body
      SCORE_EMOJI=$(echo "${PARSED}" | grep '^SCORE_EMOJI=' | cut -d= -f2)
      ARTICLE_TABLE=$(echo "${PARSED}" | sed -n 's/^ARTICLE_TABLE=//p')
      FINDING_TABLE=$(echo "${PARSED}" | sed -n 's/^FINDING_TABLE=//p')
      MORE_TEXT=$(echo "${PARSED}" | sed -n 's/^MORE_TEXT=//p')

      COMMENT_BODY="## ${SCORE_EMOJI} AIR Blackbox Compliance Scan: ${SCORE}/100

**${TOTAL} findings** (${HIGH} high, ${MEDIUM} medium, ${LOW} low)

### Article Scores

| Article | Name | Score | Checks | Status |
|---------|------|-------|--------|--------|
${ARTICLE_TABLE}

### Top Findings

| Severity | Finding | Article |
|----------|---------|---------|
${FINDING_TABLE}
${MORE_TEXT}

---
<sub>Scanned by [AIR Blackbox](https://airblackbox.ai) | [Fix these findings](https://airblackbox.ai/guides) | EU AI Act deadline: August 2, 2026</sub>"

      # Post via GitHub API
      COMMENT_JSON=$(python3 -c "
import json, sys
body = sys.stdin.read()
print(json.dumps({'body': body}))
" <<< "${COMMENT_BODY}")

      REPO="${GITHUB_REPOSITORY}"
      curl -s -X POST \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/${REPO}/issues/${PR_NUMBER}/comments" \
        -d "${COMMENT_JSON}" > /dev/null 2>&1 || echo "::warning::Failed to post PR comment"

      echo "Posted scan results as PR comment"
    fi
  fi
fi

# ============================================================
# Generate badge (optional)
# ============================================================
if [ "${GEN_BADGE}" = "true" ]; then
  if [ "${SCORE}" -ge 80 ]; then
    BADGE_COLOR="brightgreen"
  elif [ "${SCORE}" -ge 60 ]; then
    BADGE_COLOR="yellow"
  else
    BADGE_COLOR="red"
  fi

  BADGE_SVG="<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"160\" height=\"20\">
  <linearGradient id=\"b\" x2=\"0\" y2=\"100%\">
    <stop offset=\"0\" stop-color=\"#bbb\" stop-opacity=\".1\"/>
    <stop offset=\"1\" stop-opacity=\".1\"/>
  </linearGradient>
  <mask id=\"a\"><rect width=\"160\" height=\"20\" rx=\"3\" fill=\"#fff\"/></mask>
  <g mask=\"url(#a)\">
    <rect width=\"100\" height=\"20\" fill=\"#555\"/>
    <rect x=\"100\" width=\"60\" height=\"20\" fill=\"$([ ${BADGE_COLOR} = 'brightgreen' ] && echo '#4c1' || ([ ${BADGE_COLOR} = 'yellow' ] && echo '#dfb317' || echo '#e05d44'))\"/>
    <rect width=\"160\" height=\"20\" fill=\"url(#b)\"/>
  </g>
  <g fill=\"#fff\" text-anchor=\"middle\" font-family=\"Verdana,Geneva,sans-serif\" font-size=\"11\">
    <text x=\"50\" y=\"15\" fill=\"#010101\" fill-opacity=\".3\">AIR Compliance</text>
    <text x=\"50\" y=\"14\">AIR Compliance</text>
    <text x=\"130\" y=\"15\" fill=\"#010101\" fill-opacity=\".3\">${SCORE}%</text>
    <text x=\"130\" y=\"14\">${SCORE}%</text>
  </g>
</svg>"

  echo "${BADGE_SVG}" > .air-compliance-badge.svg
  echo "Badge written to .air-compliance-badge.svg"
fi

# ============================================================
# Check thresholds
# ============================================================
PASSED="true"

# Check score threshold
if [ "${THRESHOLD}" -gt 0 ] && [ "${SCORE}" -lt "${THRESHOLD}" ]; then
  echo "::error::Compliance score ${SCORE} is below threshold ${THRESHOLD}"
  PASSED="false"
fi

# Check severity threshold
case "${FAIL_ON}" in
  high)
    if [ "${HIGH}" -gt 0 ]; then
      echo "::error::Found ${HIGH} high-severity findings (fail-on: high)"
      PASSED="false"
    fi
    ;;
  medium)
    if [ "${HIGH}" -gt 0 ] || [ "${MEDIUM}" -gt 0 ]; then
      echo "::error::Found ${HIGH} high + ${MEDIUM} medium-severity findings (fail-on: medium)"
      PASSED="false"
    fi
    ;;
  low)
    if [ "${TOTAL}" -gt 0 ]; then
      echo "::error::Found ${TOTAL} findings (fail-on: low)"
      PASSED="false"
    fi
    ;;
  none|*)
    # Never fail on findings
    ;;
esac

echo "passed=${PASSED}" >> "$GITHUB_OUTPUT"

# Clean up
rm -f "${SCAN_RESULT_FILE}"

# Summary
echo ""
echo "============================================"
echo "  AIR Blackbox Compliance Score: ${SCORE}/100"
echo "  Findings: ${HIGH} high | ${MEDIUM} medium | ${LOW} low"
echo "  Threshold: ${THRESHOLD} | Fail-on: ${FAIL_ON}"
echo "  Result: $([ ${PASSED} = 'true' ] && echo 'PASSED' || echo 'FAILED')"
echo "============================================"
echo ""

# Add to GitHub step summary
cat >> "$GITHUB_STEP_SUMMARY" <<EOF
## AIR Blackbox Compliance Scan

| Metric | Value |
|--------|-------|
| Score | **${SCORE}/100** |
| High | ${HIGH} |
| Medium | ${MEDIUM} |
| Low | ${LOW} |
| Result | $([ ${PASSED} = 'true' ] && echo ':white_check_mark: Passed' || echo ':x: Failed') |

[View full report on airblackbox.ai](https://airblackbox.ai/console/scan)
EOF

if [ "${PASSED}" = "false" ]; then
  exit 1
fi
