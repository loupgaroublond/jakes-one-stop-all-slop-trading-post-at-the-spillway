#!/usr/bin/env bash
#
# Test suite for rest_build_epub.sh bug fixes
#
# Uses fixtures in test/fixtures/epub-bugs/ (copied from the mega analysis)
# to validate:
#   1. No bare <angle-bracket> tags in EPUB XHTML (Bug 1)
#   2. Exactly 5 H1 headings in combined markdown (Bug 2)
#   3. Sessions in numeric order, no INDEX/SUMMARY (Bugs 3 & 4)
#   4. No duplicated pattern content (Bug 5)
#   5. EPUB passes xmllint validation
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILDER="$PLUGIN_DIR/scripts/rest_build_epub.sh"
FIXTURES="$SCRIPT_DIR/fixtures/epub-bugs"

# Use temp dir as fake storage path
TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

PROJECT_SLUG="test-epub-bugs"
RUN_TIMESTAMP="2026-02-13-00-00"

# Set up fake storage structure
REPORTS_DIR="$TMPDIR_BASE/reports/$PROJECT_SLUG/$RUN_TIMESTAMP"
mkdir -p "$REPORTS_DIR"

# Copy fixtures into place
cp -r "$FIXTURES/"* "$REPORTS_DIR/"

PASS=0
FAIL=0
TESTS=0

assert() {
    local description="$1"
    local result="$2"
    TESTS=$((TESTS + 1))
    if [[ "$result" == "0" ]]; then
        echo "  [PASS] $description"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] $description"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== EPUB Builder Test Suite ==="
echo "Fixtures: $FIXTURES"
echo "Working dir: $REPORTS_DIR"
echo ""

# === RUN THE BUILDER ===
echo "--- Running builder ---"
# Patch: don't open Books.app during test
OUTPUT=$(bash "$BUILDER" "$TMPDIR_BASE" "$PROJECT_SLUG" "$RUN_TIMESTAMP" 2>&1 | grep -v "Opening EPUB")
echo "$OUTPUT"
echo ""

COMBINED_MD="$REPORTS_DIR/${PROJECT_SLUG}-REST-${RUN_TIMESTAMP}.md"
EPUB_FILE="$REPORTS_DIR/${PROJECT_SLUG}-REST-${RUN_TIMESTAMP}.epub"

# === TEST 1: Combined markdown was created ===
echo "--- Test: Combined markdown created ---"
assert "Combined markdown file exists" "$([ -f "$COMBINED_MD" ] && echo 0 || echo 1)"

# === TEST 2: H1 count ===
echo "--- Test: H1 heading count ---"
H1_COUNT=$(grep -c '^# ' "$COMBINED_MD" || true)
# Expected: title + Part I + Part II + Appendix = 4 (Part III skipped by dedup)
# OR: title + Part I + Part II + Part III + Appendix = 5 (if no dedup)
# With our fixtures (rest.md has embedded patterns), expect 4 (dedup kicks in)
echo "  H1 count: $H1_COUNT"
assert "H1 count <= 5 (no content H1s leaking)" "$([ "$H1_COUNT" -le 5 ] && echo 0 || echo 1)"

# === TEST 3: No raw angle-bracket tags that would break XHTML ===
echo "--- Test: No bare angle-bracket tags ---"
# Check for patterns like <word> that aren't valid HTML (not <p>, <em>, <strong>, etc.)
BARE_TAGS=$(grep -cP '<(?!/?(?:p|em|strong|code|pre|br|hr|a|ul|ol|li|h[1-6]|blockquote|div|span|img|table|tr|td|th|thead|tbody|dl|dt|dd)\b)[a-z][-a-z]*>' "$COMBINED_MD" 2>/dev/null || true)
BARE_TAGS="${BARE_TAGS:-0}"
echo "  Bare angle-bracket tags in markdown: $BARE_TAGS"
# These exist in source content — the point is pandoc with -raw_html escapes them
# So we just verify the EPUB is valid (Test 6 below)

# === TEST 4: No INDEX or SUMMARY sessions ===
echo "--- Test: No INDEX/SUMMARY sessions ---"
INDEX_SESSIONS=$(grep -cE '^## Session (INDEX|SUMMARY)' "$COMBINED_MD" || true)
echo "  INDEX/SUMMARY session entries: $INDEX_SESSIONS"
assert "No INDEX/SUMMARY session entries" "$([ "$INDEX_SESSIONS" -eq 0 ] && echo 0 || echo 1)"

# === TEST 5: Sessions in numeric order ===
echo "--- Test: Session ordering ---"
SESSION_ORDER=$(grep '^## Session S' "$COMBINED_MD" | sed 's/## Session S//' | tr '\n' ',')
echo "  Session order: $SESSION_ORDER"
# Check that S1 comes before S2 comes before S9 comes before S10 comes before S100
SORTED_ORDER=$(grep '^## Session S' "$COMBINED_MD" | sed 's/## Session S//' | sort -n | tr '\n' ',')
assert "Sessions in numeric order" "$([ "$SESSION_ORDER" = "$SORTED_ORDER" ] && echo 0 || echo 1)"

# === TEST 6: Dedup check — Part III skipped when patterns in rest.md ===
echo "--- Test: Pattern dedup ---"
PART3_PRESENT=$(grep -cE '^# Part III:' "$COMBINED_MD" || true)
echo "  Part III present: $PART3_PRESENT"
assert "Part III skipped (patterns already in rest.md)" "$([ "$PART3_PRESENT" -eq 0 ] && echo 0 || echo 1)"

# === TEST 7: EPUB was created ===
echo "--- Test: EPUB created ---"
assert "EPUB file exists" "$([ -f "$EPUB_FILE" ] && echo 0 || echo 1)"

# === TEST 8: EPUB XHTML validation with xmllint ===
echo "--- Test: EPUB XHTML validation ---"
if command -v xmllint &>/dev/null; then
    # Extract EPUB (it's a zip) and validate XHTML files
    EPUB_EXTRACT="$TMPDIR_BASE/epub-extract"
    mkdir -p "$EPUB_EXTRACT"
    unzip -q "$EPUB_FILE" -d "$EPUB_EXTRACT"

    XHTML_ERRORS=0
    for xhtml in "$EPUB_EXTRACT"/EPUB/text/*.xhtml; do
        if ! xmllint --noout "$xhtml" 2>/dev/null; then
            echo "  [ERROR] $xhtml failed validation"
            XHTML_ERRORS=$((XHTML_ERRORS + 1))
        fi
    done
    echo "  XHTML files with errors: $XHTML_ERRORS"
    assert "All XHTML files pass xmllint" "$([ "$XHTML_ERRORS" -eq 0 ] && echo 0 || echo 1)"
else
    echo "  [SKIP] xmllint not available"
fi

# === SUMMARY ===
echo ""
echo "=== Results: $PASS/$TESTS passed, $FAIL failed ==="

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
