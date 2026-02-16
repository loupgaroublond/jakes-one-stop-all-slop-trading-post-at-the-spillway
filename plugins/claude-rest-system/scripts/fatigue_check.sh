#!/usr/bin/env bash
# Copyright (c) 2026 Yaakov M Nemoy
# SPDX-License-Identifier: LicenseRef-JNNNL-1.0
# Calculate and report fatigue level based on unseen session messages
# Scans all session files and compares to analysis metadata
# Writes JSON inventory to ~/.claude/analysis/fatigue_inventory.json
#
# Project groups are loaded from ~/.claude/project-peers.json to:
# - Unify sessions from different locations under a single project name
# - Filter other-machines to only include configured peers
# - Show human-friendly project names in output

set -eo pipefail

CLAUDE_DIR="${HOME}/.claude"
PROJECTS_DIR="${CLAUDE_DIR}/projects"
ARCHIVE_DIR="${CLAUDE_DIR}/session-archives"
ANALYSIS_DIR="${CLAUDE_DIR}/analysis/sessions"
INVENTORY_FILE="${CLAUDE_DIR}/analysis/fatigue_inventory.json"
PROJECT_PEERS_FILE="${CLAUDE_DIR}/project-peers.json"

# Ensure analysis directory exists
mkdir -p "${CLAUDE_DIR}/analysis"

# Reverse lookup: "machine:encoded_path" -> "project_name"
declare -A path_to_project

# Reverse lookup: "machine:encoded_path" -> "display_name" (human-friendly)
declare -A path_to_display_name

# Forward lookup: "project_name" -> space-separated list of machines
declare -A project_machines

# Load project groups from ~/.claude/project-peers.json
# Schema: { "project-name": { "machine": [{"path": "...", "name": "..."}, ...], ... }, ... }
# Also supports legacy format: { "project-name": { "machine": ["path1", "path2"], ... }, ... }
load_project_groups() {
    if [ ! -f "$PROJECT_PEERS_FILE" ]; then
        return
    fi

    # Parse the JSON and build lookup tables
    # Handles both new format (objects with path/name) and legacy (plain strings)
    while IFS= read -r line; do
        local project machine path display_name
        project=$(echo "$line" | jq -r '.project')
        machine=$(echo "$line" | jq -r '.machine')
        path=$(echo "$line" | jq -r '.path')
        display_name=$(echo "$line" | jq -r '.name // empty')

        if [ -n "$project" ] && [ -n "$machine" ] && [ -n "$path" ]; then
            local key="${machine}:${path}"
            path_to_project["$key"]="$project"

            # Store display name if provided
            if [ -n "$display_name" ]; then
                path_to_display_name["$key"]="$display_name"
            fi

            # Track machines for each project
            local existing="${project_machines[$project]:-}"
            if [ -z "$existing" ]; then
                project_machines[$project]="$machine"
            elif [[ ! " $existing " =~ " $machine " ]]; then
                project_machines[$project]="$existing $machine"
            fi
        fi
    done < <(jq -c '
        to_entries[] |
        .key as $project |
        .value | to_entries[] |
        .key as $machine |
        .value[] |
        if type == "object" then
            {project: $project, machine: $machine, path: .path, name: .name}
        else
            {project: $project, machine: $machine, path: ., name: null}
        end
    ' "$PROJECT_PEERS_FILE" 2>/dev/null)
}

# Check if an other-machines path is a configured peer
is_configured_peer() {
    local machine="$1"
    local encoded_path="$2"
    local key="${machine}:${encoded_path}"
    [ -n "${path_to_project[$key]:-}" ]
}

# Get friendly project name from encoded path
# Strips common prefixes (Users, Documents, Projects, etc.) and returns the project portion
# e.g., "-Users-yankee-Documents-Projects-grug-brained-employee" -> "grug-brained-employee"
# e.g., "-Users-yankee-Documents-Projects-jakes-one-stop-all-slop-trading-post-at-the-spillway" -> "jakes-one-stop-all-slop-trading-post-at-the-spillway"
get_friendly_name_from_path() {
    local encoded_path="$1"

    # Remove leading dash
    encoded_path="${encoded_path#-}"

    # Split by dashes
    local segments
    IFS='-' read -ra segments <<< "$encoded_path"

    # Find where the actual project name starts (after common prefixes)
    local project_start=-1
    # Common path segments to skip (handles both regular paths and iCloud paths)
    local common_prefixes="Users Documents Projects Library Mobile CloudDocs com apple"

    for ((i=0; i<${#segments[@]}; i++)); do
        local seg="${segments[i]}"
        # Skip empty segments and common path components
        if [ -z "$seg" ]; then
            continue
        fi

        # Check if this is a common prefix we should skip
        local is_common=false
        for prefix in $common_prefixes; do
            if [ "$seg" = "$prefix" ]; then
                is_common=true
                break
            fi
        done

        # Also skip username-like segments (typically follows "Users")
        if [ $i -gt 0 ] && [ "${segments[i-1]}" = "Users" ]; then
            is_common=true
        fi

        if [ "$is_common" = false ]; then
            project_start=$i
            break
        fi
    done

    # If we found a project start, join from there to end
    if [ $project_start -ge 0 ]; then
        local result=""
        for ((i=project_start; i<${#segments[@]}; i++)); do
            if [ -n "${segments[i]}" ]; then
                if [ -n "$result" ]; then
                    result="${result}-${segments[i]}"
                else
                    result="${segments[i]}"
                fi
            fi
        done
        echo "$result"
    else
        # Fallback: just return the last non-empty segment
        for ((i=${#segments[@]}-1; i>=0; i--)); do
            if [ -n "${segments[i]}" ]; then
                echo "${segments[i]}"
                return
            fi
        done
        echo "unknown"
    fi
}

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

# Function to extract project info from file path
# Uses project groups lookup for configured paths, falls back to auto-naming
# Returns: "project_name|machine|encoded_path" (pipe-separated for parsing)
get_project_info() {
    local file="$1"
    local machine=""
    local encoded_path=""
    local project_name=""

    # Check for other-machines path first
    if [[ "$file" =~ /session-archives/other-machines/([^/]+)/([^/]+)/ ]]; then
        machine="${BASH_REMATCH[1]}"
        encoded_path="${BASH_REMATCH[2]}"

        # Check if this is a configured peer
        local key="${machine}:${encoded_path}"
        if [ -n "${path_to_project[$key]:-}" ]; then
            project_name="${path_to_project[$key]}"
        else
            # Not configured - return empty to signal exclusion
            echo ""
            return
        fi
    elif [[ "$file" =~ /projects/([^/]+)/ ]]; then
        encoded_path="${BASH_REMATCH[1]}"
        machine="local"

        # Check if this is in a project group
        local key="local:${encoded_path}"
        if [ -n "${path_to_project[$key]:-}" ]; then
            project_name="${path_to_project[$key]}"
        else
            # Auto-name from path
            project_name=$(get_friendly_name_from_path "$encoded_path")
        fi
    elif [[ "$file" =~ /session-archives/([^/]+)/ ]]; then
        encoded_path="${BASH_REMATCH[1]}"
        # Skip "other-machines" directory itself
        if [ "$encoded_path" = "other-machines" ]; then
            echo ""
            return
        fi
        machine="local"

        # Check if this is in a project group
        local key="local:${encoded_path}"
        if [ -n "${path_to_project[$key]:-}" ]; then
            project_name="${path_to_project[$key]}"
        else
            # Auto-name from path
            project_name=$(get_friendly_name_from_path "$encoded_path")
        fi
    else
        echo "unknown||"
        return
    fi

    # Return all three values pipe-separated
    echo "${project_name}|${machine}|${encoded_path}"
}

# Track which machines contributed to each project (during session scan)
declare -A observed_project_machines

# Load project groups configuration
load_project_groups

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

# Track unseen metrics by project (main sessions) - rollup totals
declare -A project_sessions
declare -A project_messages
declare -A project_bytes

# Track subagent metrics separately - rollup totals
declare -A project_subagents
declare -A project_subagent_messages
declare -A project_subagent_bytes

# Track last analysis timestamp per project
declare -A project_last_analyzed

# Track per-location stats within each project
# Keys are "project|machine:path" for uniqueness
declare -A location_sessions
declare -A location_messages
declare -A location_bytes
declare -A location_subagents
declare -A location_subagent_messages
declare -A location_subagent_bytes

# Track which locations belong to each project (space-separated "machine:path" entries)
declare -A project_locations

# Store inventory entries for JSON output
inventory_entries=()

# Process each main session
for session_id in "${!session_files[@]}"; do
    file="${session_files[$session_id]}"

    # Get project info (returns "project|machine|encoded_path")
    project_info=$(get_project_info "$file")

    # Skip unconfigured other-machines sessions (empty result)
    if [ -z "$project_info" ]; then
        continue
    fi

    # Parse pipe-separated values
    IFS='|' read -r project project_machine project_encoded_path <<< "$project_info"

    # Skip if project is empty
    if [ -z "$project" ]; then
        continue
    fi

    # Build location key for per-location tracking
    location_key="${project_machine}:${project_encoded_path}"
    full_key="${project}|${location_key}"

    # Track which locations belong to this project
    existing_locations="${project_locations[$project]:-}"
    if [ -z "$existing_locations" ]; then
        project_locations[$project]="$location_key"
    elif [[ ! " $existing_locations " =~ " $location_key " ]]; then
        project_locations[$project]="$existing_locations $location_key"
    fi

    # Track which machines contributed to this project (for summary)
    if [ -n "$project_machine" ]; then
        existing_machines="${observed_project_machines[$project]:-}"
        if [ -z "$existing_machines" ]; then
            observed_project_machines[$project]="$project_machine"
        elif [[ ! " $existing_machines " =~ " $project_machine " ]]; then
            observed_project_machines[$project]="$existing_machines $project_machine"
        fi
    fi

    # Get message counts
    msg_count=$(get_message_count "$file")
    analyzed_count=$(get_analyzed_count "$session_id")
    unseen_count=$((msg_count - analyzed_count))

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

                # Initialize project subagent counters if needed (rollup)
                if [ -z "${project_subagents[$project]:-}" ]; then
                    project_subagents[$project]=0
                    project_subagent_messages[$project]=0
                    project_subagent_bytes[$project]=0
                fi

                # Accumulate project-level (rollup)
                project_subagents[$project]=$((project_subagents[$project] + 1))
                project_subagent_messages[$project]=$((project_subagent_messages[$project] + sub_unseen_count))
                project_subagent_bytes[$project]=$((project_subagent_bytes[$project] + sub_file_size))

                # Initialize location subagent counters if needed
                if [ -z "${location_subagents[$full_key]:-}" ]; then
                    location_subagents[$full_key]=0
                    location_subagent_messages[$full_key]=0
                    location_subagent_bytes[$full_key]=0
                fi

                # Accumulate per-location
                location_subagents[$full_key]=$((location_subagents[$full_key] + 1))
                location_subagent_messages[$full_key]=$((location_subagent_messages[$full_key] + sub_unseen_count))
                location_subagent_bytes[$full_key]=$((location_subagent_bytes[$full_key] + sub_file_size))
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

        # Initialize project counters if needed (rollup)
        if [ -z "${project_sessions[$project]:-}" ]; then
            project_sessions[$project]=0
            project_messages[$project]=0
            project_bytes[$project]=0
        fi

        # Accumulate project-level (rollup)
        project_sessions[$project]=$((project_sessions[$project] + 1))
        project_messages[$project]=$((project_messages[$project] + unseen_count))
        project_bytes[$project]=$((project_bytes[$project] + file_size))

        # Initialize location counters if needed
        if [ -z "${location_sessions[$full_key]:-}" ]; then
            location_sessions[$full_key]=0
            location_messages[$full_key]=0
            location_bytes[$full_key]=0
        fi

        # Accumulate per-location
        location_sessions[$full_key]=$((location_sessions[$full_key] + 1))
        location_messages[$full_key]=$((location_messages[$full_key] + unseen_count))
        location_bytes[$full_key]=$((location_bytes[$full_key] + file_size))
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

    # Show by project with hierarchical breakdown
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

    # Sort numerically descending and display hierarchically
    # Use process substitution to avoid subshell (needed to access associative arrays)
    first_project=true
    while IFS=: read -r _ project; do
        [ -z "$project" ] && continue

        # Get rollup stats
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

        # Blank line between projects (not before first)
        if [ "$first_project" = true ]; then
            first_project=false
        else
            echo ""
        fi

        # === PROJECT HEADER ===
        echo ""
        printf "  ┌─ %s " "$project"
        # Fill with dashes to create visual separator
        name_len=${#project}
        dash_count=$((72 - name_len))
        for ((i=0; i<dash_count; i++)); do printf "─"; done
        printf " [%s]\n" "$last_ago"
        printf "  │\n"

        # === COLUMN HEADERS FOR THIS PROJECT ===
        printf "  │ %-40s  %-8s %8s %6s %9s %8s %8s\n" "Location" "Machine" "Sessions" "Msgs" "Subagents" "Sub Msgs" "Size"
        printf "  │ %-40s  %-8s %8s %6s %9s %8s %8s\n" "────────────────────────────────────────" "────────" "────────" "──────" "─────────" "────────" "────────"

        # === PER-LOCATION ROWS ===
        locations="${project_locations[$project]:-}"
        for loc in $locations; do
            full_key="${project}|${loc}"

            loc_sessions=${location_sessions[$full_key]:-0}
            loc_messages=${location_messages[$full_key]:-0}
            loc_bytes=${location_bytes[$full_key]:-0}
            loc_subagents=${location_subagents[$full_key]:-0}
            loc_sub_msgs=${location_subagent_messages[$full_key]:-0}
            loc_sub_bytes=${location_subagent_bytes[$full_key]:-0}

            loc_combined_bytes=$((loc_bytes + loc_sub_bytes))
            loc_size=$(format_bytes $loc_combined_bytes)

            # Parse machine:path from location key
            machine="${loc%%:*}"
            encoded_path="${loc#*:}"

            # Use display name if configured, otherwise truncate encoded path
            display_name="${path_to_display_name[$loc]:-}"
            if [ -n "$display_name" ]; then
                display_path="$display_name"
            else
                display_path="$encoded_path"
                if [ ${#display_path} -gt 40 ]; then
                    display_path="...${display_path: -37}"
                fi
            fi

            printf "  │ %-40s  %-8s %8d %6d %9d %8d %8s\n" \
                "$display_path" "$machine" "$loc_sessions" "$loc_messages" "$loc_subagents" "$loc_sub_msgs" "$loc_size"
        done

        # === TOTAL ROW ===
        printf "  ├─%-40s──%-8s─%8s─%6s─%9s─%8s─%8s\n" "────────────────────────────────────────" "────────" "────────" "──────" "─────────" "────────" "────────"
        printf "  └ %-40s  %-8s %8d %6d %9d %8d %8s\n" \
            "TOTAL" "" "$sessions" "$messages" "$subagents" "$sub_msgs" "$size"

    done < <(echo "$sort_list" | sort -t: -k1 -nr)
fi
