#!/bin/bash
# Copyright (c) 2026 Yaakov M Nemoy
# SPDX-License-Identifier: LicenseRef-JNNNL-1.0
# Integration test for rest analysis pipeline
# Runs /rest analysis inside a Lima VM against fixture sessions
#
# Usage:
#   ./run.sh              Create VM if missing, clean state, run test, stop VM
#   ./run.sh --keep       Same but leave VM running after test
#   ./run.sh --clean      Delete existing VM, create fresh, run test
#   ./run.sh --destroy    Just delete the VM, no test
#   ./run.sh --fast       Use haiku for subagents (cheaper/faster)
#   ./run.sh --model X    Use model X for main session (opus, sonnet, haiku)
#
# Auth: auto-extracts OAuth from macOS keychain, or use ANTHROPIC_API_KEY
#   ./run.sh --fast --keep                          # uses keychain
#   ANTHROPIC_API_KEY=sk-ant-... ./run.sh --fast    # uses API key
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_ROOT="$(cd "$PLUGIN_ROOT/../.." && pwd)"
RESULTS_DIR="$SCRIPT_DIR/results"
VM_NAME="rest-integration-test"
FAST_MODE=false
KEEP_RUNNING=false
CLEAN=false
DESTROY_ONLY=false
MODEL=""

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --fast) FAST_MODE=true; shift ;;
    --keep) KEEP_RUNNING=true; shift ;;
    --clean) CLEAN=true; shift ;;
    --destroy) DESTROY_ONLY=true; shift ;;
    --model) MODEL="$2"; shift 2 ;;
    *) echo "Usage: run.sh [--fast] [--keep] [--clean] [--destroy] [--model MODEL]"; exit 1 ;;
  esac
done

# --- Destroy mode ---
if $DESTROY_ONLY; then
  echo "=== Destroying VM ==="
  limactl delete -f "$VM_NAME" 2>/dev/null || true
  echo "Done."
  exit 0
fi

# --- Auth: resolve credentials before VM work ---
# Priority: ANTHROPIC_API_KEY env var > macOS keychain OAuth token
AUTH_MODE=""
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  AUTH_MODE="api_key"
else
  # Try extracting OAuth credentials from macOS keychain
  # Claude Code stores them under "Claude Code-credentials" service
  KEYCHAIN_CREDS=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null || true)
  if [ -n "$KEYCHAIN_CREDS" ]; then
    AUTH_MODE="oauth"
  fi
fi

if [ -z "$AUTH_MODE" ]; then
  echo "ERROR: No auth credentials found."
  echo ""
  echo "Option 1: Log in to Claude Code on this machine (keychain)"
  echo "Option 2: ANTHROPIC_API_KEY=sk-ant-... ./run.sh"
  echo ""
  exit 1
fi

# --- Clean mode: delete existing VM ---
if $CLEAN; then
  echo "=== Clean: removing existing VM ==="
  limactl delete -f "$VM_NAME" 2>/dev/null || true
fi

# --- Helper: run command in VM ---
# Subshell with cd /tmp prevents Lima from mirroring host CWD into the guest.
# Without this, limactl tries to cd to the host path inside the VM and emits warnings.
vm_shell() {
  (cd /tmp && limactl shell "$VM_NAME" -- "$@")
}

# --- Create VM if it doesn't exist ---
if ! limactl list -q | grep -q "^${VM_NAME}$"; then
  echo "=== Creating VM ==="
  # Fill in mount paths in template (BSD sed compatible)
  TMPYAML=$(mktemp /tmp/vm-XXXX.yaml)
  sed \
    -e "s|REPO_ROOT_PLACEHOLDER|$REPO_ROOT|" \
    -e "s|FIXTURES_DIR_PLACEHOLDER|$SCRIPT_DIR/fixtures|" \
    "$SCRIPT_DIR/vm.yaml" > "$TMPYAML"

  limactl create --name="$VM_NAME" "$TMPYAML" --tty=false
  rm -f "$TMPYAML"
  limactl start "$VM_NAME"

  echo "=== Waiting for provisioning ==="
  # Wait for cloud-init to finish (Node.js + Claude Code installed)
  vm_shell bash -c \
    'while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 2; done'
  vm_shell claude --version
else
  # VM exists — ensure it's running
  echo "=== Starting existing VM ==="
  limactl start "$VM_NAME" 2>/dev/null || true
fi

# --- Prepare VM for this run ---
# Clean state: wipe .claude/ and test-project/, rebuild from scratch
echo "=== Preparing test environment ==="
RUN_TS=$(date +%Y%m%d-%H%M%S)

vm_shell bash -c '
  set -eux
  HOME_DIR="$HOME"

  # Clean slate for .claude
  rm -rf "$HOME_DIR/.claude"
  mkdir -p "$HOME_DIR/.claude/projects"
  mkdir -p "$HOME_DIR/.claude/analysis/sessions"
  mkdir -p "$HOME_DIR/.claude/analysis/inventory"
  mkdir -p "$HOME_DIR/.claude/session-archives"

  # Test project (CWD for Claude Code)
  rm -rf "$HOME_DIR/test-project"
  mkdir -p "$HOME_DIR/test-project/.claude-plugin"
  mkdir -p "$HOME_DIR/test-project/plugins"
  git -C "$HOME_DIR/test-project" init --quiet

  # Symlink plugin from read-only repo mount
  ln -s /repo/plugins/claude-rest-system "$HOME_DIR/test-project/plugins/claude-rest-system"
  cp /repo/.claude-plugin/marketplace.json "$HOME_DIR/test-project/.claude-plugin/"

  # Copy fixtures into .claude/projects/ (encoded path for test-project)
  ENCODED=$(echo "$HOME_DIR/test-project" | sed "s|^/||; s|/|-|g")
  mkdir -p "$HOME_DIR/.claude/projects/-${ENCODED}"
  cp /fixtures/sessions/*.jsonl "$HOME_DIR/.claude/projects/-${ENCODED}/"
'

# Generate minimal settings.json for the test (don't copy host's — it contains user-specific config)
SETTINGS_TMP=$(mktemp /tmp/settings-XXXX.json)
cat > "$SETTINGS_TMP" <<'SETTINGS_EOF'
{
  "permissions": {
    "allow": [],
    "deny": []
  },
  "enabledPlugins": {
    "claude-rest-system@all-slop-marketplace": true
  }
}
SETTINGS_EOF
limactl copy "$SETTINGS_TMP" "${VM_NAME}:~/.claude/settings.json"
rm -f "$SETTINGS_TMP"

# Inject auth credentials into VM
echo "=== Configuring auth ($AUTH_MODE) ==="
if [ "$AUTH_MODE" = "oauth" ]; then
  # Write OAuth JSON from keychain to .credentials.json (Linux credential store)
  # Create a temp file to avoid passing JSON through shell escaping
  CRED_TMP=$(mktemp /tmp/creds-XXXX.json)
  security find-generic-password -s "Claude Code-credentials" -w > "$CRED_TMP" 2>/dev/null
  limactl copy "$CRED_TMP" "${VM_NAME}:~/.claude/.credentials.json"
  rm -f "$CRED_TMP"
fi

# --- Install plugin in VM ---
echo "=== Installing plugin ==="
vm_shell bash -c \
  "claude plugin marketplace add ~/test-project/.claude-plugin/marketplace.json 2>&1"
vm_shell bash -c \
  "claude plugin install claude-rest-system@all-slop-marketplace 2>&1"

# --- Build prompt ---
# Use fully-qualified skill name (short /rest doesn't resolve in -p mode)
# Append instructions to proceed without confirmation (non-interactive -p mode)
PROMPT="/claude-rest-system:rest — Proceed immediately with analysis, do not ask for confirmation. Analyze all sessions found."
if $FAST_MODE; then
  PROMPT="/claude-rest-system:rest — Proceed immediately with analysis, do not ask for confirmation. Analyze all sessions found. Use haiku for all subagents to minimize cost."
fi

# --- Run Claude inside VM ---
echo "=== Running /rest analysis ==="
mkdir -p "$RESULTS_DIR/$RUN_TS"

# Build CLI flags
CLI_FLAGS="--dangerously-skip-permissions"
if [ -n "$MODEL" ]; then
  CLI_FLAGS="$CLI_FLAGS --model $MODEL"
  echo "Model: $MODEL"
fi

if [ "$AUTH_MODE" = "api_key" ]; then
  vm_shell bash -c "export ANTHROPIC_API_KEY='$ANTHROPIC_API_KEY' && cd ~/test-project && claude $CLI_FLAGS -p '$PROMPT'" \
    2>&1 | tee "$RESULTS_DIR/$RUN_TS/run.log" || true
else
  # OAuth credentials already in .credentials.json
  vm_shell bash -c "cd ~/test-project && claude $CLI_FLAGS -p '$PROMPT'" \
    2>&1 | tee "$RESULTS_DIR/$RUN_TS/run.log" || true
fi
# || true: don't abort if Claude exits non-zero — we still want artifacts

# --- Extract artifacts ---
echo "=== Extracting artifacts ==="

# Analysis output
limactl copy -r "${VM_NAME}:~/.claude/analysis" "$RESULTS_DIR/$RUN_TS/analysis/" 2>/dev/null || true

# Claude's own session transcripts (the JSONL files from this run)
mkdir -p "$RESULTS_DIR/$RUN_TS/claude-sessions"
vm_shell bash -c \
  'find ~/.claude/projects -name "*.jsonl" -newer ~/.claude/analysis 2>/dev/null || true' \
  | while read -r f; do
    limactl copy "${VM_NAME}:$f" "$RESULTS_DIR/$RUN_TS/claude-sessions/" 2>/dev/null || true
  done

# Fallback: grab ALL session files if the timestamp filter missed them
SESS_COUNT=$(ls "$RESULTS_DIR/$RUN_TS/claude-sessions/"*.jsonl 2>/dev/null | wc -l | tr -d ' ')
if [ "$SESS_COUNT" -eq 0 ]; then
  limactl copy -r "${VM_NAME}:~/.claude/projects" "$RESULTS_DIR/$RUN_TS/claude-sessions/" 2>/dev/null || true
fi

# --- Evaluate ---
echo ""
echo "=== Evaluating ==="
"$SCRIPT_DIR/evaluate.sh" "$RESULTS_DIR/$RUN_TS/analysis" 2>&1 | tee "$RESULTS_DIR/$RUN_TS/eval.log"
EVAL_EXIT=$?

# --- Symlink latest ---
ln -sfn "$RUN_TS" "$RESULTS_DIR/latest"

# --- VM lifecycle ---
if ! $KEEP_RUNNING; then
  echo "=== Stopping VM (retained for debugging: limactl shell $VM_NAME) ==="
  limactl stop "$VM_NAME"
else
  echo "=== VM left running: limactl shell $VM_NAME ==="
fi

echo ""
echo "Results: $RESULTS_DIR/$RUN_TS/"
echo "Latest:  $RESULTS_DIR/latest/"
exit $EVAL_EXIT
