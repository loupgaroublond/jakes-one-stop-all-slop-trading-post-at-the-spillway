---
description: Migrate the project's specs/ layout to the latest schema version
allowed-tools: Bash(*schema-check.sh*), Bash(cat:*), Bash(ls:*), Bash(git:*)
---

# Migrate Schema

Walk this project from its active SHIT schema version to the latest, applying each migration in sequence.

## Active project state

!`"${CLAUDE_PLUGIN_ROOT}/scripts/schema-check.sh"`

## What to do

Use the output above to drive the plan.

### If `STATUS=OK`

The project is on the latest schema. Tell the user "nothing to do" and stop.

### If `STATUS=UNINITIALIZED`

There is no `specs/` directory. Tell the user to run `/shit:init` first — `/shit:migrate` is for projects that already adopted SHIT.

### If `STATUS=LEGACY` or `STATUS=MISMATCH`

Build and execute a migration plan.

## Migration plan workflow

### 1. Determine the target range

- If `STATUS=LEGACY`: source is "legacy" → start at migration `001`. The `ACTIVE` value is `none`; treat the effective starting version as `0`.
- If `STATUS=MISMATCH`: source is `$ACTIVE` → start at migration `0$((ACTIVE+1))`.
- Target is `$LATEST`.

The migrations to apply are all files matching `${CLAUDE_PLUGIN_ROOT}/migrations/NNN-*.md` whose `NNN` falls in `(start, target]`. List them by reading the directory:

```bash
ls -1 "${CLAUDE_PLUGIN_ROOT}/migrations/" | grep -E '^[0-9]{3}-' | sort
```

### 2. Read each pending migration file

For every migration in range, read the file. Each one declares its source version, target version, change description, detection commands, migration steps, and verification.

### 3. Decide rollup vs step-by-step

Based on the migrations' content, recommend one of:

- **Step-by-step** (default, safer): apply each migration's steps and verification, in order. After each, update `specs/.shit.toml` to that migration's target version. Stop and report on any failure.
- **Rollup** (faster, only when safe): collapse multiple migrations into a single combined plan — appropriate when migrations operate on disjoint files or have no inter-step dependencies. Tell the user explicitly that you're rolling up and which migrations are folded together.

Present the recommendation to the user. If the gap is large or migrations touch overlapping files, prefer step-by-step. If the gap is small (1–2) or migrations are clearly independent, rollup is fine.

### 4. Show the plan and confirm

Print:

```
=== SHIT Schema Migration Plan ===
Active: <ACTIVE or "legacy">
Latest: <LATEST>
Migrations to apply: <list of NNN-name>

Mode: <step-by-step|rollup>

Step 1: <description>
  Will run: <commands or summary>
Step 2: <description>
  ...
```

Wait for user confirmation before executing.

### 5. Execute

For each step:
1. Show the command(s).
2. Get confirmation if the step is destructive (`git rm`, `rm`, `sed -i`).
3. Run.
4. Run the migration file's verification block.
5. Update `specs/.shit.toml` to that migration's target version.
6. Continue to the next step on success; stop and report on failure.

### 6. Final verification

After all migrations applied, re-run the schema check:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/schema-check.sh"
```

Expected output: `STATUS=OK`, `ACTIVE=$LATEST`, `GAP=0`.

### 7. Stage and report

Stage all changes (`git add -A specs/`) but do not auto-commit. Tell the user to review and commit when ready.

## Notes

- **Forward-only.** Migrations are not designed to roll back. Use `git restore` / `git revert` if you need to undo.
- **No silent file deletion.** Any `git rm` happens with the user's explicit confirmation.
- **Cross-references.** Migration 002 in particular renames files; check `grep -r '<old-filename>' specs/` to surface references that need updating.
- **`.shit.toml` is the source of truth** for active version. If it disagrees with apparent project state, trust the file (the user may have edited manually) and tell the user.
