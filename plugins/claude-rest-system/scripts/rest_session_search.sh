#!/bin/bash
# Copyright (c) 2026 Yaakov M Nemoy
# SPDX-License-Identifier: LicenseRef-JNNNL-1.0
# Search for patterns in session content, return matching line numbers
# Usage: rest_session_search.sh <session_file> <pattern>
# Output: line_number:matching_content_snippet

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: rest_session_search.sh <session_file> <pattern>" >&2
  exit 1
fi

grep -n -E "$2" "$1"
