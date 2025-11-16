#!/usr/bin/env bash
# Find common patterns in session
# Usage: find-patterns.sh <session-file.jsonl> <pattern-type>
# Pattern types: commands, agents, errors, questions

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <session-file.jsonl> <pattern-type>"
    echo "Pattern types: commands, agents, errors, questions"
    exit 1
fi

SESSION_FILE="$1"
PATTERN="$2"

if [ ! -f "$SESSION_FILE" ]; then
    echo "Error: File not found: $SESSION_FILE"
    exit 1
fi

case "$PATTERN" in
    commands)
        echo "=== Slash Commands Used ==="
        jq -r 'select(.role == "user") | .content | select(type == "string") | select(startswith("/")) | split(" ")[0]' "$SESSION_FILE" | sort | uniq -c | sort -rn
        ;;
    agents)
        echo "=== Agents Invoked ==="
        jq -r 'select(.content[]? | type == "array") | .content[] | select(.type == "tool_use" and .name == "Task") | .input.subagent_type' "$SESSION_FILE" 2>/dev/null | sort | uniq -c | sort -rn || echo "None found"
        ;;
    errors)
        echo "=== Error Keywords ==="
        jq -r 'select(.role == "assistant") | .content | select(type == "string") | select(contains("error") or contains("Error") or contains("failed") or contains("Failed"))' "$SESSION_FILE" | wc -l | xargs echo "Messages with errors:"
        ;;
    questions)
        echo "=== User Questions ==="
        jq -r 'select(.role == "user") | .content | select(type == "string") | select(contains("?"))' "$SESSION_FILE" | head -10
        ;;
    *)
        echo "Unknown pattern type: $PATTERN"
        echo "Available: commands, agents, errors, questions"
        exit 1
        ;;
esac
