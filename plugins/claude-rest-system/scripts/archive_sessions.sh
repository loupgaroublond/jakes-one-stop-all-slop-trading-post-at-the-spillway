#!/bin/bash
# Archive session files from ~/.claude/projects/ to ~/.claude/session-archives/
# Optionally sync to network storage for multi-machine analysis
# Incrementally copies new and updated files, never deletes from archive

set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
PROJECTS_DIR="${CLAUDE_DIR}/projects"
ARCHIVE_DIR="${CLAUDE_DIR}/session-archives"
LOG_FILE="${CLAUDE_DIR}/archive.log"
SYNC_CONF="${CLAUDE_DIR}/sync.conf"

# Load sync config (env vars override conf values)
NETWORK_STORAGE_PATH="${NETWORK_STORAGE_PATH:-}"
MACHINE_NAME="${MACHINE_NAME:-}"
AGGREGATE_FROM_NETWORK="${AGGREGATE_FROM_NETWORK:-false}"

if [[ -f "${SYNC_CONF}" ]]; then
    # Source config, but don't override existing env vars
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        # Remove quotes from value
        value="${value%\"}"
        value="${value#\"}"
        # Only set if not already set in environment
        case "$key" in
            NETWORK_STORAGE_PATH) [[ -z "$NETWORK_STORAGE_PATH" ]] && NETWORK_STORAGE_PATH="$value" ;;
            MACHINE_NAME) [[ -z "$MACHINE_NAME" ]] && MACHINE_NAME="$value" ;;
            AGGREGATE_FROM_NETWORK) [[ "$AGGREGATE_FROM_NETWORK" == "false" ]] && AGGREGATE_FROM_NETWORK="$value" ;;
        esac
    done < "${SYNC_CONF}"
fi

# Default machine name to hostname if not set
MACHINE_NAME="${MACHINE_NAME:-$(hostname -s)}"

# Expand tilde in network storage path
NETWORK_STORAGE_PATH="${NETWORK_STORAGE_PATH/#\~/$HOME}"

# Ensure archive directory exists
mkdir -p "${ARCHIVE_DIR}"

# Use rsync to incrementally copy sessions
# -a: archive mode (preserves timestamps, permissions, etc.)
# -v: verbose output
# --stats: show transfer statistics
# --include: only copy .jsonl files and necessary directories
# --exclude: exclude everything else
# Note: no --delete flag, so files in archive are never removed

{
    echo "=== Archive run at $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="

    # Step 1: Local archive (projects → session-archives)
    echo "--- Step 1: Local archive ---"
    rsync -av \
        --stats \
        --include='*/' \
        --include='*.jsonl' \
        --exclude='*' \
        "${PROJECTS_DIR}/" \
        "${ARCHIVE_DIR}/"

    # Step 2: Push to network storage (if configured)
    if [[ -n "${NETWORK_STORAGE_PATH}" ]]; then
        echo "--- Step 2: Push to network (${MACHINE_NAME}) ---"
        NETWORK_MACHINE_DIR="${NETWORK_STORAGE_PATH}/${MACHINE_NAME}"
        mkdir -p "${NETWORK_MACHINE_DIR}"

        rsync -av \
            --stats \
            --include='*/' \
            --include='*.jsonl' \
            --exclude='*' \
            "${ARCHIVE_DIR}/" \
            "${NETWORK_MACHINE_DIR}/" || echo "WARNING: Network push failed (continuing)"
    fi

    # Step 3: Pull from network (if aggregator)
    if [[ "${AGGREGATE_FROM_NETWORK}" == "true" && -n "${NETWORK_STORAGE_PATH}" ]]; then
        echo "--- Step 3: Pull from network (aggregator mode) ---"
        OTHER_MACHINES_DIR="${ARCHIVE_DIR}/other-machines"
        mkdir -p "${OTHER_MACHINES_DIR}"

        for machine_dir in "${NETWORK_STORAGE_PATH}"/*/; do
            if [[ -d "${machine_dir}" ]]; then
                machine_basename=$(basename "${machine_dir}")
                # Skip our own machine's folder
                if [[ "${machine_basename}" == "${MACHINE_NAME}" ]]; then
                    echo "Skipping own machine (${machine_basename})"
                    continue
                fi
                echo "Pulling from ${machine_basename}..."
                # Pull to other-machines/{machine-name}/
                mkdir -p "${OTHER_MACHINES_DIR}/${machine_basename}"
                rsync -av \
                    --stats \
                    --include='*/' \
                    --include='*.jsonl' \
                    --exclude='*' \
                    "${machine_dir}/" \
                    "${OTHER_MACHINES_DIR}/${machine_basename}/" || echo "WARNING: Pull from ${machine_basename} failed (continuing)"
            fi
        done
    fi

    echo ""
} >> "${LOG_FILE}" 2>&1
