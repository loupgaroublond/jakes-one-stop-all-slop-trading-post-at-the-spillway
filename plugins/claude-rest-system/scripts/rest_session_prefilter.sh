#!/bin/bash
# Pre-filter and inventory session files
# Usage: rest_session_prefilter.sh <session_dir_or_file> [session_dir_or_file...]
# Output: JSON array of valid sessions with id, count, first_timestamp, size_bytes

if [ -z "$1" ]; then
  echo "Usage: rest_session_prefilter.sh <session_dir_or_file> [...]" >&2
  exit 1
fi

# Collect all .jsonl files from args (files or directories)
files=()
for arg in "$@"; do
  if [ -d "$arg" ]; then
    while IFS= read -r -d '' f; do
      files+=("$f")
    done < <(find "$arg" -name "*.jsonl" -type f -print0 2>/dev/null)
  elif [ -f "$arg" ]; then
    files+=("$arg")
  fi
done

echo "["
first=true
for f in "${files[@]}"; do
  # Skip empty files
  if [ ! -s "$f" ]; then
    continue
  fi

  # Get file size
  size=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f" 2>/dev/null || echo "0")

  # Get line count
  count=$(wc -l < "$f" | tr -d ' ')

  # Skip files with 0 lines
  if [ "$count" -eq 0 ]; then
    continue
  fi

  # Extract session ID from filename
  session_id=$(basename "$f" .jsonl)

  # Get first message timestamp (first line with timestamp field)
  first_ts=$(jq -r 'select(.timestamp) | .timestamp' "$f" 2>/dev/null | head -1)
  if [ -z "$first_ts" ] || [ "$first_ts" = "null" ]; then
    first_ts=""
  fi

  # Output JSON object
  if [ "$first" = true ]; then
    first=false
  else
    echo ","
  fi

  jq -n \
    --arg id "$session_id" \
    --arg file "$f" \
    --argjson count "$count" \
    --arg ts "$first_ts" \
    --argjson size "$size" \
    '{session_id: $id, file: $file, message_count: $count, first_timestamp: (if $ts == "" then null else $ts end), size_bytes: $size}'
done
echo "]"
