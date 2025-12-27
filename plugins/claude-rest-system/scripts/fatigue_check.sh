#!/usr/bin/env bash
# Calculate and report fatigue level based on unseen session messages
# Scans all session files and compares to analysis metadata

set -eo pipefail

CLAUDE_DIR="${HOME}/.claude"
PROJECTS_DIR="${CLAUDE_DIR}/projects"
ARCHIVE_DIR="${CLAUDE_DIR}/session-archives"
ANALYSIS_DIR="${CLAUDE_DIR}/analysis/sessions"

# Function to get message count from JSONL file
get_message_count() {
    local file="$1"
    local count
    if [ -f "$file" ]; then
        count=$(grep -c . "$file" 2>/dev/null) || count=0
        echo "${count:-0}"
    else
        echo "0"
    fi
}

# Function to get file size in bytes
get_file_size() {
    local file="$1"
    if [ -f "$file" ]; then
        stat -f%z "$file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Function to format bytes to human-readable
format_bytes() {
    local bytes="$1"
    if [ "$bytes" -lt 1024 ]; then
        echo "${bytes}B"
    elif [ "$bytes" -lt 1048576 ]; then
        echo "$(( bytes / 1024 ))KB"
    elif [ "$bytes" -lt 1073741824 ]; then
        echo "$(( bytes / 1048576 ))MB"
    else
        echo "$(( bytes / 1073741824 ))GB"
    fi
}

# Function to get analyzed count from metadata
get_analyzed_count() {
    local session_id="$1"
    local metadata_file="${ANALYSIS_DIR}/${session_id}/metadata.json"

    if [ -f "$metadata_file" ]; then
        jq -r '.analyzed_through_message // 0' "$metadata_file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Function to extract project name from file path
# For other-machines, includes machine name: "machine:project"
get_project_name() {
    local file="$1"
    # Check for other-machines path first
    if [[ "$file" =~ /session-archives/other-machines/([^/]+)/([^/]+)/ ]]; then
        local machine="${BASH_REMATCH[1]}"
        local project="${BASH_REMATCH[2]}"
        echo "${machine}:${project}"
    elif [[ "$file" =~ /projects/([^/]+)/ ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ "$file" =~ /session-archives/([^/]+)/ ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "unknown"
    fi
}

# Collect all unique session files (prefer projects/ over archives/)
declare -A session_files

# First, scan archives
if [ -d "${ARCHIVE_DIR}" ]; then
    while IFS= read -r -d '' file; do
        session_id=$(basename "$file" .jsonl)
        session_files["$session_id"]="$file"
    done < <(find "${ARCHIVE_DIR}" -name "*.jsonl" -print0 2>/dev/null)
fi

# Then scan projects (overwrites archived versions if exists in both)
if [ -d "${PROJECTS_DIR}" ]; then
    while IFS= read -r -d '' file; do
        session_id=$(basename "$file" .jsonl)
        session_files["$session_id"]="$file"
    done < <(find "${PROJECTS_DIR}" -name "*.jsonl" -print0 2>/dev/null)
fi

# Track unseen metrics by project
declare -A project_sessions
declare -A project_messages
declare -A project_bytes

# Process each unique session
for session_id in "${!session_files[@]}"; do
    file="${session_files[$session_id]}"

    # Skip subagent sessions (will be analyzed separately later)
    if [[ "$session_id" == agent-* ]]; then
        continue
    fi

    # Get message counts
    msg_count=$(get_message_count "$file")
    analyzed_count=$(get_analyzed_count "$session_id")
    unseen_count=$((msg_count - analyzed_count))

    # Only track if there are unseen messages
    if [ "$unseen_count" -gt 0 ]; then
        project=$(get_project_name "$file")
        file_size=$(get_file_size "$file")

        # Initialize project counters if needed
        if [ -z "${project_sessions[$project]:-}" ]; then
            project_sessions[$project]=0
            project_messages[$project]=0
            project_bytes[$project]=0
        fi

        # Accumulate by project
        project_sessions[$project]=$((project_sessions[$project] + 1))
        project_messages[$project]=$((project_messages[$project] + unseen_count))
        project_bytes[$project]=$((project_bytes[$project] + file_size))
    fi
done

# Output report
echo "FATIGUE REPORT"
echo ""

if [ "${#project_sessions[@]}" -eq 0 ]; then
    echo "No unseen sessions"
else
    # Calculate totals
    total_sessions=0
    total_messages=0
    total_bytes=0

    for project in "${!project_sessions[@]}"; do
        total_sessions=$((total_sessions + project_sessions[$project]))
        total_messages=$((total_messages + project_messages[$project]))
        total_bytes=$((total_bytes + project_bytes[$project]))
    done

    # Show totals
    echo "Total Unseen:"
    echo "  Sessions: ${total_sessions}"
    echo "  Messages: ${total_messages}"
    echo "  Size: $(format_bytes $total_bytes)"
    echo ""

    # Show by project (sorted by message count descending)
    echo "By Project:"

    # Create sortable list: "message_count:project"
    sort_list=""
    for project in "${!project_messages[@]}"; do
        sort_list+="${project_messages[$project]}:${project}"$'\n'
    done

    # Sort numerically descending and display
    echo "$sort_list" | sort -t: -k1 -nr | while IFS=: read -r _ project; do
        [ -z "$project" ] && continue
        sessions=${project_sessions[$project]}
        messages=${project_messages[$project]}
        bytes=${project_bytes[$project]}
        size=$(format_bytes $bytes)
        echo "  ${project}: ${sessions} sessions, ${messages} messages, ${size}"
    done
fi
