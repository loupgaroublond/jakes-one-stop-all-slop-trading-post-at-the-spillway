#!/usr/bin/env bash
# Pipeline Dashboard Generator
# Parses YAML frontmatter from active pipeline docs and computes state.
# Output: JSON summary or formatted markdown dashboard.
#
# Usage: ./dashboard.sh [--json | --markdown]
#   --json      Output raw JSON (default)
#   --markdown  Output formatted markdown dashboard to stdout AND write to specs/pipeline/dashboard.md

set -euo pipefail

# Discover the project root by walking up from the current working directory
# until we find a specs/ directory (the convention enforced by /shit:init).
PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && [ ! -d "$PROJECT_ROOT/specs" ]; do
    PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done

if [ ! -d "$PROJECT_ROOT/specs" ]; then
    echo "Error: no specs/ directory found in any parent of the current working directory." >&2
    echo "Run /shit:init from your project root to scaffold the specs/ tree." >&2
    exit 1
fi

ACTIVE_DIR="$PROJECT_ROOT/specs/pipeline/active"
ARCHIVE_DIR="$PROJECT_ROOT/specs/pipeline/archive"
DASHBOARD_FILE="$PROJECT_ROOT/specs/pipeline/dashboard.md"

OUTPUT_FORMAT="${1:---json}"

# Extract YAML frontmatter value from a pipeline doc
# Usage: frontmatter_value <file> <key>
frontmatter_value() {
    local file="$1"
    local key="$2"
    sed -n '/^---$/,/^---$/p' "$file" | grep "^${key}:" | head -1 | sed "s/^${key}: *//" | sed 's/^"\(.*\)"$/\1/'
}

# Extract list field from YAML frontmatter (returns comma-separated)
# Usage: frontmatter_list <file> <key>
frontmatter_list() {
    local file="$1"
    local key="$2"
    sed -n '/^---$/,/^---$/p' "$file" | grep "^${key}:" | head -1 | sed "s/^${key}: *//" | sed 's/\[//;s/\]//' | sed 's/, */,/g'
}

# Build JSON array of active pipelines
build_active_json() {
    local first=true
    echo "["
    if [ -d "$ACTIVE_DIR" ]; then
        for file in "$ACTIVE_DIR"/p*.md; do
            [ -f "$file" ] || continue
            if [ "$first" = true ]; then
                first=false
            else
                echo ","
            fi

            local id phase priority title slug source blocked_by created updated
            id=$(frontmatter_value "$file" "id")
            phase=$(frontmatter_value "$file" "phase")
            priority=$(frontmatter_value "$file" "priority")
            title=$(frontmatter_value "$file" "title")
            slug=$(frontmatter_value "$file" "slug")
            source=$(frontmatter_value "$file" "source")
            blocked_by=$(frontmatter_list "$file" "blocked-by")
            created=$(frontmatter_value "$file" "created")
            updated=$(frontmatter_value "$file" "updated")

            # Convert blocked-by to JSON array
            local blocked_json="[]"
            if [ -n "$blocked_by" ] && [ "$blocked_by" != "[]" ]; then
                blocked_json=$(echo "$blocked_by" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep -v '^$' | jq -R . | jq -s .)
            fi

            # Calculate days in current phase
            local days_in_phase=0
            if [ -n "$updated" ] && [ "$updated" != "null" ]; then
                local updated_epoch current_epoch
                updated_epoch=$(date -j -f "%Y-%m-%d" "$updated" "+%s" 2>/dev/null || date -d "$updated" "+%s" 2>/dev/null || echo 0)
                current_epoch=$(date "+%s")
                if [ "$updated_epoch" -gt 0 ]; then
                    days_in_phase=$(( (current_epoch - updated_epoch) / 86400 ))
                fi
            fi

            cat <<ITEM
  {
    "id": $(echo "$id" | jq -R .),
    "slug": $(echo "$slug" | jq -R .),
    "title": $(echo "$title" | jq -R .),
    "phase": $(echo "$phase" | jq -R .),
    "priority": ${priority:-2},
    "source": $(echo "${source:-null}" | jq -R .),
    "blocked_by": $blocked_json,
    "created": $(echo "$created" | jq -R .),
    "updated": $(echo "$updated" | jq -R .),
    "days_in_phase": $days_in_phase,
    "file": $(echo "$file" | jq -R .)
  }
ITEM
        done
    fi
    echo "]"
}

# Count archived pipelines
count_archived() {
    if [ -d "$ARCHIVE_DIR" ]; then
        find "$ARCHIVE_DIR" -name "p*.md" -type f 2>/dev/null | wc -l | tr -d ' '
    else
        echo 0
    fi
}

# Main JSON output
build_json() {
    local active_json
    active_json=$(build_active_json)
    local archived_count
    archived_count=$(count_archived)
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local total_active
    total_active=$(echo "$active_json" | jq 'length')

    # Phase-based categorization. Pipelines with blocked_by entries go in the
    # blocked bucket regardless of phase.
    local design breakdown execution verification archived blocked

    blocked=$(echo "$active_json" | jq '[.[] | select(.blocked_by | length > 0)] | sort_by(.priority)')

    design=$(echo "$active_json" | jq '[.[] | select(.blocked_by | length == 0) | select(.phase == "design")] | sort_by(.priority)')

    breakdown=$(echo "$active_json" | jq '[.[] | select(.blocked_by | length == 0) | select(.phase == "breakdown")] | sort_by(.priority)')

    execution=$(echo "$active_json" | jq '[.[] | select(.blocked_by | length == 0) | select(.phase == "execution")] | sort_by(.priority)')

    verification=$(echo "$active_json" | jq '[.[] | select(.blocked_by | length == 0) | select(.phase == "verification")] | sort_by(.priority)')

    archived=$(echo "$active_json" | jq '[.[] | select(.phase == "archived")] | sort_by(.priority)')

    jq -n \
        --argjson pipelines "$active_json" \
        --arg timestamp "$timestamp" \
        --argjson archived_count "$archived_count" \
        --argjson total_active "$total_active" \
        --argjson design "$design" \
        --argjson breakdown "$breakdown" \
        --argjson execution "$execution" \
        --argjson verification "$verification" \
        --argjson archived "$archived" \
        --argjson blocked "$blocked" \
        '{
            timestamp: $timestamp,
            summary: {
                active: $total_active,
                archived_count: $archived_count,
                design: ($design | length),
                breakdown: ($breakdown | length),
                execution: ($execution | length),
                verification: ($verification | length),
                blocked: ($blocked | length),
                archived: ($archived | length)
            },
            design: $design,
            breakdown: $breakdown,
            execution: $execution,
            verification: $verification,
            archived: $archived,
            blocked: $blocked,
            pipelines: $pipelines
        }'
}

# Markdown output
build_markdown() {
    local json
    json=$(build_json)
    local timestamp
    timestamp=$(echo "$json" | jq -r '.timestamp')

    cat <<HEADER
# Pipeline Dashboard
_Updated: ${timestamp}_

## Summary
| Phase | Count |
|-------|------:|
| Design | $(echo "$json" | jq '.summary.design') |
| Breakdown | $(echo "$json" | jq '.summary.breakdown') |
| Execution | $(echo "$json" | jq '.summary.execution') |
| Verification | $(echo "$json" | jq '.summary.verification') |
| Blocked | $(echo "$json" | jq '.summary.blocked') |
| Archived (in active dir) | $(echo "$json" | jq '.summary.archived') |
| **Total active** | **$(echo "$json" | jq '.summary.active')** |
| Archived (in archive dir) | $(echo "$json" | jq '.summary.archived_count') |

## Design
| Pipeline | Priority | Days in phase |
|----------|:--------:|--------------:|
HEADER

    echo "$json" | jq -r '.design[] | "| \(.id) — \(.title) | \(.priority) | \(.days_in_phase) |"'

    cat <<BREAKDOWN

## Breakdown
| Pipeline | Priority | Days in phase |
|----------|:--------:|--------------:|
BREAKDOWN

    echo "$json" | jq -r '.breakdown[] | "| \(.id) — \(.title) | \(.priority) | \(.days_in_phase) |"'

    cat <<EXECUTION

## Execution
| Pipeline | Priority | Days in phase |
|----------|:--------:|--------------:|
EXECUTION

    echo "$json" | jq -r '.execution[] | "| \(.id) — \(.title) | \(.priority) | \(.days_in_phase) |"'

    cat <<VERIFICATION

## Verification
| Pipeline | Priority | Days in phase |
|----------|:--------:|--------------:|
VERIFICATION

    echo "$json" | jq -r '.verification[] | "| \(.id) — \(.title) | \(.priority) | \(.days_in_phase) |"'

    cat <<BLOCKED

## Blocked
| Pipeline | Priority | Phase | Waiting On |
|----------|:--------:|-------|------------|
BLOCKED

    echo "$json" | jq -r '.blocked[] | "| \(.id) — \(.title) | \(.priority) | \(.phase) | \(.blocked_by | join(", ")) |"'

    cat <<ARCHIVED_IN_ACTIVE

## Archived (still in active directory)
| Pipeline | Priority |
|----------|:--------:|
ARCHIVED_IN_ACTIVE

    echo "$json" | jq -r '.archived[] | "| \(.id) — \(.title) | \(.priority) |"'

    echo ""
}

case "$OUTPUT_FORMAT" in
    --json)
        build_json
        ;;
    --markdown)
        # Ensure parent directory exists
        mkdir -p "$(dirname "$DASHBOARD_FILE")"
        build_markdown | tee "$DASHBOARD_FILE"
        echo "" >&2
        echo "Dashboard written to $DASHBOARD_FILE" >&2
        ;;
    *)
        echo "Usage: $0 [--json | --markdown]" >&2
        exit 1
        ;;
esac
