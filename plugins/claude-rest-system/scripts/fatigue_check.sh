#!/usr/bin/env bash
# Calculate and report fatigue level based on unseen session messages
# Scans all session files and compares to analysis metadata
# Writes JSON inventory to ~/.claude/analysis/fatigue_inventory.json

set -eo pipefail

CLAUDE_DIR="${HOME}/.claude"
PROJECTS_DIR="${CLAUDE_DIR}/projects"
ARCHIVE_DIR="${CLAUDE_DIR}/session-archives"
ANALYSIS_DIR="${CLAUDE_DIR}/analysis/sessions"
INVENTORY_FILE="${CLAUDE_DIR}/analysis/fatigue_inventory.json"

# Ensure analysis directory exists
mkdir -p "${CLAUDE_DIR}/analysis"

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

# Function to get analyzed count for subagent
# Subagent metadata: ~/.claude/analysis/sessions/{main_session_id}/subagents/{subagent_id}/metadata.json
get_subagent_analyzed_count() {
    local main_session_id="$1"
    local subagent_id="$2"
    local metadata_file="${ANALYSIS_DIR}/${main_session_id}/subagents/${subagent_id}/metadata.json"

    if [ -f "$metadata_file" ]; then
        jq -r '.analyzed_through_message // 0' "$metadata_file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Function to get analysis timestamp from metadata
get_analysis_timestamp() {
    local session_id="$1"
    local metadata_file="${ANALYSIS_DIR}/${session_id}/metadata.json"
    if [ -f "$metadata_file" ]; then
        jq -r '.analysis_timestamp // ""' "$metadata_file" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Function to format timestamp as human-readable "time ago"
format_time_ago() {
    local timestamp="$1"
    [ -z "$timestamp" ] && echo "never" && return
    local then_epoch now_epoch diff
    then_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${timestamp%%.*}" "+%s" 2>/dev/null) || { echo "unknown"; return; }
    now_epoch=$(date "+%s")
    diff=$((now_epoch - then_epoch))
    if [ "$diff" -lt 60 ]; then echo "just now"
    elif [ "$diff" -lt 3600 ]; then echo "$((diff / 60))m ago"
    elif [ "$diff" -lt 86400 ]; then echo "$((diff / 3600))h ago"
    elif [ "$diff" -lt 604800 ]; then echo "$((diff / 86400))d ago"
    else echo "$((diff / 604800))w ago"
    fi
}

# Function to get parent session ID from subagent file
# Reads sessionId field from first line of JSONL
get_parent_session_id() {
    local file="$1"
    if [ -f "$file" ]; then
        head -1 "$file" 2>/dev/null | jq -r '.sessionId // empty' 2>/dev/null || echo ""
    else
        echo ""
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
declare -A subagent_files

# First, scan archives
if [ -d "${ARCHIVE_DIR}" ]; then
    while IFS= read -r -d '' file; do
        session_id=$(basename "$file" .jsonl)
        if [[ "$session_id" == agent-* ]]; then
            subagent_files["$session_id"]="$file"
        else
            session_files["$session_id"]="$file"
        fi
    done < <(find "${ARCHIVE_DIR}" -name "*.jsonl" -print0 2>/dev/null)
fi

# Then scan projects (overwrites archived versions if exists in both)
if [ -d "${PROJECTS_DIR}" ]; then
    while IFS= read -r -d '' file; do
        session_id=$(basename "$file" .jsonl)
        if [[ "$session_id" == agent-* ]]; then
            subagent_files["$session_id"]="$file"
        else
            session_files["$session_id"]="$file"
        fi
    done < <(find "${PROJECTS_DIR}" -name "*.jsonl" -print0 2>/dev/null)
fi

# Map subagents to their parent sessions
declare -A subagent_parent
for subagent_id in "${!subagent_files[@]}"; do
    file="${subagent_files[$subagent_id]}"
    parent_id=$(get_parent_session_id "$file")
    if [ -n "$parent_id" ]; then
        subagent_parent["$subagent_id"]="$parent_id"
    fi
done

# Track unseen metrics by project (main sessions)
declare -A project_sessions
declare -A project_messages
declare -A project_bytes

# Track subagent metrics separately
declare -A project_subagents
declare -A project_subagent_messages
declare -A project_subagent_bytes

# Track last analysis timestamp per project
declare -A project_last_analyzed

# Store inventory entries for JSON output
inventory_entries=()

# Process each main session
for session_id in "${!session_files[@]}"; do
    file="${session_files[$session_id]}"

    # Get message counts
    msg_count=$(get_message_count "$file")
    analyzed_count=$(get_analyzed_count "$session_id")
    unseen_count=$((msg_count - analyzed_count))

    project=$(get_project_name "$file")

    # Track most recent analysis timestamp for this project
    timestamp=$(get_analysis_timestamp "$session_id")
    if [ -n "$timestamp" ]; then
        current="${project_last_analyzed[$project]:-}"
        if [ -z "$current" ] || [[ "$timestamp" > "$current" ]]; then
            project_last_analyzed[$project]="$timestamp"
        fi
    fi

    # Find subagents for this session
    subagent_json_entries=()
    for subagent_id in "${!subagent_parent[@]}"; do
        if [ "${subagent_parent[$subagent_id]}" = "$session_id" ]; then
            sub_file="${subagent_files[$subagent_id]}"
            sub_msg_count=$(get_message_count "$sub_file")
            sub_analyzed_count=$(get_subagent_analyzed_count "$session_id" "$subagent_id")
            sub_unseen_count=$((sub_msg_count - sub_analyzed_count))

            # Add to subagent JSON array
            subagent_json_entries+=("{\"file\":\"$sub_file\",\"messages\":$sub_msg_count,\"unseen_messages\":$sub_unseen_count}")

            # Track subagent stats if unseen
            if [ "$sub_unseen_count" -gt 0 ]; then
                sub_file_size=$(get_file_size "$sub_file")

                # Initialize project subagent counters if needed
                if [ -z "${project_subagents[$project]:-}" ]; then
                    project_subagents[$project]=0
                    project_subagent_messages[$project]=0
                    project_subagent_bytes[$project]=0
                fi

                project_subagents[$project]=$((project_subagents[$project] + 1))
                project_subagent_messages[$project]=$((project_subagent_messages[$project] + sub_unseen_count))
                project_subagent_bytes[$project]=$((project_subagent_bytes[$project] + sub_file_size))
            fi
        fi
    done

    # Build subagents JSON array
    if [ ${#subagent_json_entries[@]} -gt 0 ]; then
        subagents_json=$(IFS=,; echo "[${subagent_json_entries[*]}]")
    else
        subagents_json="[]"
    fi

    # Only include in inventory if there are unseen messages (main or subagent)
    has_unseen_subagents=false
    for entry in "${subagent_json_entries[@]}"; do
        if echo "$entry" | grep -q '"unseen_messages":[1-9]'; then
            has_unseen_subagents=true
            break
        fi
    done

    if [ "$unseen_count" -gt 0 ] || [ "$has_unseen_subagents" = true ]; then
        inventory_entries+=("{\"file\":\"$file\",\"project\":\"$project\",\"unseen_messages\":$unseen_count,\"subagents\":$subagents_json}")
    fi

    # Track main session stats if unseen
    if [ "$unseen_count" -gt 0 ]; then
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

# Write JSON inventory file (idempotent - overwrites with current state)
if [ ${#inventory_entries[@]} -gt 0 ]; then
    inventory_json=$(IFS=,; echo "[${inventory_entries[*]}]")
else
    inventory_json="[]"
fi
echo "$inventory_json" | jq '.' > "$INVENTORY_FILE"

# Output report
echo "FATIGUE REPORT"
echo ""

# Calculate main session totals
total_sessions=0
total_messages=0
total_bytes=0
for project in "${!project_sessions[@]}"; do
    total_sessions=$((total_sessions + project_sessions[$project]))
    total_messages=$((total_messages + project_messages[$project]))
    total_bytes=$((total_bytes + project_bytes[$project]))
done

# Calculate subagent totals
total_subagents=0
total_subagent_messages=0
total_subagent_bytes=0
for project in "${!project_subagents[@]}"; do
    total_subagents=$((total_subagents + project_subagents[$project]))
    total_subagent_messages=$((total_subagent_messages + project_subagent_messages[$project]))
    total_subagent_bytes=$((total_subagent_bytes + project_subagent_bytes[$project]))
done

if [ "$total_sessions" -eq 0 ] && [ "$total_subagents" -eq 0 ]; then
    echo "No unseen sessions"
else
    # Show main session stats
    echo "Main Sessions:"
    if [ "$total_sessions" -eq 0 ]; then
        echo "  (none unseen)"
    else
        echo "  Sessions: ${total_sessions}"
        echo "  Messages: ${total_messages}"
        echo "  Size: $(format_bytes $total_bytes)"
    fi
    echo ""

    # Show subagent stats
    echo "Subagents:"
    if [ "$total_subagents" -eq 0 ]; then
        echo "  (none unseen)"
    else
        echo "  Subagents: ${total_subagents}"
        echo "  Messages: ${total_subagent_messages}"
        echo "  Size: $(format_bytes $total_subagent_bytes)"
    fi
    echo ""

    # Show combined totals
    combined_count=$((total_sessions + total_subagents))
    combined_messages=$((total_messages + total_subagent_messages))
    combined_bytes=$((total_bytes + total_subagent_bytes))
    echo "Combined Total:"
    echo "  Sessions + Subagents: ${combined_count}"
    echo "  Messages: ${combined_messages}"
    echo "  Size: $(format_bytes $combined_bytes)"
    echo ""

    # Show by project (sorted by combined message count descending)
    echo "By Project:"

    # Get all projects (union of main and subagent projects)
    declare -A all_projects
    for project in "${!project_sessions[@]}"; do
        all_projects[$project]=1
    done
    for project in "${!project_subagents[@]}"; do
        all_projects[$project]=1
    done

    # Create sortable list: "combined_message_count:project"
    sort_list=""
    for project in "${!all_projects[@]}"; do
        main_msgs=${project_messages[$project]:-0}
        sub_msgs=${project_subagent_messages[$project]:-0}
        combined_msgs=$((main_msgs + sub_msgs))
        sort_list+="${combined_msgs}:${project}"$'\n'
    done

    # Sort numerically descending and display
    echo "$sort_list" | sort -t: -k1 -nr | while IFS=: read -r _ project; do
        [ -z "$project" ] && continue
        sessions=${project_sessions[$project]:-0}
        messages=${project_messages[$project]:-0}
        bytes=${project_bytes[$project]:-0}
        subagents=${project_subagents[$project]:-0}
        sub_msgs=${project_subagent_messages[$project]:-0}
        sub_bytes=${project_subagent_bytes[$project]:-0}

        combined_bytes=$((bytes + sub_bytes))
        size=$(format_bytes $combined_bytes)

        last_ts="${project_last_analyzed[$project]:-}"
        last_ago=$(format_time_ago "$last_ts")
        echo "  ${project}: ${sessions} sessions (${messages} msgs), ${subagents} subagents (${sub_msgs} msgs), ${size} [last: ${last_ago}]"
    done
fi
