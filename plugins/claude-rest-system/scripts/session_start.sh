#!/bin/bash
# Session start hook - archives sessions and reports fatigue level
# Run this at the beginning of each Claude session

set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"

# Check if this is a fresh install (required directories missing)
if [[ ! -d "${CLAUDE_DIR}/self" ]] || [[ ! -d "${CLAUDE_DIR}/session-archives" ]] || [[ ! -d "${CLAUDE_DIR}/analysis" ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "☕ CLAUDE REST SYSTEM - First Time Setup"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Looks like this is a fresh install! The Rest System"
    echo "needs a few directories to track your sessions."
    echo ""
    echo "Ask Claude to set it up:"
    echo ""
    echo "  \"Set up the Claude Rest System for me\""
    echo ""
    echo "Or run manually:"
    echo ""
    echo "  mkdir -p ~/.claude/self"
    echo "  mkdir -p ~/.claude/session-archives"
    echo "  mkdir -p ~/.claude/analysis/reports"
    echo "  mkdir -p ~/.claude/analysis/sessions"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0
fi

# Use plugin root if available, fallback to ~/.claude/rest-plugin for standalone use
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