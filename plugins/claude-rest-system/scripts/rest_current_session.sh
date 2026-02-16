#!/usr/bin/env bash
# Copyright (c) 2026 Yaakov M Nemoy
# SPDX-License-Identifier: LicenseRef-JNNNL-1.0
#
# rest_current_session.sh - Find the current active session file
#
# Usage: rest_current_session.sh [project_path]
#
# If project_path is provided, uses that. Otherwise uses current directory.
# Outputs the path to the most recent non-agent session file.
#
# Exit codes:
#   0 - Success, session file path printed to stdout
#   1 - No session files found
#   2 - Project directory doesn't exist

set -euo pipefail

PROJECT_PATH="${1:-$(pwd)}"

# Encode path: replace / with -
ENCODED_PROJECT=$(echo "$PROJECT_PATH" | sed 's|^/||' | sed 's|/|-|g')

SESSION_DIR="${HOME}/.claude/projects/-${ENCODED_PROJECT}"

if [[ ! -d "$SESSION_DIR" ]]; then
    echo "Error: No session directory found at $SESSION_DIR" >&2
    exit 2
fi

# Find most recent non-agent session file
# Agent sessions start with "agent-", we want regular sessions
LATEST_SESSION=$(ls -1t "$SESSION_DIR"/*.jsonl 2>/dev/null | grep -v '/agent-' | head -1)

if [[ -z "$LATEST_SESSION" ]]; then
    echo "Error: No session files found in $SESSION_DIR" >&2
    exit 1
fi

# Output the session path
echo "$LATEST_SESSION"
