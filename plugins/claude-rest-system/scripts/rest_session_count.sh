#!/bin/bash
# Copyright (c) 2026 Yaakov M Nemoy
# SPDX-License-Identifier: LicenseRef-JNNNL-1.0
# Count total messages (lines) in a session JSONL file
# Usage: rest_session_count.sh <session_file>
# Returns 0 for empty or missing files

if [ -z "$1" ]; then
  echo "Usage: rest_session_count.sh <session_file>" >&2
  exit 1
fi

# Check if file exists and is non-empty
if [ ! -f "$1" ] || [ ! -s "$1" ]; then
  echo "0"
  exit 0
fi

wc -l < "$1" | tr -d ' '
