#!/usr/bin/env bash
# Reports the project's SHIT schema-version state vs the plugin's latest.
#
# Reads:
#   ./specs/.shit.toml                      (active version, if present)
#   <script's plugin root>/migrations/LATEST  (latest version)
#
# The plugin root is computed from the script's own location, so this works
# whether or not $CLAUDE_PLUGIN_ROOT is set in the subshell. Claude Code's
# `!` directive expands ${CLAUDE_PLUGIN_ROOT} in the markdown command line
# before invoking, but does not export it into the script's environment.
#
# Prints (one per line, KEY=VALUE):
#   STATUS=OK|MISMATCH|UNINITIALIZED|LEGACY
#   ACTIVE=<int|none>
#   LATEST=<int|?>
#   GAP=<int|?>
#
# Always exits 0 — the agent inspects the output.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LATEST_FILE="$PLUGIN_ROOT/migrations/LATEST"
MARKER="specs/.shit.toml"

if [ -r "$LATEST_FILE" ]; then
  LATEST=$(tr -d '[:space:]' < "$LATEST_FILE")
else
  LATEST="?"
fi

if [ ! -d specs ]; then
  STATUS=UNINITIALIZED
  ACTIVE=none
elif [ ! -f "$MARKER" ]; then
  STATUS=LEGACY
  ACTIVE=none
else
  ACTIVE=$(awk -F'=' '/^[[:space:]]*version[[:space:]]*=/ { gsub(/[[:space:]"]/, "", $2); print $2; exit }' "$MARKER")
  if [ -z "${ACTIVE:-}" ]; then
    STATUS=LEGACY
    ACTIVE=none
  elif [ "$ACTIVE" = "$LATEST" ]; then
    STATUS=OK
  else
    STATUS=MISMATCH
  fi
fi

if [ "$ACTIVE" = "none" ] || [ "$LATEST" = "?" ]; then
  GAP="?"
else
  GAP=$((LATEST - ACTIVE))
fi

printf 'STATUS=%s\n' "$STATUS"
printf 'ACTIVE=%s\n' "$ACTIVE"
printf 'LATEST=%s\n' "$LATEST"
printf 'GAP=%s\n' "$GAP"
