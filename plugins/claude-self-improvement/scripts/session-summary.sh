#!/usr/bin/env bash
# Quick session summary from JSONL
# Usage: session-summary.sh <session-file.jsonl>

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <session-file.jsonl>"
    exit 1
fi

SESSION_FILE="$1"

if [ ! -f "$SESSION_FILE" ]; then
    echo "Error: File not found: $SESSION_FILE"
    exit 1
fi

# Count messages by role
echo "=== Session Summary ==="
echo ""
echo "Total messages: $(wc -l < "$SESSION_FILE" | tr -d ' ')"
echo ""
echo "By role:"
jq -r '.role' "$SESSION_FILE" | sort | uniq -c | sort -rn
echo ""
echo "Tools used:"
jq -r 'select(.content[]? | type == "array") | .content[] | select(.type == "tool_use") | .name' "$SESSION_FILE" 2>/dev/null | sort | uniq -c | sort -rn || echo "  None detected"
echo ""
echo "Session duration: $(jq -r '.timestamp' "$SESSION_FILE" | head -1) to $(jq -r '.timestamp' "$SESSION_FILE" | tail -1)"
