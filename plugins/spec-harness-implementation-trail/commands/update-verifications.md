---
description: Heavy cleanup — full audit, reader, spec, status, spec-status, audit-spec, attest-report, distill, verify
allowed-tools: Bash(*schema-check.sh*)
---

# Update Verifications — Heavy Cleanup Orchestrator

Run 9 cleanup steps in sequence with error gating. Each step must succeed before the next begins.

**Steps:** `/shit:audit-transcripts` → `/shit:reader` → `/shit:spec-reader` → `/shit:status` → `/shit:spec-status` → `/shit:audit-spec` → `/shit:attest-report` → `/shit:distill` → `/shit:verify`

**Error gating:** After each step, check result. "Nothing new found" is SUCCESS. Broken data, file write failures, exceptions = FAILURE → halt immediately.

This is the comprehensive sweep. Use it before major reviews, milestones, or whenever you want a clean slate of generated reports across the entire project.

## Schema check

This command targets schema version **2**.

Active project state:

!`"${CLAUDE_PLUGIN_ROOT}/scripts/schema-check.sh"`

Decide based on the output above:
- `STATUS=OK` — proceed.
- `STATUS=MISMATCH` or `STATUS=LEGACY` — orchestrators are sensitive to schema drift because their subcommands depend on layout. Recommend `/shit:migrate` before running. Refuse to proceed unless the user explicitly requests best-effort.
- `STATUS=UNINITIALIZED` — tell the user to run `/shit:init` first.

---

## Step 1: Audit Transcripts

Run the full `/shit:audit-transcripts` workflow:

1. Discovery (worktree-aware) via `${CLAUDE_PLUGIN_ROOT}/scripts/audit/list-sessions.sh`
2. Parallel verification agents
3. Repair (serialized writes for any `MISSING_FOUND` results)
4. Final audit agent

### Step 1 Gate
- **SUCCESS** — Final audit returns ALL_COVERED, or MISSING_FOUND with repairs completed
- **FAILURE** — Agent errors, discovery script fails, or file write failures

If FAILURE, stop here.

---

## Step 2: Reader

Run the full `/shit:reader` workflow. Output: `specs/0-transcripts/reader_{DATETIME}.md`.

### Step 2 Gate
- **SUCCESS** — Reader file written
- **FAILURE** — File write fails or no transcripts found

---

## Step 3: Spec Reader

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/compile-spec.py
```

Output: `specs/2-spec/compiled/spec-reader_YYYY-MM-DD.md`.

### Step 3 Gate
- **SUCCESS** — Script exits 0 and output file created
- **FAILURE** — Script errors or output file missing

---

## Step 4: Status

Run the full `/shit:status` workflow. Output: `specs/4-docs/project-status.md`.

### Step 4 Gate
- **SUCCESS** — `specs/4-docs/project-status.md` updated and passes quality checks
- **FAILURE** — File write fails or quality checks fail

---

## Step 5: Spec Status

Run the full `/shit:spec-status` workflow. Output: `specs/4-docs/spec-status-report_{YYYY-MM-DD}.md`.

This step must run before steps 6 and 9 because it produces the dated report they consume.

### Step 5 Gate
- **SUCCESS** — Dashboard generated, file written
- **FAILURE** — File write fails or scan errors

---

## Step 6: Audit Spec

Run the full `/shit:audit-spec` workflow. It will read the same-day spec-status report from Step 5 to avoid redundant scanning. Output: `specs/4-docs/audit-spec-report_{YYYY-MM-DD}.md`.

### Step 6 Gate
- **SUCCESS** — Audit report generated, file written
- **FAILURE** — File write fails or audit errors

---

## Step 7: Attest Report

Run the full `/shit:attest-report` workflow. Spawns parallel workers for each active spec module. Output: `specs/4-docs/attestation-report_{YYYY-MM-DD}.md` plus per-module files in `specs/4-docs/attestations/`.

### Step 7 Gate
- **SUCCESS** — All worker reports collected, combined report generated
- **FAILURE** — Worker failures, file write failures

---

## Step 8: Distill

Run the full `/shit:distill` workflow. Reads all spec modules and ADRs, updates the BEGIN DISTILLED blocks in every gate file in `specs/gates/`.

This step must run before Step 9 because `/shit:verify` reads the distilled checks from the gate files. Distilling here ensures verification uses the freshest project rules.

### Step 8 Gate
- **SUCCESS** — All gate files updated, no conflicts that block verification
- **FAILURE** — File write failures, parse errors, or conflicts that prevent gate generation

If distillation surfaces stale checks or conflicts, it does NOT fail the gate — those are flagged for human review but the run continues. Only hard failures (file write errors, unparseable specs) block.

---

## Step 9: Verify

Run the full `/shit:verify` workflow. It will read the same-day reports from Steps 5, 6, 7 and the freshly distilled gate files from Step 8. Output: `specs/4-docs/verification-report_{YYYY-MM-DD}.md`.

### Step 9 Gate
- **SUCCESS** — Verification report generated, file written
- **FAILURE** — Build failure, test failure, or file write failure

---

## Completion

Report all 9 step results:

| Step | Command | Result | Detail |
|------|---------|--------|--------|
| 1 | audit-transcripts | SUCCESS/FAILURE | {summary} |
| 2 | reader | SUCCESS/FAILURE | {summary} |
| 3 | spec-reader | SUCCESS/FAILURE | {summary} |
| 4 | status | SUCCESS/FAILURE | {summary} |
| 5 | spec-status | SUCCESS/FAILURE | {summary} |
| 6 | audit-spec | SUCCESS/FAILURE | {summary} |
| 7 | attest-report | SUCCESS/FAILURE | {summary} |
| 8 | distill | SUCCESS/FAILURE | {summary} |
| 9 | verify | SUCCESS/FAILURE | {summary} |

**Files written:** list all files created or modified across all steps.

If all SUCCESS: "Heavy cleanup complete."
If any FAILURE: "Stopped at Step N: {reason}"
