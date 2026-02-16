#!/bin/bash
# Copyright (c) 2026 Yaakov M Nemoy
# SPDX-License-Identifier: LicenseRef-JNNNL-1.0
# Filter messages by type
# Usage: rest_session_filter.sh <session_file> <type>
# Types: user, assistant, summary, file-history-snapshot, queue-operation
# Output: Full JSON lines matching the type

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: rest_session_filter.sh <session_file> <type>" >&2
  exit 1
fi

jq -c "select(.type == \"$2\")" "$1"
