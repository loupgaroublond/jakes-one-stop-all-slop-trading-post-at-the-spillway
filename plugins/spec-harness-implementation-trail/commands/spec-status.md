---
description: Scan spec modules and provenance markers to produce a live coverage dashboard
allowed-tools: Bash(*schema-check.sh*)
---

# Spec Status Dashboard

Scan all spec modules and provenance markers to produce a live coverage dashboard.

## Schema check

This command targets schema version **2**.

Active project state:

!`"${CLAUDE_PLUGIN_ROOT}/scripts/schema-check.sh"`

Decide based on the output above:
- `STATUS=OK` — proceed.
- `STATUS=MISMATCH` or `STATUS=LEGACY` — the project is on schema v$ACTIVE; this command targets v$LATEST. Recommend `/shit:migrate`. If the user wants to defer and the rest of this command does not depend on the changed layout, you may proceed in best-effort mode and warn about possibly stale results.
- `STATUS=UNINITIALIZED` — tell the user to run `/shit:init` first.

## Process

### 1. Parse All Spec Modules

Read every spec file matching `specs/2-spec/NNN-*.md` (three-digit prefix, excluding `000-index.md` and `001-introduction.md`). For each file, extract every requirement block:

- **Requirement ID and title** from lines matching `^### (REQ-[A-Z]+-[0-9]{3}): (.+)$`
- **Priority** from `**Priority:** (must-have|should-have|deferred)` within the requirement block
- **Module number and name** from the filename

Build a master list of all requirements with: module, req ID, title, priority.

### 2. Scan Code for Provenance Markers

Provenance markers are language-specific. Look for any of these comment patterns adjacent to declarations in the project's source code (everything outside `specs/`, `node_modules/`, build directories, and test files — discover the source layout from the project's CLAUDE.md or by inspecting the directory structure):

```
@provenance: REQ-XXX-NNN
@provenance REQ-XXX-NNN
provenance: REQ-XXX-NNN
MARK: - Provenance: REQ-XXX-NNN
```

The marker may appear in any line-comment style the language uses (`//`, `#`, `--`, `;`). Extract every `REQ-PREFIX-NNN` from matching lines. A single marker line may contain multiple comma-separated requirement IDs. Map each requirement ID to the file(s) it appears in.

### 3. Scan Tests for Provenance Tags or Markers

For test files (the project's test directory), look for both:

**Provenance markers** (same patterns as above)

**Test framework tags** that match the requirement ID convention:

```
@Tag(.reqXXXNNN)
.tags(.reqXXXNNN)
@requirement("REQ-XXX-NNN")
@pytest.mark.req_XXX_NNN
```

Convert tag format to requirement ID: `.reqAUTH001` → `REQ-AUTH-001`. The plugin's commands accept any reasonable transformation; if the project uses a different tagging convention, the project's CLAUDE.md should describe it.

Map each requirement ID to the test file(s) it appears in.

### 4. Derive Status

For each requirement:

- `specified` — exists in spec only (no code markers, no test markers)
- `implemented` — has at least one code provenance marker
- `tested` — has at least one test provenance tag (implies implemented)

### 5. Output Per-Module Tables

For each spec module, output a table:

```
## Module 004 — Authentication (REQ-AUTH)

| Req ID | Title | Priority | Status | Code Files | Test Files |
|--------|-------|----------|--------|------------|------------|
| REQ-AUTH-001 | Login Flow | must-have | tested | src/auth/login.ts | tests/auth/login.test.ts |
| REQ-AUTH-002 | Session Management | must-have | implemented | src/auth/session.ts | — |
...
```

- Code/Test Files columns show paths relative to the project root
- If multiple files, comma-separate them
- **Sort rows by implementation status:** `specified` first, then `implemented`, then `tested`. Within each status group, sort by req ID.

### 6. Output Summary Table

```
## Summary

| Module | Prefix | Total | Specified | Implemented | Tested | Coverage% |
|--------|--------|-------|-----------|-------------|--------|-----------|
| 002-invariants | REQ-INV | 8 | 8 | 0 | 0 | 0% |
...
| **TOTAL** | | **162** | **162** | **0** | **0** | **0%** |
```

Coverage% = (Tested + Implemented) / Total × 100, rounded to nearest integer.

**Sort rows by Coverage% ascending** (least covered modules first). The TOTAL row stays at the bottom.

### 7. Flag Anomalies

After the summary table, list any anomalies found:

- **Orphaned provenance:** Code or test files referencing requirement IDs that don't exist in any spec module
- **Must-have gaps:** Must-have requirements still at `specified` status (expected on first run — note this)
- **Deferred-but-implemented:** Requirements marked `deferred` priority that have implementation markers (not necessarily wrong, but worth flagging)

## Key Files

- `specs/2-spec/000-index.md` — module list and requirement counts (use to verify scan completeness)
- `specs/2-spec/NNN-*.md` — spec modules
- Project source files — provenance markers (location varies; consult project's CLAUDE.md if unsure)
- Project test files — provenance tags

## Output

Display the full dashboard in the conversation.

Additionally, write the complete dashboard to `specs/4-docs/spec-status-report_{YYYY-MM-DD}.md` (using today's date, overwriting any same-day report). This file is consumed by downstream commands (`/shit:audit-spec`, `/shit:verify`) to avoid redundant provenance scanning.
