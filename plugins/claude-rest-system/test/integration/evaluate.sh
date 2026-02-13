#!/bin/bash
# Evaluate rest analysis output
# Usage: evaluate.sh <analysis_dir>
set -euo pipefail

ANALYSIS_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS=0; FAIL=0

run_test() {
  local name="$1"; shift
  if "$@" 2>/dev/null; then
    echo "✓ $name"; PASS=$((PASS + 1))
  else
    echo "✗ $name"; FAIL=$((FAIL + 1))
  fi
}

# Safe glob count: returns count of matching files (0 if none)
glob_count() {
  local pattern="$1"
  # Use find to avoid ls failures on no-match globs
  local dir; dir=$(dirname "$pattern")
  local base; base=$(basename "$pattern")
  find "$dir" -maxdepth 1 -name "$base" 2>/dev/null | wc -l | tr -d ' '
}

# --- Find output paths ---
if [ ! -d "$ANALYSIS_DIR" ]; then
  echo "✗ FATAL: Analysis directory does not exist: $ANALYSIS_DIR"; exit 1
fi
if [ ! -d "$ANALYSIS_DIR/reports" ]; then
  echo "✗ FATAL: No reports/ directory in $ANALYSIS_DIR"; exit 1
fi
PROJECT_SLUG=$(ls "$ANALYSIS_DIR/reports/" 2>/dev/null | head -1 || true)
if [ -z "$PROJECT_SLUG" ]; then
  echo "✗ FATAL: No project directory in reports/"; exit 1
fi
RUN_TS=$(ls "$ANALYSIS_DIR/reports/$PROJECT_SLUG/" 2>/dev/null | sort -r | head -1 || true)
REPORTS="$ANALYSIS_DIR/reports/$PROJECT_SLUG/$RUN_TS"
echo "Report dir: $REPORTS"
echo ""

# ==========================================
echo "=== Tier 1: Structural Checks ==="
# ==========================================

# Final report
run_test "rest.md exists" test -f "$REPORTS/rest.md"
if [ -f "$REPORTS/rest.md" ]; then
  REST_SIZE=$(wc -c < "$REPORTS/rest.md" | tr -d ' ')
  run_test "rest.md is non-trivial (> 500 bytes, got $REST_SIZE)" test "$REST_SIZE" -gt 500
fi

# Session reports
SR_COUNT=$(glob_count "$REPORTS/session-reports/S*-report.md")
run_test "session reports exist (count: $SR_COUNT)" test "$SR_COUNT" -ge 1

# EPUB (optional — requires pandoc in VM)
EPUB_COUNT=$(glob_count "$REPORTS/*.epub")
if [ "$EPUB_COUNT" -gt 0 ]; then
  EPUB=$(find "$REPORTS" -maxdepth 1 -name "*.epub" | head -1)
  run_test "EPUB generated" test -n "$EPUB"
  if [ -n "$EPUB" ] && [ -f "$EPUB" ]; then
    EPUB_SIZE=$(wc -c < "$EPUB" | tr -d ' ')
    run_test "EPUB non-trivial (> 1000 bytes, got $EPUB_SIZE)" test "$EPUB_SIZE" -gt 1000
  fi
else
  echo "⊘ EPUB skipped (pandoc not in VM)"
fi

# Recommendations
run_test "recommendations.md exists" test -f "$REPORTS/recommendations.md"

# Metadata files
META_COUNT=$(find "$ANALYSIS_DIR/sessions" -name "metadata.json" 2>/dev/null | wc -l | tr -d ' ')
run_test "metadata.json files written (count: $META_COUNT)" test "$META_COUNT" -ge 1

# Transcripts were generated
if [ -d "$REPORTS/transcripts" ]; then
  T_COUNT=$(glob_count "$REPORTS/transcripts/*.md")
  run_test "transcripts generated (count: $T_COUNT)" test "$T_COUNT" -ge 1
else
  echo "✗ transcripts directory missing"; FAIL=$((FAIL + 1))
fi

# Required sections in final report
if [ -f "$REPORTS/rest.md" ]; then
  for section in "Summary" "Findings" "Recommendations" "Methodology"; do
    if grep -qi "## .*${section}" "$REPORTS/rest.md"; then
      echo "✓ rest.md contains '$section' section"; PASS=$((PASS + 1))
    else
      echo "✗ rest.md missing '$section' section"; FAIL=$((FAIL + 1))
    fi
  done
fi

# ==========================================
echo ""
echo "=== Tier 2: Content Checks ==="
# ==========================================

# Load expected patterns from fixture spec and check against reports
if [ -f "$SCRIPT_DIR/fixtures/expected.json" ]; then
  FIXTURE_COUNT=$(jq '.fixtures | length' "$SCRIPT_DIR/fixtures/expected.json")

  for i in $(seq 0 $((FIXTURE_COUNT - 1))); do
    NAME=$(jq -r ".fixtures[$i].name" "$SCRIPT_DIR/fixtures/expected.json")
    KEYWORDS=$(jq -r ".fixtures[$i].expected_findings.keywords_any[]" "$SCRIPT_DIR/fixtures/expected.json" 2>/dev/null)
    FOUND=false
    for kw in $KEYWORDS; do
      # Search rest.md and all session reports
      if grep -qil "$kw" "$REPORTS/rest.md" 2>/dev/null; then
        FOUND=true; break
      fi
      if find "$REPORTS/session-reports" -name "*.md" -exec grep -qil "$kw" {} \; 2>/dev/null; then
        FOUND=true; break
      fi
    done
    if $FOUND; then
      echo "✓ fixture '$NAME': at least one keyword found in reports"; PASS=$((PASS + 1))
    else
      echo "✗ fixture '$NAME': none of expected keywords found"; FAIL=$((FAIL + 1))
    fi
  done
fi

# ==========================================
echo ""
echo "=== Results ==="
# ==========================================
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo ""

# ==========================================
echo "=== Tier 3: LLM Quality Score ==="
# ==========================================
echo "(Informational — not a gate)"

if [ -f "$REPORTS/rest.md" ]; then
  cat > "$(dirname "$ANALYSIS_DIR")/quality-prompt.md" <<'PROMPT_EOF'
You are evaluating the quality of a rest analysis report. Score each dimension 1-5.

Dimensions:
1. **Completeness**: Were all sessions analyzed? Are findings present for each?
2. **Specificity**: Do findings cite actual content, not vague summaries?
3. **Finding types**: Are learnings, mistakes, and processes correctly categorized?
4. **Evidence**: Do findings include M# references and keywords?
5. **Recommendations**: Are they concrete and actionable?
6. **Report structure**: Is the markdown well-formed? Sections present?

Output a JSON object:
{"completeness": N, "specificity": N, "finding_types": N, "evidence": N, "recommendations": N, "structure": N, "overall": N, "notes": "..."}
PROMPT_EOF
  echo "Quality scoring prompt written to results/{timestamp}/quality-prompt.md"
  echo "Run: claude -p \"\$(cat quality-prompt.md)\n\n\$(cat rest.md)\""
fi

[ "$FAIL" -eq 0 ]
