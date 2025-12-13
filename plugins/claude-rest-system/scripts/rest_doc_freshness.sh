#!/usr/bin/env bash
#
# Check if documentation pre-dates or post-dates a session
#
# Usage:
#   rest_doc_freshness.sh <doc_file> <session_file>
#
# Output (JSON):
#   {
#     "status": "pre-dates" | "post-dates" | "not-found",
#     "doc_file": "/path/to/doc",
#     "doc_timestamp": "2025-01-10T15:30:00",
#     "session_timestamp": "2025-01-12T09:00:00"
#   }
#
# Status meanings:
#   pre-dates: Doc was last modified BEFORE the session started
#              → Incident post-dates docs, docs may be insufficient
#   post-dates: Doc was last modified AFTER the session started
#              → Docs may have been added in response to incident
#   not-found: Doc file doesn't exist
#

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <doc_file> <session_file>" >&2
    exit 1
fi

DOC_FILE="$1"
SESSION_FILE="$2"

# Expand ~ in paths
DOC_FILE="${DOC_FILE/#\~/$HOME}"
SESSION_FILE="${SESSION_FILE/#\~/$HOME}"

# Check if doc file exists
if [[ ! -f "$DOC_FILE" ]]; then
    jq -n --arg doc "$DOC_FILE" '{
        status: "not-found",
        doc_file: $doc,
        doc_timestamp: null,
        session_timestamp: null
    }'
    exit 0
fi

# Check if session file exists
if [[ ! -f "$SESSION_FILE" ]]; then
    echo "Error: Session file not found: $SESSION_FILE" >&2
    exit 1
fi

# Get doc file modification time (ISO 8601)
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS
    DOC_EPOCH=$(stat -f %m "$DOC_FILE")
    DOC_TIMESTAMP=$(date -r "$DOC_EPOCH" "+%Y-%m-%dT%H:%M:%S")
else
    # Linux
    DOC_TIMESTAMP=$(stat -c %y "$DOC_FILE" | cut -d'.' -f1 | tr ' ' 'T')
    DOC_EPOCH=$(date -d "$DOC_TIMESTAMP" +%s)
fi

# Get session first message timestamp
# Session JSONL has timestamp in each message, get the first one
FIRST_LINE=$(head -1 "$SESSION_FILE")
SESSION_TIMESTAMP=$(echo "$FIRST_LINE" | jq -r '.timestamp // empty' 2>/dev/null)

if [[ -z "$SESSION_TIMESTAMP" ]]; then
    # Try alternate field names
    SESSION_TIMESTAMP=$(echo "$FIRST_LINE" | jq -r '.ts // .time // .created_at // empty' 2>/dev/null)
fi

if [[ -z "$SESSION_TIMESTAMP" ]]; then
    echo "Error: Could not extract timestamp from session file" >&2
    exit 1
fi

# Convert session timestamp to epoch for comparison
# Handle both ISO 8601 formats: "2025-01-12T09:00:00Z" and "2025-01-12T09:00:00"
SESSION_TIMESTAMP_CLEAN=$(echo "$SESSION_TIMESTAMP" | sed 's/Z$//' | sed 's/\.[0-9]*$//')

if [[ "$(uname)" == "Darwin" ]]; then
    # macOS date -j -f format
    SESSION_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$SESSION_TIMESTAMP_CLEAN" "+%s" 2>/dev/null || echo "0")
else
    # Linux
    SESSION_EPOCH=$(date -d "$SESSION_TIMESTAMP_CLEAN" +%s 2>/dev/null || echo "0")
fi

# Compare timestamps
if [[ "$DOC_EPOCH" -lt "$SESSION_EPOCH" ]]; then
    STATUS="pre-dates"
else
    STATUS="post-dates"
fi

# Output JSON
jq -n \
    --arg status "$STATUS" \
    --arg doc "$DOC_FILE" \
    --arg doc_ts "$DOC_TIMESTAMP" \
    --arg session_ts "$SESSION_TIMESTAMP" \
    '{
        status: $status,
        doc_file: $doc,
        doc_timestamp: $doc_ts,
        session_timestamp: $session_ts
    }'
