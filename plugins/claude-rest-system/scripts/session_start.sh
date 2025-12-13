#!/bin/bash
# Session start hook - silently archives sessions
# Fatigue reporting moved to /fatigue command

set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"

# Check if this is a fresh install (required directories missing)
if [[ ! -d "${CLAUDE_DIR}/self" ]] || [[ ! -d "${CLAUDE_DIR}/session-archives" ]] || [[ ! -d "${CLAUDE_DIR}/analysis" ]]; then
    echo "Claude Rest System needs setup. Ask Claude: \"Set up the Claude Rest System for me\""
    exit 0
fi

# Plugin root must be set by Claude Code
SCRIPTS_DIR="${CLAUDE_PLUGIN_ROOT}/scripts"

# Archive sessions silently (output goes to log file, not stdout)
"${SCRIPTS_DIR}/archive_sessions.sh" 2>/dev/null || true
