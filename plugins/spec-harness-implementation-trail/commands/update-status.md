---
description: Light cleanup — audit transcripts, update reader, compile spec, update status
---

# Update Status — Light Cleanup Orchestrator

Run 4 cleanup steps in sequence with error gating. Each step must succeed before the next begins.

**Steps:** `/shit:audit-transcripts` → `/shit:reader` → `/shit:spec-reader` → `/shit:status`

**Error gating:** After each step, check result. "Nothing new found" is SUCCESS. Broken data, file write failures, exceptions = FAILURE → halt immediately.

---

## Step 1: Audit Transcripts

Run the full `/shit:audit-transcripts` workflow:

1. Discovery (worktree-aware) via `${CLAUDE_PLUGIN_ROOT}/scripts/audit/list-sessions.sh`
2. Parallel verification agents (5–7 agents, batched by date range, chunked for large sessions)
3. Repair (serialized writes for any `MISSING_FOUND` results)
4. Final audit agent

### Step 1 Gate

- **SUCCESS** — Final audit returns ALL_COVERED, or MISSING_FOUND with repairs completed
- **FAILURE** — Agent errors, discovery script fails, or file write failures

If FAILURE, stop here. Report what went wrong. Do not proceed to Step 2.

---

## Step 2: Reader

Run the full `/shit:reader` workflow:

1. Read current reader (most recent `specs/0-transcripts/reader_*.md`) to establish baseline
2. Read all transcript files to find new content
3. Read `specs/0-transcripts/process.md` for open questions status
4. Write updated reader to `specs/0-transcripts/reader_{DATETIME}.md`

### Step 2 Gate

- **SUCCESS** — Reader file written
- **FAILURE** — File write fails or no transcripts found

If FAILURE, stop here. Report what went wrong. Do not proceed to Step 3.

---

## Step 3: Spec Reader

Compile active spec modules into a single file by running the compilation script:

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/compile-spec.py
```

The script:
1. Reads all spec modules from `specs/2-spec/` matching `NNN-*.md` (three-digit prefix)
2. Strips dropped sections in both formats: `<!-- DROPPED ... -->` HTML comments and `~~strikethrough~~` headings
3. Compiles active content into `specs/2-spec/compiled/spec-reader_YYYY-MM-DD.md`

Report the script's output: total modules compiled, number of dropped sections skipped, output file path and size.

### Step 3 Gate

- **SUCCESS** — Script exits 0 and output file created
- **FAILURE** — Script errors or output file missing

If FAILURE, stop here. Report what went wrong. Do not proceed to Step 4.

---

## Step 4: Status

Run the full `/shit:status` workflow:

1. Discover all transcripts in `specs/0-transcripts/`
2. Read `specs/4-docs/project-status.md` (or create if missing)
3. Find uncovered transcripts
4. Extract timeline entries and feature updates
5. Merge into `specs/4-docs/project-status.md`
6. Update generated date

### Step 4 Gate

- **SUCCESS** — `specs/4-docs/project-status.md` updated and passes quality checks
- **FAILURE** — File write fails or quality checks fail

If FAILURE, stop here. Report what went wrong.

---

## Completion

Report all 4 step results:

| Step | Command | Result | Detail |
|------|---------|--------|--------|
| 1 | audit-transcripts | SUCCESS/FAILURE | {summary} |
| 2 | reader | SUCCESS/FAILURE | {summary} |
| 3 | spec-reader | SUCCESS/FAILURE | {summary} |
| 4 | status | SUCCESS/FAILURE | {summary} |

**Files written:** list all files created or modified across all steps.

If all SUCCESS: "Light cleanup complete."
If any FAILURE: "Stopped at Step N: {reason}"
