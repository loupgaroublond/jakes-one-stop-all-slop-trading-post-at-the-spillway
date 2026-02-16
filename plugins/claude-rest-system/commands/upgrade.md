<!-- Copyright (c) 2026 Yaakov M Nemoy -->
<!-- SPDX-License-Identifier: LicenseRef-JNNNL-1.0 -->
---
description: Check and apply plugin migrations for breaking changes
---

# Upgrade

Evaluate the user's system against known migrations and help apply any needed changes.

This is an LLM-driven migration tool. You will read the MIGRATIONS.md document, run detection commands for each migration, determine status, and guide the user through any needed updates.

## Usage

```
/upgrade [--dry-run]
```

**Options:**
- `--dry-run`: Show migration status and plan without making changes
- (no args): Interactive migration with user confirmation

## User Instructions

$ARGUMENTS

## Workflow

### 1. Load Migrations Document

Read the migrations document to understand what needs checking:

```bash
cat ${CLAUDE_PLUGIN_ROOT}/MIGRATIONS.md
```

Parse each migration section to extract:
- Migration ID and version
- Detection commands
- Status determination logic
- Migration steps
- Verification commands

### 2. Evaluate Each Migration

For each migration in sequence, run the detection commands and determine status.

**Migration 001 (Peers Format v2.2.0):**
```bash
# Check if file exists
test -f ~/.claude/project-peers.json && echo "FILE_EXISTS" || echo "NO_FILE"

# If exists, check format
jq -e 'to_entries[].value | to_entries[].value[] | select(type == "string")' ~/.claude/project-peers.json 2>/dev/null && echo "HAS_STRINGS" || echo "NO_STRINGS"
```

**Migration 002 (sync.conf v2.4.0):**
```bash
test -f ~/.claude/self/sync.conf && echo "OLD_EXISTS"
test -f ~/.claude/sync.conf && echo "NEW_EXISTS"
```

**Migration 003 (archive.log v2.4.0):**
```bash
test -f ~/.claude/self/archive.log && echo "OLD_EXISTS"
test -f ~/.claude/archive.log && echo "NEW_EXISTS"
```

**Migration 004 (Remove self/ v2.4.0):**
```bash
test -d ~/.claude/self && echo "DIR_EXISTS"
ls -A ~/.claude/self 2>/dev/null | head -1  # Check if empty
```

### 3. Report Status

Present findings clearly:

```
=== Claude Rest System Migration Status ===
Plugin version: 2.4.0

Migration 001: Peers Format (v2.2.0)
  Status: NOT_APPLICABLE
  Reason: ~/.claude/project-peers.json does not exist

Migration 002: sync.conf Location (v2.4.0)
  Status: NEEDS_MIGRATION
  Found: ~/.claude/self/sync.conf
  Action: Move to ~/.claude/sync.conf

Migration 003: archive.log Location (v2.4.0)
  Status: NEEDS_MIGRATION
  Found: ~/.claude/self/archive.log
  Action: Move to ~/.claude/archive.log

Migration 004: Remove ~/.claude/self/ (v2.4.0)
  Status: BLOCKED
  Reason: Directory not empty (waiting on migrations 002, 003)

=== Summary ===
Migrations needed: 2
Blocked: 1 (depends on above)
Up to date: 1
```

### 4. Generate Migration Plan

If migrations are needed and not `--dry-run`:

```
=== Migration Plan ===

The following changes will be made:

Step 1: Move sync.conf (Migration 002)
  Command: mv ~/.claude/self/sync.conf ~/.claude/sync.conf

Step 2: Move archive.log (Migration 003)
  Command: mv ~/.claude/self/archive.log ~/.claude/archive.log

Step 3: Remove deprecated directory (Migration 004)
  Command: rmdir ~/.claude/self

Proceed with migration? [Y/n]
```

### 5. Execute Migrations (with confirmation)

For each migration step:
1. Show the command about to run
2. Get user confirmation (unless they said "yes to all")
3. Execute the command
4. Verify success
5. Report result

```
Executing Step 1: Move sync.conf
  Running: mv ~/.claude/self/sync.conf ~/.claude/sync.conf
  Verifying...
  ✓ Success: ~/.claude/sync.conf exists

Executing Step 2: Move archive.log
  Running: mv ~/.claude/self/archive.log ~/.claude/archive.log
  Verifying...
  ✓ Success: ~/.claude/self/archive.log removed

Executing Step 3: Remove deprecated directory
  Running: rmdir ~/.claude/self
  Verifying...
  ✓ Success: ~/.claude/self no longer exists
```

### 6. Final Verification

Re-run all detection checks to confirm migration success:

```
=== Final Migration Status ===

Migration 001: Peers Format (v2.2.0) - NOT_APPLICABLE
Migration 002: sync.conf Location (v2.4.0) - MIGRATED ✓
Migration 003: archive.log Location (v2.4.0) - MIGRATED ✓
Migration 004: Remove ~/.claude/self/ (v2.4.0) - MIGRATED ✓

All migrations complete!
```

## Handling Special Cases

### Conflict Resolution

If both old and new locations exist:
- For config files (sync.conf): Ask user which to keep
- For log files (archive.log): Offer to merge (append old to new)

### Peers Format Migration (001)

This requires JSON transformation. If detected:
1. Show current format
2. Show what the transformed format would look like
3. Ask user to confirm before writing
4. User should add display names after migration

### Blocked Migrations

If a migration is blocked by dependencies:
1. Explain the dependency
2. Offer to run prerequisite migrations first
3. Continue with the blocked migration after prerequisites complete

## Notes

- Migrations are idempotent - running twice won't cause issues
- Always verify after each step
- User can abort at any point
- `--dry-run` is safe and makes no changes
