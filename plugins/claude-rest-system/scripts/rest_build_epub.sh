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

set -euo pipefail

STORAGE="${1:-$HOME/.claude/analysis}"
STORAGE="${STORAGE/#\~/$HOME}"
REPORTS_DIR="$STORAGE/reports"

# Verify reports directory exists
if [[ ! -d "$REPORTS_DIR" ]]; then
    echo "Error: Reports directory not found: $REPORTS_DIR" >&2
    exit 1
fi

cd "$REPORTS_DIR"

# Find all rest-*.md reports
REPORT_FILES=$(find . -maxdepth 1 -name "rest-*.md" -type f | sort)

if [[ -z "$REPORT_FILES" ]]; then
    echo "Error: No rest-*.md reports found in $REPORTS_DIR" >&2
    exit 1
fi

REPORT_COUNT=$(echo "$REPORT_FILES" | wc -l | tr -d ' ')
echo "Found $REPORT_COUNT report(s) to include"

# Extract date range from filenames
# Format: rest-YYYY-MM-DD-HH-MM.md
FIRST_REPORT=$(echo "$REPORT_FILES" | head -1 | sed 's|^\./||')
LAST_REPORT=$(echo "$REPORT_FILES" | tail -1 | sed 's|^\./||')

# Extract timestamps
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

# Format date range for title
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
**Number of Reports:** $REPORT_COUNT
**Storage:** $STORAGE

## About This Book

This book contains rest analysis reports from Claude Code sessions. Each report provides:
- Learnings discovered during sessions
- Mistakes and patterns that need better steering
- Documentation suggestions
- Drill-down keywords for further investigation

Reports are organized chronologically. Use the table of contents to navigate to specific dates.

## Reports Included

$(echo "$REPORT_FILES" | sed 's|^\.\/||' | sed 's/^/- /')

---

EOF

# Concatenate all reports
while IFS= read -r file; do
    basename="${file##*/}"
    basename="${basename%.md}"

    # Extract date/time from filename
    if [[ "$basename" =~ rest-([0-9]{4}-[0-9]{2}-[0-9]{2})-([0-9]{2}-[0-9]{2}) ]]; then
        report_date="${BASH_REMATCH[1]}"
        report_time="${BASH_REMATCH[2]//-/:}"
        chapter_title="Analysis $report_date $report_time"
    else
        chapter_title="Analysis $basename"
    fi

    # Add separator and include report
    echo >> REST-ANALYSIS.md
    echo "# $chapter_title" >> REST-ANALYSIS.md
    echo >> REST-ANALYSIS.md
    # Skip the first H1 heading if present (we're replacing it with our chapter title)
    sed '1{/^# /d;}' "$file" >> REST-ANALYSIS.md

done <<< "$REPORT_FILES"

# Verify concatenation
if [[ ! -s REST-ANALYSIS.md ]]; then
    echo "Error: Failed to create REST-ANALYSIS.md" >&2
    exit 1
fi

WORD_COUNT=$(wc -w < REST-ANALYSIS.md | tr -d ' ')
echo "REST-ANALYSIS.md created: $WORD_COUNT words"

# Generate EPUB
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

# Open in Books.app
echo "Opening EPUB in Books.app..."
open -a Books REST-ANALYSIS.epub

echo "Done! EPUB location: $REPORTS_DIR/REST-ANALYSIS.epub"
