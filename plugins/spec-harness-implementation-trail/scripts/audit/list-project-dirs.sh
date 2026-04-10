#!/usr/bin/env bash
# List all Claude project directories related to the current project.
# Works with or without git. If git is available and the project is a repo,
# also enumerates worktree directories.
#
# Output: one directory path per line (only existing directories)

set -uo pipefail

# Walk up from cwd to find the project root (directory containing specs/).
find_project_root() {
  local dir
  dir="$(pwd)"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/specs" ]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

PROJECT_ROOT=$(find_project_root) || {
  echo "Error: no specs/ directory found in any parent of the current working directory." >&2
  echo "Run /shit:init from your project root to scaffold the specs/ tree." >&2
  exit 1
}

# Encode a path for Claude's project directory naming convention.
# /Users/foo/my-project becomes -Users-foo-my-project (leading dash preserved)
encode_path() {
  echo "$1" | tr '/' '-'
}

# Emit the Claude project directory for a given path, if it exists.
emit_if_exists() {
  local encoded
  encoded=$(encode_path "$1")
  local dir="$HOME/.claude/projects/$encoded"
  if [ -d "$dir" ]; then
    echo "$dir"
  fi
}

# Always include the project root itself.
emit_if_exists "$PROJECT_ROOT"

# If git is available and we're in a repo, also include worktree directories.
if command -v git >/dev/null 2>&1 && git -C "$PROJECT_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  while IFS= read -r line; do
    if [[ "$line" == worktree\ * ]]; then
      wt_path="${line#worktree }"
      # Don't duplicate the project root (already emitted above).
      if [ "$wt_path" != "$PROJECT_ROOT" ]; then
        emit_if_exists "$wt_path"
      fi
    fi
  done < <(git -C "$PROJECT_ROOT" worktree list --porcelain 2>/dev/null)
fi
