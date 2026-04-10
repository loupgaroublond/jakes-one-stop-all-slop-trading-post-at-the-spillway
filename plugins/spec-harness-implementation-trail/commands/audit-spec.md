# Spec Audit — PRD-to-Spec Coverage Verification

Walk the entire pipeline checking for gaps between PRD, spec modules, code, and tests.

## Process

### 1. Extract PRD Section Headers

Read the most recent PRD file in `specs/1-prd/prd_*.md` and extract all `## N. Title` and `## N.N Title` section headers. Build a list of all PRD sections with their numbers and titles.

### 2. Load Coverage Matrix

Read `specs/2-spec/000-index.md` and extract:

**PRD Coverage Matrix:** Map each PRD section to its spec module(s) and status. Note which sections are "context-only" (no spec needed).

**Module Status Overview:** Extract the claimed requirement counts per module (the "Total" column).

### 3. Verify Each Spec Module

For each spec module listed in the index (`002-*.md` and up):

1. Read the spec file
2. Count actual requirement headers matching `^### (REQ-[A-Z]+-[0-9]{3}):`
3. Compare against the claimed count in the index
4. Extract any Upstream References section — verify PRD sections are listed
5. Extract any Downstream References section — note claimed code and test directories

### 4. Verify Downstream References

For each spec module's Downstream References (if present):

- Check if claimed code directories/files exist
- Check if claimed test directories/files exist
- Flag missing paths

### 5. Load Provenance Coverage

If `specs/4-docs/spec-status-report_{YYYY-MM-DD}.md` exists (today's date), read it and extract the per-module coverage data (implementation% and test%). This avoids redundant provenance scanning when run after `/shit:spec-status` or as part of `/shit:update-verifications`.

If no same-day spec-status report exists, fall back to computing provenance coverage directly:

- Scan project source files for any of these provenance marker patterns:
  ```
  @provenance: REQ-PREFIX-NNN
  provenance: REQ-PREFIX-NNN
  MARK: - Provenance: REQ-PREFIX-NNN
  ```
- Scan project test files for the same patterns AND test framework tags following the convention (e.g., `.reqAUTH001`, `@requirement("REQ-AUTH-001")`)
- Map requirement IDs to code files and test files
- Derive status per requirement: specified / implemented / tested

### 6. Output Section 1 — PRD Coverage

```
## PRD Coverage

| PRD Section | Title | Spec Module | Index Status | Verified |
|-------------|-------|-------------|--------------|----------|
| §1 | Executive Summary | (context) | — | — |
| §2 | Authentication | 004-auth.md | complete | ✓ |
...
```

"Verified" column: ✓ if the spec module exists and its Upstream References mention this PRD section. ✗ if not.

### 7. Output Section 2 — Spec Module Health

```
## Spec Module Health

| Module | Prefix | Claimed | Actual | Match? | Implemented | Tested | Coverage% |
|--------|--------|---------|--------|--------|-------------|--------|-----------|
| 002-invariants | REQ-INV | 8 | 8 | ✓ | 0 | 0 | 0% |
...
```

- Claimed = count from index
- Actual = count from scanning the spec file
- Match? = ✓ if equal, ✗ with note if not
- Coverage% = (Implemented + Tested) / Actual × 100

### 8. Output Section 3 — Gap Analysis

Report categories of issues:

**Critical Gaps** — Must-have requirements with no implementation path:

```
### Critical Gaps
- REQ-AUTH-001 (must-have): User Login Flow — no code provenance
- REQ-AUTH-002 (must-have): Session Management — no code provenance
...
```

On first run with zero provenance markers, note: "All must-have requirements lack provenance — this is expected. Provenance markers are added incrementally as code is touched."

**Index Discrepancies** — Mismatches between index claims and reality:

```
### Index Discrepancies
- Module 004: index claims 10 requirements, file has 9 (missing REQ-AUTH-XXX?)
```

**Downstream Reference Issues** — Missing files or directories:

```
### Downstream Reference Issues
- Module 008 claims code in src/shell/ — directory not found
```

**Unmapped PRD Sections** — PRD sections not covered by any spec module (beyond known context-only sections):

```
### Unmapped PRD Sections
- §3.4 Audit Logging — no spec module covers this
```

**Orphaned Provenance** — Code/test markers referencing nonexistent requirement IDs:

```
### Orphaned Provenance
- src/old/legacy.ts: marker REQ-LEGACY-001 — no such requirement in any spec module
```

### 9. Output Section 4 — PRD Pipeline Flow (Top-to-Bottom)

Trace each PRD section through the full pipeline to show what percentage of the PRD appears downstream in implementation and testing.

**Per-PRD-Section Table:** Group PRD sections by their spec module. For each group, show the PRD section(s), spec module, total requirements, implemented count, tested count, Code%, and Test%.

```
## PRD Pipeline Flow (Top-to-Bottom)

### Per-PRD-Section Downstream Coverage

| PRD Section(s) | Spec Module | Reqs | Impl'd | Tested | Code% | Test% |
|----------------|-------------|------|--------|--------|-------|-------|
| §2 Auth | 004-auth | 8 | 4 | 3 | 50% | 38% |
| §3 Persistence | 005-persistence | 10 | 8 | 3 | 80% | 30% |
...
```

**Aggregate Pipeline Flow:** Show the full pipeline as a flow diagram with counts and percentages at each layer transition:

```
### Aggregate Pipeline Flow

PRD  ━━━  N sections
       │ X% coverage
       ▼
Spec ━━━  N requirements across N modules
       │ X% have code provenance
       ▼
Code ━━━  N requirements traced to source
       │ X% of implemented reqs have test tags
       ▼
Tests ━━━  N requirements traced to tests
```

Plus a transition rate table:

| Layer Transition | Rate |
|------------------|------|
| PRD → Spec | X% |
| Spec → Code | X% (N/N) |
| Spec → Tests | X% (N/N) |
| Code → Tests | X% (N/N) |

**Unimplemented Breakdown:** Categorize the unimplemented requirements into:

- **Explicitly deferred** — items marked deferred in scope or spec
- **Meta/process** — requirements that describe standards/processes with no code artifact
- **Genuinely unimplemented** — features that need building
- **Arguably provenance-able** — existing code that could be tagged but isn't

**Test Coverage Gaps:** Identify modules with the widest gap between implementation and test coverage (highest leverage for adding tests). Show module, Code%, Test%, and gap in percentage points.

### 10. Summary Statistics

```
## Summary

- **PRD sections:** N total, N covered, N context-only
- **Spec modules:** N total, all present
- **Total requirements:** N
- **Implementation coverage:** N/N (X%)
- **Test coverage:** N/N (X%)
- **Index accuracy:** X/N modules match claimed counts
- **Downstream references:** X/Y paths verified
- **Deferred (no code expected):** ~N requirements
- **Meta/process (no code artifact):** ~N requirements
- **Adjusted code provenance:** N/N active reqs (X%)
- **Orphaned provenance:** N
- **Unmapped PRD sections:** N
```

## Key Files

- `specs/1-prd/prd_*.md` — most recent PRD
- `specs/2-spec/000-index.md` — coverage matrix and module index
- `specs/2-spec/*.md` — spec modules
- Project source files — code provenance
- Project test files — test provenance

## Output

Display the full audit in the conversation.

Additionally, write the complete audit to `specs/4-docs/audit-spec-report_{YYYY-MM-DD}.md` (using today's date, overwriting any same-day report). This file is consumed by downstream commands (`/shit:verify`) to avoid redundant pipeline traceability scanning.
