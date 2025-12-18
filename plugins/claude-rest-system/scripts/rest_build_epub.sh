#!/usr/bin/env bash
#
# Build REST-ANALYSIS.epub from rest analysis reports
#
# Usage:
#   rest_build_epub.sh [storage-path]
#
# Default storage: ~/.claude/analysis
# Output: {storage}/reports/REST-ANALYSIS.epub
#
# Includes (in order):
#   1. Final report (rest-*.md)
#   2. Recommendations (recommendations-*.md)
#   3. Pattern reports (pattern-reports/*.md)
#   4. Session reports (session-reports/*.md) - as appendix
#

set -euo pipefail

STORAGE="${1:-$HOME/.claude/analysis}"
STORAGE="${STORAGE/#\~/$HOME}"
REPORTS_DIR="$STORAGE/reports"

echo "=== REST Analysis EPUB Builder ==="
echo "Storage: $STORAGE"
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

# Check 1: Final report exists
FINAL_REPORTS=$(find . -maxdepth 1 -name "rest-*.md" -type f 2>/dev/null | sort)
if [[ -z "$FINAL_REPORTS" ]]; then
    echo "[FAIL] No rest-*.md final reports found"
    PREFLIGHT_PASS=false
else
    FINAL_COUNT=$(echo "$FINAL_REPORTS" | wc -l | tr -d ' ')
    echo "[OK] Found $FINAL_COUNT final report(s)"
fi

# Check 2: Recommendations file
RECOMMENDATIONS=$(find . -maxdepth 1 -name "recommendations-*.md" -type f 2>/dev/null | sort)
if [[ -z "$RECOMMENDATIONS" ]]; then
    WARNINGS="$WARNINGS\n[WARN] No recommendations-*.md found"
else
    REC_COUNT=$(echo "$RECOMMENDATIONS" | wc -l | tr -d ' ')
    echo "[OK] Found $REC_COUNT recommendations file(s)"
fi

# Check 3: Pattern reports
PATTERN_REPORTS=""
if [[ -d "pattern-reports" ]]; then
    PATTERN_REPORTS=$(find pattern-reports -name "*.md" -type f 2>/dev/null | sort)
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
    SESSION_REPORTS=$(find session-reports -name "*.md" -type f 2>/dev/null | sort)
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
[[ -n "$FINAL_REPORTS" ]] && TOTAL_FILES=$((TOTAL_FILES + $(echo "$FINAL_REPORTS" | wc -l)))
[[ -n "$RECOMMENDATIONS" ]] && TOTAL_FILES=$((TOTAL_FILES + $(echo "$RECOMMENDATIONS" | wc -l)))
[[ -n "$PATTERN_REPORTS" ]] && TOTAL_FILES=$((TOTAL_FILES + $(echo "$PATTERN_REPORTS" | wc -l)))
[[ -n "$SESSION_REPORTS" ]] && TOTAL_FILES=$((TOTAL_FILES + $(echo "$SESSION_REPORTS" | wc -l)))
echo "Total files to include: $TOTAL_FILES"

# Extract date range from final report filenames
FIRST_REPORT=$(echo "$FINAL_REPORTS" | head -1 | sed 's|^\./||')
LAST_REPORT=$(echo "$FINAL_REPORTS" | tail -1 | sed 's|^\./||')

if [[ "$FIRST_REPORT" =~ rest-([0-9]{4}-[0-9]{2}-[0-9]{2})-([0-9]{2}-[0-9]{2}) ]]; then
    FIRST_DATE="${BASH_REMATCH[1]}"
    FIRST_TIME="${BASH_REMATCH[2]//-/:}"
else
    FIRST_DATE="unknown"
    FIRST_TIME=""
fi

if [[ "$LAST_REPORT" =~ rest-([0-9]{4}-[0-9]{2}-[0-9]{2})-([0-9]{2}-[0-9]{2}) ]]; then
    LAST_DATE="${BASH_REMATCH[1]}"
    LAST_TIME="${BASH_REMATCH[2]//-/:}"
else
    LAST_DATE="unknown"
    LAST_TIME=""
fi

if [[ "$FIRST_DATE" == "$LAST_DATE" ]]; then
    if [[ -n "$FIRST_TIME" ]]; then
        DATE_RANGE="$FIRST_DATE $FIRST_TIME"
    else
        DATE_RANGE="$FIRST_DATE"
    fi
else
    DATE_RANGE="$FIRST_DATE to $LAST_DATE"
fi

GENERATION_TIME=$(date "+%Y-%m-%d %H:%M:%S")

# Create combined markdown file
echo "Creating REST-ANALYSIS.md..."

cat > REST-ANALYSIS.md << EOF
# Rest Analysis Reports

## Book Information

**Generated:** $GENERATION_TIME
**Date Range:** $DATE_RANGE
**Storage:** $STORAGE

## Contents

This book contains:
EOF

# Add content summary
[[ -n "$FINAL_REPORTS" ]] && echo "- **Final Reports:** $(echo "$FINAL_REPORTS" | wc -l | tr -d ' ')" >> REST-ANALYSIS.md
[[ -n "$RECOMMENDATIONS" ]] && echo "- **Recommendations:** $(echo "$RECOMMENDATIONS" | wc -l | tr -d ' ')" >> REST-ANALYSIS.md
[[ -n "$PATTERN_REPORTS" ]] && echo "- **Pattern Reports:** $(echo "$PATTERN_REPORTS" | wc -l | tr -d ' ')" >> REST-ANALYSIS.md
[[ -n "$SESSION_REPORTS" ]] && echo "- **Session Reports:** $(echo "$SESSION_REPORTS" | wc -l | tr -d ' ') (appendix)" >> REST-ANALYSIS.md

cat >> REST-ANALYSIS.md << 'EOF'

## How to Use This Book

1. **Start with the Final Report** - Executive summary and key findings
2. **Review Recommendations** - Actionable items to implement
3. **Explore Patterns** - Cross-session themes and root causes
4. **Dive into Sessions** - Full narrative analysis of individual sessions

---

EOF

# === PART 1: FINAL REPORTS ===
if [[ -n "$FINAL_REPORTS" ]]; then
    echo "" >> REST-ANALYSIS.md
    echo "# Part I: Analysis Reports" >> REST-ANALYSIS.md
    echo "" >> REST-ANALYSIS.md

    while IFS= read -r file; do
        basename="${file##*/}"
        basename="${basename%.md}"

        if [[ "$basename" =~ rest-([0-9]{4}-[0-9]{2}-[0-9]{2})-([0-9]{2}-[0-9]{2}) ]]; then
            report_date="${BASH_REMATCH[1]}"
            report_time="${BASH_REMATCH[2]//-/:}"
            chapter_title="Analysis: $report_date $report_time"
        else
            chapter_title="Analysis: $basename"
        fi

        echo "" >> REST-ANALYSIS.md
        echo "## $chapter_title" >> REST-ANALYSIS.md
        echo "" >> REST-ANALYSIS.md
        # Skip the first H1 heading, demote remaining headings so they don't clutter TOC
        sed '1{/^# /d;}' "$file" | sed 's/^#### /##### /g; s/^### /#### /g; s/^## /### /g' >> REST-ANALYSIS.md

    done <<< "$FINAL_REPORTS"
fi

# === PART 2: RECOMMENDATIONS ===
if [[ -n "$RECOMMENDATIONS" ]]; then
    echo "" >> REST-ANALYSIS.md
    echo "# Part II: Recommendations" >> REST-ANALYSIS.md
    echo "" >> REST-ANALYSIS.md

    while IFS= read -r file; do
        basename="${file##*/}"
        basename="${basename%.md}"

        if [[ "$basename" =~ recommendations-([0-9]{4}-[0-9]{2}-[0-9]{2})-([0-9]{2}-[0-9]{2}) ]]; then
            rec_date="${BASH_REMATCH[1]}"
            rec_time="${BASH_REMATCH[2]//-/:}"
            chapter_title="Recommendations: $rec_date $rec_time"
        else
            chapter_title="Recommendations"
        fi

        echo "" >> REST-ANALYSIS.md
        echo "## $chapter_title" >> REST-ANALYSIS.md
        echo "" >> REST-ANALYSIS.md
        # Demote headings so internal sections don't appear in TOC
        sed '1{/^# /d;}' "$file" | sed 's/^#### /##### /g; s/^### /#### /g; s/^## /### /g' >> REST-ANALYSIS.md

    done <<< "$RECOMMENDATIONS"
fi

# === PART 3: PATTERN REPORTS ===
if [[ -n "$PATTERN_REPORTS" ]]; then
    echo "" >> REST-ANALYSIS.md
    echo "# Part III: Cross-Session Patterns" >> REST-ANALYSIS.md
    echo "" >> REST-ANALYSIS.md
    echo "These reports consolidate findings that appeared across multiple sessions." >> REST-ANALYSIS.md
    echo "" >> REST-ANALYSIS.md

    while IFS= read -r file; do
        basename="${file##*/}"
        basename="${basename%.md}"
        # Convert slug to title (ami-confusion -> AMI Confusion)
        chapter_title=$(echo "$basename" | sed 's/-consolidated$//' | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')

        echo "" >> REST-ANALYSIS.md
        echo "## Pattern: $chapter_title" >> REST-ANALYSIS.md
        echo "" >> REST-ANALYSIS.md
        # Demote headings so internal sections don't appear in TOC
        sed '1{/^# /d;}' "$file" | sed 's/^#### /##### /g; s/^### /#### /g; s/^## /### /g' >> REST-ANALYSIS.md

    done <<< "$PATTERN_REPORTS"
fi

# === PART 4: SESSION REPORTS (APPENDIX) ===
if [[ -n "$SESSION_REPORTS" ]]; then
    echo "" >> REST-ANALYSIS.md
    echo "# Appendix: Session Reports" >> REST-ANALYSIS.md
    echo "" >> REST-ANALYSIS.md
    echo "Full narrative analysis of individual sessions." >> REST-ANALYSIS.md
    echo "" >> REST-ANALYSIS.md

    while IFS= read -r file; do
        basename="${file##*/}"
        basename="${basename%.md}"
        # Extract session number (S1-report -> S1)
        session_num=$(echo "$basename" | sed 's/-report$//')

        echo "" >> REST-ANALYSIS.md
        echo "## Session $session_num" >> REST-ANALYSIS.md
        echo "" >> REST-ANALYSIS.md
        # Demote headings so internal sections (Summary, Findings, Methodology) don't appear in TOC
        sed '1{/^# /d;}' "$file" | sed 's/^#### /##### /g; s/^### /#### /g; s/^## /### /g' >> REST-ANALYSIS.md

    done <<< "$SESSION_REPORTS"
fi

# Verify concatenation
if [[ ! -s REST-ANALYSIS.md ]]; then
    echo "Error: Failed to create REST-ANALYSIS.md" >&2
    exit 1
fi

WORD_COUNT=$(wc -w < REST-ANALYSIS.md | tr -d ' ')
LINE_COUNT=$(wc -l < REST-ANALYSIS.md | tr -d ' ')
echo "REST-ANALYSIS.md created: $WORD_COUNT words, $LINE_COUNT lines"

# Check minimum content threshold
MIN_WORDS=500
if [[ $WORD_COUNT -lt $MIN_WORDS ]]; then
    echo ""
    echo "[WARN] Content seems thin ($WORD_COUNT words < $MIN_WORDS minimum)"
    echo "       Consider checking if all reports were generated correctly."
fi

# Generate EPUB
echo ""
echo "Creating REST-ANALYSIS.epub..."

BOOK_TITLE="Rest Analysis Reports - $DATE_RANGE"

pandoc REST-ANALYSIS.md \
    -o REST-ANALYSIS.epub \
    --metadata title="$BOOK_TITLE" \
    --metadata author="Claude Code Rest System" \
    --toc \
    --toc-depth=2

if [[ ! -f REST-ANALYSIS.epub ]]; then
    echo "Error: Failed to create REST-ANALYSIS.epub" >&2
    exit 1
fi

EPUB_SIZE=$(ls -lh REST-ANALYSIS.epub | awk '{print $5}')
echo "REST-ANALYSIS.epub created: $EPUB_SIZE"

# Final summary
echo ""
echo "=== EPUB Summary ==="
echo "Location: $REPORTS_DIR/REST-ANALYSIS.epub"
echo "Size: $EPUB_SIZE"
echo "Words: $WORD_COUNT"
echo "Files included: $TOTAL_FILES"
[[ -n "$FINAL_REPORTS" ]] && echo "  - Final reports: $(echo "$FINAL_REPORTS" | wc -l | tr -d ' ')"
[[ -n "$RECOMMENDATIONS" ]] && echo "  - Recommendations: $(echo "$RECOMMENDATIONS" | wc -l | tr -d ' ')"
[[ -n "$PATTERN_REPORTS" ]] && echo "  - Pattern reports: $(echo "$PATTERN_REPORTS" | wc -l | tr -d ' ')"
[[ -n "$SESSION_REPORTS" ]] && echo "  - Session reports: $(echo "$SESSION_REPORTS" | wc -l | tr -d ' ')"

# Open in Books.app
echo ""
echo "Opening EPUB in Books.app..."
open -a Books REST-ANALYSIS.epub

echo ""
echo "Done!"
