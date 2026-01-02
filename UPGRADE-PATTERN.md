# Plugin Upgrade Pattern

**Non-deterministic SQL migrations for LLM and coding agent plugins.**

How to implement LLM-driven migrations for plugins at Jake's Spillway.

## Philosophy

Traditional migration tools are deterministic: run a script, get the same result. But user environments vary wildly - different paths, partial migrations, conflicting configs, files that moved or got renamed manually. A deterministic script can't handle this.

LLMs can. They evaluate actual state, reason about intent, and generate tailored plans.

The LLM:
1. Reads a structured migrations document
2. Runs detection commands to evaluate current state
3. Determines which migrations are needed
4. Generates a migration plan specific to this machine
5. Executes with verification (or dry-run)

## Components

### 1. MIGRATIONS.md

Each plugin with breaking changes should have a `MIGRATIONS.md` in its root. This is a structured document the LLM parses.

**Location:** `plugins/{plugin-name}/MIGRATIONS.md`

**Structure:**

```markdown
# {Plugin Name} Migrations

Brief intro about what this document is for.

---

## Migration {NNN}: {Short Name} (v{VERSION})

**Change:** What changed and why it's breaking

**Detection:**
```bash
# Commands to determine current state
# Exit codes or output indicate status
```

**Status determination:**
- `NOT_APPLICABLE`: Condition when migration doesn't apply
- `NEEDS_MIGRATION`: Condition when migration is needed
- `MIGRATED`: Condition when already migrated
- `CONFLICT`: Condition when manual intervention needed
- `BLOCKED`: Condition when depends on other migrations

**Migration:**
```bash
# Commands to perform the migration
```

**Verification:**
```bash
# Commands to confirm success
```

---

## Migration {NNN+1}: ...
```

**Numbering:** Use sequential 3-digit numbers (001, 002, 003). Never reuse numbers even if migrations are removed.

**Version:** The plugin version that introduced the breaking change.


### 2. /upgrade Command

Each plugin with migrations should have an `/upgrade` command.

**Location:** `plugins/{plugin-name}/commands/upgrade.md`

**Template:**

```markdown
---
description: Check and apply plugin migrations for breaking changes
---

# Upgrade

Evaluate the user's system against known migrations and help apply any needed changes.

## Usage

/upgrade [--dry-run]

## User Instructions

$ARGUMENTS

## Workflow

### 1. Load Migrations Document

```bash
cat ${CLAUDE_PLUGIN_ROOT}/MIGRATIONS.md
```

Parse each migration section.

### 2. Evaluate Each Migration

Run detection commands for each migration in sequence.
Determine status: NOT_APPLICABLE | NEEDS_MIGRATION | MIGRATED | CONFLICT | BLOCKED

### 3. Report Status

Present findings in a clear table format.

### 4. Generate Migration Plan

If migrations needed and not --dry-run, present the plan.

### 5. Execute with Confirmation

For each step:
1. Show command
2. Get confirmation
3. Execute
4. Verify
5. Report result

### 6. Final Verification

Re-run all detection checks to confirm success.
```


### 3. SLOP_REPORT.md Entry

Every version with migrations MUST have a SLOP_REPORT entry explaining:
- What changed
- Why it's breaking
- That `/upgrade` is available

## Writing Good Migrations

### Detection Commands

Detection should be:
- **Idempotent**: Safe to run multiple times
- **Non-destructive**: Never modify state
- **Clear output**: Use echo statements or exit codes
- **Fast**: No network calls, minimal file reads

**Good:**
```bash
test -f ~/.config/old-path && echo "OLD_EXISTS"
test -f ~/.config/new-path && echo "NEW_EXISTS"
```

**Bad:**
```bash
# Modifies state during detection!
mv ~/.config/old-path ~/.config/new-path 2>/dev/null || true
```

### Status Determination

Always cover these cases:
- **NOT_APPLICABLE**: User doesn't use this feature
- **NEEDS_MIGRATION**: Old state exists, new doesn't
- **MIGRATED**: New state exists (regardless of old)
- **CONFLICT**: Both exist with different content
- **BLOCKED**: Depends on earlier migration

### Migration Commands

Should be:
- **Atomic**: Either fully succeed or fully fail
- **Reversible**: When possible, document how to undo
- **Verified**: Include a verification step

### Dependencies

If migration B requires migration A:
1. Document the dependency in migration B
2. The /upgrade command handles sequencing
3. Mark B as BLOCKED if A isn't complete

```markdown
## Migration 004: Remove Old Directory (v2.4.0)

**Change:** Remove deprecated directory

**Dependencies:** Migrations 002, 003 must complete first

**Detection:**
...
```

## Example: Full Migration Lifecycle

### 1. You Make a Breaking Change

You move a config file from `~/.plugin/config.json` to `~/.config/plugin/config.json`.

### 2. Add to MIGRATIONS.md

```markdown
## Migration 005: Config Location (v1.5.0)

**Change:** Config moved from ~/.plugin/config.json to ~/.config/plugin/config.json

**Detection:**
```bash
OLD_EXISTS=$(test -f ~/.plugin/config.json && echo "true" || echo "false")
NEW_EXISTS=$(test -f ~/.config/plugin/config.json && echo "true" || echo "false")
```

**Status determination:**
- `NOT_APPLICABLE`: Neither exists (fresh install)
- `NEEDS_MIGRATION`: Old exists, new doesn't
- `MIGRATED`: New exists
- `CONFLICT`: Both exist

**Migration:**
```bash
mkdir -p ~/.config/plugin
mv ~/.plugin/config.json ~/.config/plugin/config.json
```

**Verification:**
```bash
test -f ~/.config/plugin/config.json && echo "OK"
test ! -f ~/.plugin/config.json && echo "OLD_REMOVED"
```
```

### 3. Update SLOP_REPORT.md

```markdown
## 2026-01-15 — "THE CONFIG SHUFFLE"

### my-plugin v1.5.0

- **Config location changed** — Now at ~/.config/plugin/config.json
- Run `/upgrade` to migrate automatically!
```

### 4. Bump Version

Update both `plugin.json` and `marketplace.json`.

### 5. User Runs /upgrade

```
=== Migration Status ===

Migration 005: Config Location (v1.5.0)
  Status: NEEDS_MIGRATION
  Found: ~/.plugin/config.json
  Action: Move to ~/.config/plugin/config.json

Proceed? [Y/n]
```

## Special Cases

### JSON Format Migrations

When JSON schema changes, the LLM can transform:

```markdown
**Migration:**
1. Read current file
2. Transform structure:
   - Old: `{"key": "value"}`
   - New: `{"key": {"value": "value", "meta": ""}}`
3. Write transformed file
4. User adds missing fields
```

### Merge Conflicts

When both old and new exist:

```markdown
**Conflict Resolution:**
- For config files: Ask user which to keep
- For log files: Offer to merge (append old to new)
- For directories: List contents, let user decide
```

### Partial Migrations

If migration fails midway:

```markdown
**Recovery:**
1. Detection should identify partial state
2. Migration should be resumable
3. Document manual recovery steps
```

## Testing Migrations

Before releasing:

1. **Fresh install**: Migration should be NOT_APPLICABLE
2. **Old state only**: Migration should succeed
3. **New state only**: Migration should show MIGRATED
4. **Both states**: Should detect CONFLICT
5. **Partial state**: Should handle gracefully

## Anti-Patterns

**Don't:**
- Make detection commands modify state
- Skip verification steps
- Assume specific paths (use $HOME, etc.)
- Forget to document dependencies
- Reuse migration numbers

**Do:**
- Test on fresh and existing installs
- Provide dry-run option
- Show clear before/after states
- Handle conflicts gracefully
- Document everything in SLOP_REPORT
