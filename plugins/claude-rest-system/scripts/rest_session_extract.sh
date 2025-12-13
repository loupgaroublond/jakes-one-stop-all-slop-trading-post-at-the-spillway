#!/bin/bash
# Extract specific message range by line offset
# Usage: rest_session_extract.sh <session_file> <start_line> <end_line>
# Output: Lines from start to end (inclusive, 1-indexed)

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
  echo "Usage: rest_session_extract.sh <session_file> <start_line> <end_line>" >&2
  exit 1
fi

sed -n "${2},${3}p" "$1"
