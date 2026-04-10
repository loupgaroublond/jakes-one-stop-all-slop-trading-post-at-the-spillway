# Verification Layer 0: Scope Check

The scope check is the per-work-item layer. It runs against the diff produced by each individual work item, before any work items are merged together. It is the first verification layer to run in the pipeline, and the only one that runs per work item rather than per merged patch.

## Where This Fits in the Workflow

A pipeline diverges into multiple work items during the breakdown phase. Each work item is implemented independently and produces its own diff. The pipeline's verification flow is:

1. **For each work item**, layer 0 (scope check) runs against the work item's diff in isolation. The work item must pass scope check before its diff is allowed to enter the merge.
2. **All work item diffs are merged** into a single patch representing the entire pipeline's work.
3. **Layers 1–5 run against the merged patch**, not against any individual work item.

This is deliberate. Scope check needs the per-item context (one work item declared one scope) to catch creep early. Layers 1–5 need the merged context (the whole pipeline is what changes the spec coverage, the architecture, the blast radius) to assess the change as a unit. Mixing the two layers would either let scope creep slip through or hide cross-item interactions from the higher layers.

## Purpose

Layer 0 catches scope creep when the diff is small enough to fix in place. It is *not* a code review. It does not assess correctness, style, or design quality. It only asks whether the change matches its declared scope. Layers 1–5 handle their own slices of the rest, but none of them are code review either — see `verify-2-invariants.md` for the longer note on what gates can and cannot replace.

## Inputs

- A single work item's declared scope and acceptance criteria from the breakdown
- The diff produced by that work item (and only that work item — not merged with anything else)

## Checks

1. **Diff matches scope** — every file in the diff is named in the work item's scope, or is a clearly necessary side effect (e.g., a generated file, a test file paired with a source file). Unrelated files in the diff are scope creep and must be removed.

2. **All expected files are touched** — the work item's scope says "modify X, add Y, delete Z." All three must appear in the diff.

3. **No unexpected files** — files not predicted by the scope but present in the diff need a justification. If the justification is "this change required also updating Q," that's fine but it should be noted in the work item's outcome.

4. **Acceptance criteria are addressed** — for each acceptance criterion, the diff should show the change that satisfies it. The verifier doesn't run the criteria (that's layer 1's traceability or layer 2's invariants); it just confirms the criteria are *attempted* in the diff.

5. **No obvious red flags** — debug prints, commented-out code, hardcoded credentials, TODO comments without an associated tracking item. These aren't correctness issues but they're scope-discipline issues.

## Output

A short scope report per work item:

```
## Scope Check: wi-003 — Add session expiry handling

### Declared Scope
- Modify: src/auth/session.ts
- Add: src/auth/session-expiry.ts
- Add: tests/auth/session-expiry.test.ts

### Diff
- ✓ src/auth/session.ts (38 lines changed)
- ✓ src/auth/session-expiry.ts (new, 67 lines)
- ✓ tests/auth/session-expiry.test.ts (new, 41 lines)
- ⚠ src/auth/credential.ts (4 lines changed) — NOT in declared scope

### Acceptance Criteria
- ✓ Sessions older than 24h return EXPIRED
- ✓ Expiry check uses the configured clock interface
- ✓ Refresh extends expiry by 24h from refresh time

### Red Flags
- (none)

### Verdict
SCOPE_CREEP — `credential.ts` change is not declared. Either remove it or amend the work item scope to include it.
```

## Failure Mode

Scope creep is a soft failure. The verifier flags it and the worker fixes it — either by removing the unrelated change or by amending the work item scope to include it. Either is acceptable; the key is that it's a deliberate decision, not silent drift.

A scope check failure does NOT advance the work item into the merge. The work item bounces back for adjustment, then re-runs scope check from scratch. Only after all work items in the pipeline pass layer 0 does the merge happen and layers 1–5 begin.

## Distilled Checks

_This section is managed by `/shit:distill`._

<!-- BEGIN DISTILLED -->
<!-- (no distilled checks yet) -->
<!-- END DISTILLED -->
