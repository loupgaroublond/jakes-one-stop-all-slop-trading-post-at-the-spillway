#!/usr/bin/env bash
#
# Build project-specific EPUB from rest analysis reports
#
# Usage:
#   rest_build_epub.sh <storage-path> <project-slug> <run-timestamp>
#
# Example:
#   rest_build_epub.sh ~/.claude/analysis grug-brained-employee 2025-12-31-14-30
#
# Output: {storage}/reports/{project-slug}/{run-timestamp}/{project-slug}-REST-{run-timestamp}.epub
#
# Includes (in order):
#   1. Final report (rest.md)
#   2. Recommendations (recommendations.md)
#   3. Pattern reports (pattern-reports/*.md)
#   4. Session reports (session-reports/*.md) - as appendix
#

set -euo pipefail

# Ensure blank line before list items when one is missing.
# Pandoc requires a blank line before lists to parse them as lists.
fix_list_spacing() {
    awk '{
        is_list = ($0 ~ /^[[:space:]]*([-*] |[0-9]+\. )/)
        is_blank = ($0 ~ /^[[:space:]]*$/)
        if (is_list && !prev_blank && !prev_list) print ""
        print
        prev_blank = is_blank
        prev_list = is_list
    }'
}

STORAGE="${1:-}"
PROJECT_SLUG="${2:-}"
RUN_TIMESTAMP="${3:-}"

# Validate required parameters
if [[ -z "$STORAGE" || -z "$PROJECT_SLUG" || -z "$RUN_TIMESTAMP" ]]; then
    echo "Error: All three parameters required" >&2
    echo "Usage: rest_build_epub.sh <storage-path> <project-slug> <run-timestamp>" >&2
    echo "" >&2
    echo "Example: rest_build_epub.sh ~/.claude/analysis grug-brained-employee 2025-12-31-14-30" >&2
    exit 1
fi

# Expand tilde and construct reports directory
STORAGE="${STORAGE/#\~/$HOME}"
REPORTS_DIR="$STORAGE/reports/$PROJECT_SLUG/$RUN_TIMESTAMP"

# Generate display-friendly project name (kebab-case to Title Case)
PROJECT_DISPLAY=$(echo "$PROJECT_SLUG" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')

# Output filename
EPUB_BASENAME="${PROJECT_SLUG}-REST-${RUN_TIMESTAMP}"

echo "=== REST Analysis EPUB Builder ==="
echo "Project: $PROJECT_DISPLAY"
echo "Run: $RUN_TIMESTAMP"
echo "Reports: $REPORTS_DIR"
echo ""

# Verify reports directory exists
if [[ ! -d "$REPORTS_DIR" ]]; then
    echo "Error: Reports directory not found: $REPORTS_DIR" >&2
    exit 1
fi

cd "$REPORTS_DIR"

# === PRE-FLIGHT CHECKS ===
echo "=== Pre-flight Checks ==="

PREFLIGHT_PASS=true
WARNINGS=""

# Check 1: Final report exists (rest.md - single file per run)
FINAL_REPORT=""
if [[ -f "rest.md" ]]; then
    FINAL_REPORT="rest.md"
    echo "[OK] Found rest.md"
else
    echo "[FAIL] No rest.md final report found"
    PREFLIGHT_PASS=false
fi

# Check 2: Recommendations file (recommendations.md - single file per run)
RECOMMENDATIONS=""
if [[ -f "recommendations.md" ]]; then
    RECOMMENDATIONS="recommendations.md"
    echo "[OK] Found recommendations.md"
else
    WARNINGS="$WARNINGS\n[WARN] No recommendations.md found"
fi

# Check 3: Pattern reports
PATTERN_REPORTS=""
if [[ -d "pattern-reports" ]]; then
    PATTERN_REPORTS=$(find pattern-reports -name "*-consolidated.md" -type f 2>/dev/null | sort -V)
fi
if [[ -z "$PATTERN_REPORTS" ]]; then
    WARNINGS="$WARNINGS\n[WARN] No pattern reports found in pattern-reports/"
else
    PATTERN_COUNT=$(echo "$PATTERN_REPORTS" | wc -l | tr -d ' ')
    echo "[OK] Found $PATTERN_COUNT pattern report(s)"
fi

# Check 4: Session reports
SESSION_REPORTS=""
if [[ -d "session-reports" ]]; then
    SESSION_REPORTS=$(find session-reports -name "S*-report.md" -type f 2>/dev/null | sort -V)
fi
if [[ -z "$SESSION_REPORTS" ]]; then
    WARNINGS="$WARNINGS\n[WARN] No session reports found in session-reports/"
else
    SESSION_COUNT=$(echo "$SESSION_REPORTS" | wc -l | tr -d ' ')
    echo "[OK] Found $SESSION_COUNT session report(s)"
fi

# Show warnings
if [[ -n "$WARNINGS" ]]; then
    echo -e "$WARNINGS"
fi

# Abort if critical checks failed
if [[ "$PREFLIGHT_PASS" == "false" ]]; then
    echo ""
    echo "Pre-flight checks failed. Cannot build EPUB."
    exit 1
fi

echo ""
echo "=== Building EPUB ==="

# Count total files to include
TOTAL_FILES=0
[[ -n "$FINAL_REPORT" ]] && TOTAL_FILES=$((TOTAL_FILES + 1))
[[ -n "$RECOMMENDATIONS" ]] && TOTAL_FILES=$((TOTAL_FILES + 1))
[[ -n "$PATTERN_REPORTS" ]] && TOTAL_FILES=$((TOTAL_FILES + $(echo "$PATTERN_REPORTS" | wc -l)))
[[ -n "$SESSION_REPORTS" ]] && TOTAL_FILES=$((TOTAL_FILES + $(echo "$SESSION_REPORTS" | wc -l)))
echo "Total files to include: $TOTAL_FILES"

# Parse date from run timestamp (format: YYYY-MM-DD-HH-MM)
if [[ "$RUN_TIMESTAMP" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2})-([0-9]{2}-[0-9]{2}) ]]; then
    RUN_DATE="${BASH_REMATCH[1]}"
    RUN_TIME="${BASH_REMATCH[2]//-/:}"
    DATE_RANGE="$RUN_DATE $RUN_TIME"
else
    DATE_RANGE="$RUN_TIMESTAMP"
fi

GENERATION_TIME=$(date "+%Y-%m-%d %H:%M:%S")

# Create combined markdown file
COMBINED_MD="${EPUB_BASENAME}.md"
echo "Creating ${COMBINED_MD}..."

cat > "${COMBINED_MD}" << EOF
# $PROJECT_DISPLAY - Rest Analysis

## Book Information

**Project:** $PROJECT_DISPLAY
**Analysis Run:** $DATE_RANGE
**Generated:** $GENERATION_TIME
**Location:** $REPORTS_DIR

## Contents

This book contains:

EOF

# Add content summary
[[ -n "$FINAL_REPORT" ]] && echo "- **Final Report:** 1" >> "${COMBINED_MD}"
[[ -n "$RECOMMENDATIONS" ]] && echo "- **Recommendations:** 1" >> "${COMBINED_MD}"
[[ -n "$PATTERN_REPORTS" ]] && echo "- **Pattern Reports:** $(echo "$PATTERN_REPORTS" | wc -l | tr -d ' ')" >> "${COMBINED_MD}"
[[ -n "$SESSION_REPORTS" ]] && echo "- **Session Reports:** $(echo "$SESSION_REPORTS" | wc -l | tr -d ' ') (appendix)" >> "${COMBINED_MD}"

cat >> "${COMBINED_MD}" << 'EOF'

## How to Use This Book

1. **Start with the Final Report** - Executive summary and key findings
2. **Review Recommendations** - Actionable items to implement
3. **Explore Patterns** - Cross-session themes and root causes
4. **Dive into Sessions** - Full narrative analysis of individual sessions

---

EOF

# === PART 1: FINAL REPORT ===
if [[ -n "$FINAL_REPORT" ]]; then
    echo "" >> "${COMBINED_MD}"
    echo "# Part I: Analysis Report" >> "${COMBINED_MD}"
    echo "" >> "${COMBINED_MD}"
    echo "## Analysis: $DATE_RANGE" >> "${COMBINED_MD}"
    echo "" >> "${COMBINED_MD}"
    # Skip the first H1 heading, demote remaining headings so they don't clutter TOC
    # Order: deepest first to avoid double-demotion
    sed '1{/^# /d;}' "$FINAL_REPORT" | sed 's/^##### /####### /g; s/^#### /##### /g; s/^### /#### /g; s/^## /### /g; s/^# /## /g' | fix_list_spacing >> "${COMBINED_MD}"
fi

# === PART 2: RECOMMENDATIONS ===
if [[ -n "$RECOMMENDATIONS" ]]; then
    echo "" >> "${COMBINED_MD}"
    echo "# Part II: Recommendations" >> "${COMBINED_MD}"
    echo "" >> "${COMBINED_MD}"
    echo "## Recommendations" >> "${COMBINED_MD}"
    echo "" >> "${COMBINED_MD}"
    # Demote headings so internal sections don't appear in TOC
    sed '1{/^# /d;}' "$RECOMMENDATIONS" | sed 's/^##### /####### /g; s/^#### /##### /g; s/^### /#### /g; s/^## /### /g; s/^# /## /g' | fix_list_spacing >> "${COMBINED_MD}"
fi

# === PART 3: PATTERN REPORTS ===
# Skip if rest.md already embeds full pattern content (avoids duplication)
PATTERNS_IN_REST=$(grep -c '^# Pattern:' "$FINAL_REPORT" 2>/dev/null || echo 0)
if [[ "$PATTERNS_IN_REST" -gt 0 ]]; then
    echo "  [DEDUP] rest.md contains $PATTERNS_IN_REST embedded pattern sections — skipping Part III"
    PATTERN_REPORTS=""
fi
if [[ -n "$PATTERN_REPORTS" ]]; then
    echo "" >> "${COMBINED_MD}"
    echo "# Part III: Cross-Session Patterns" >> "${COMBINED_MD}"
    echo "" >> "${COMBINED_MD}"
    echo "These reports consolidate findings that appeared across multiple sessions." >> "${COMBINED_MD}"
    echo "" >> "${COMBINED_MD}"

    while IFS= read -r file; do
        basename="${file##*/}"
        basename="${basename%.md}"
        # Convert slug to title (ami-confusion -> AMI Confusion)
        chapter_title=$(echo "$basename" | sed 's/-consolidated$//' | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')

        echo "" >> "${COMBINED_MD}"
        echo "## Pattern: $chapter_title" >> "${COMBINED_MD}"
        echo "" >> "${COMBINED_MD}"
        # Demote headings so internal sections don't appear in TOC
        sed '1{/^# /d;}' "$file" | sed 's/^##### /####### /g; s/^#### /##### /g; s/^### /#### /g; s/^## /### /g; s/^# /## /g' | fix_list_spacing >> "${COMBINED_MD}"

    done <<< "$PATTERN_REPORTS"
fi

# === PART 4: SESSION REPORTS (APPENDIX) ===
if [[ -n "$SESSION_REPORTS" ]]; then
    echo "" >> "${COMBINED_MD}"
    echo "# Appendix: Session Reports" >> "${COMBINED_MD}"
    echo "" >> "${COMBINED_MD}"
    echo "Full narrative analysis of individual sessions." >> "${COMBINED_MD}"
    echo "" >> "${COMBINED_MD}"

    while IFS= read -r file; do
        basename="${file##*/}"
        basename="${basename%.md}"
        # Extract session number (S1-report -> S1)
        session_num=$(echo "$basename" | sed 's/-report$//')

        echo "" >> "${COMBINED_MD}"
        echo "## Session $session_num" >> "${COMBINED_MD}"
        echo "" >> "${COMBINED_MD}"
        # Demote headings so internal sections (Summary, Findings, Methodology) don't appear in TOC
        sed '1{/^# /d;}' "$file" | sed 's/^##### /####### /g; s/^#### /##### /g; s/^### /#### /g; s/^## /### /g; s/^# /## /g' | fix_list_spacing >> "${COMBINED_MD}"

    done <<< "$SESSION_REPORTS"
fi

# Verify concatenation
if [[ ! -s "${COMBINED_MD}" ]]; then
    echo "Error: Failed to create ${COMBINED_MD}" >&2
    exit 1
fi

WORD_COUNT=$(wc -w < "${COMBINED_MD}" | tr -d ' ')
LINE_COUNT=$(wc -l < "${COMBINED_MD}" | tr -d ' ')
echo "${COMBINED_MD} created: $WORD_COUNT words, $LINE_COUNT lines"

# Check minimum content threshold
MIN_WORDS=500
if [[ $WORD_COUNT -lt $MIN_WORDS ]]; then
    echo ""
    echo "[WARN] Content seems thin ($WORD_COUNT words < $MIN_WORDS minimum)"
    echo "       Consider checking if all reports were generated correctly."
fi

# Generate EPUB
EPUB_FILE="${EPUB_BASENAME}.epub"
echo ""
echo "Creating ${EPUB_FILE}..."

BOOK_TITLE="$PROJECT_DISPLAY - Rest Analysis - $DATE_RANGE"

pandoc "${COMBINED_MD}" \
    -o "${EPUB_FILE}" \
    --from markdown-raw_html \
    --metadata title="$BOOK_TITLE" \
    --metadata author="Claude Code Rest System" \
    --toc \
    --toc-depth=2

if [[ ! -f "${EPUB_FILE}" ]]; then
    echo "Error: Failed to create ${EPUB_FILE}" >&2
    exit 1
fi

EPUB_SIZE=$(ls -lh "${EPUB_FILE}" | awk '{print $5}')
echo "${EPUB_FILE} created: $EPUB_SIZE"

# Final summary
echo ""
echo "=== EPUB Summary ==="
echo "Project: $PROJECT_DISPLAY"
echo "Location: $REPORTS_DIR/${EPUB_FILE}"
echo "Size: $EPUB_SIZE"
echo "Words: $WORD_COUNT"
echo "Files included: $TOTAL_FILES"
[[ -n "$FINAL_REPORT" ]] && echo "  - Final report: 1"
[[ -n "$RECOMMENDATIONS" ]] && echo "  - Recommendations: 1"
[[ -n "$PATTERN_REPORTS" ]] && echo "  - Pattern reports: $(echo "$PATTERN_REPORTS" | wc -l | tr -d ' ')"
[[ -n "$SESSION_REPORTS" ]] && echo "  - Session reports: $(echo "$SESSION_REPORTS" | wc -l | tr -d ' ')"

# Open in Books.app
echo ""
echo "Opening EPUB in Books.app..."
open -a Books "${EPUB_FILE}"

echo ""
echo "Done!"
