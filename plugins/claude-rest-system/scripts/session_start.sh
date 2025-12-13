#!/bin/bash
# Session start hook - archives sessions and reports fatigue level
# Run this at the beginning of each Claude session

set -euo pipefail

# Use plugin root if available, fallback to ~/.claude/self for standalone use
SCRIPTS_DIR="${CLAUDE_PLUGIN_ROOT:-${HOME}/.claude/rest-plugin}/scripts"

echo "Running session start checks..."
echo ""

# Archive sessions first (preserve everything before checking)
"${SCRIPTS_DIR}/archive_sessions.sh"

echo ""
echo "─────────────────────────────────────────"
echo ""

# Check and report fatigue level
"${SCRIPTS_DIR}/fatigue_check.sh"