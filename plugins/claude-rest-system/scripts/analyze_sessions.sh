#!/bin/bash
# Copyright (c) 2026 Yaakov M Nemoy
# SPDX-License-Identifier: LicenseRef-JNNNL-1.0
# Analyze session files and update metadata (STUB VERSION)
# This is a placeholder - actual analysis logic will be implemented in v2.0

set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
PROJECTS_DIR="${CLAUDE_DIR}/projects"
ARCHIVE_DIR="${CLAUDE_DIR}/session-archives"
ANALYSIS_DIR="${CLAUDE_DIR}/analysis/sessions"

# Parse arguments
MODE="unseen"
SPECIFIC_SESSION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            MODE="all"
            shift
            ;;
        --session-id)
            MODE="specific"
            SPECIFIC_SESSION="$2"
            shift 2
            ;;
        --unseen-only)
            MODE="unseen"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--all | --session-id SESSION_ID | --unseen-only]"
            exit 1
            ;;
    esac
done

echo "═══════════════════════════════════════════════════"
echo "  SESSION ANALYSIS (STUB)"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Mode: ${MODE}"
echo ""

# Helper function to get message count
get_message_count() {
    local file="$1"
    local count
    if [ -f "$file" ]; then
        count=$(grep -c . "$file" 2>/dev/null) || count=0
        echo "$count"
    else
        echo "0"
    fi
}

# Helper function to get analyzed count
get_analyzed_count() {
    local session_id="$1"
    local metadata_file="${ANALYSIS_DIR}/${session_id}/metadata.json"

    if [ -f "$metadata_file" ]; then
        jq -r '.analyzed_through_message // 0' "$metadata_file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Helper function to update metadata
update_metadata() {
    local session_id="$1"
    local analyzed_through="$2"
    local total_messages="$3"
    local session_dir="${ANALYSIS_DIR}/${session_id}"
    local metadata_file="${session_dir}/metadata.json"

    mkdir -p "${session_dir}"

    cat > "$metadata_file" <<EOF
{
  "session_id": "${session_id}",
  "analyzed_through_message": ${analyzed_through},
  "total_messages_at_analysis": ${total_messages},
  "analysis_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "analysis_version": "v2.0-stub"
}
EOF

    echo "  ✓ Updated metadata: ${session_id}"
}

# Collect sessions to analyze
declare -A session_files

# Scan archives
if [ -d "${ARCHIVE_DIR}" ]; then
    while IFS= read -r -d '' file; do
        session_id=$(basename "$file" .jsonl)
        session_files["$session_id"]="$file"
    done < <(find "${ARCHIVE_DIR}" -name "*.jsonl" -type f -print0)
fi

# Scan projects (overwrites archived versions)
if [ -d "${PROJECTS_DIR}" ]; then
    while IFS= read -r -d '' file; do
        session_id=$(basename "$file" .jsonl)
        session_files["$session_id"]="$file"
    done < <(find "${PROJECTS_DIR}" -name "*.jsonl" -type f -print0)
fi

# Process sessions based on mode
analyzed_count=0
skipped_count=0

for session_id in "${!session_files[@]}"; do
    file="${session_files[$session_id]}"

    # Skip if specific session requested and this isn't it
    if [ "$MODE" = "specific" ] && [ "$session_id" != "$SPECIFIC_SESSION" ]; then
        continue
    fi

    # Get message counts
    total_msg=$(get_message_count "$file")
    analyzed_msg=$(get_analyzed_count "$session_id")
    unseen_msg=$((total_msg - analyzed_msg))

    # Skip if unseen-only mode and no unseen messages
    if [ "$MODE" = "unseen" ] && [ "$unseen_msg" -eq 0 ]; then
        ((skipped_count++))
        continue
    fi

    # STUB: In real implementation, this is where analysis would happen
    # For now, just mark everything as analyzed

    echo "Analyzing ${session_id}:"
    echo "  Messages: ${unseen_msg} unseen (${analyzed_msg} → ${total_msg})"
    echo "  [STUB] Would analyze messages ${analyzed_msg}-${total_msg} here"

    # Update metadata to mark as analyzed
    update_metadata "$session_id" "$total_msg" "$total_msg"

    ((analyzed_count++))
done

echo ""
echo "───────────────────────────────────────────────────"
echo "Analysis complete!"
echo "  Analyzed: ${analyzed_count} sessions"
echo "  Skipped: ${skipped_count} sessions (already seen)"
echo ""
echo "NOTE: This is a STUB implementation."
echo "Real analysis logic will be implemented in the future."
