# Verification Layer 1: Traceability

The traceability layer checks that the graph from requirements to code to tests is complete. Every requirement this pipeline claims to implement must have code with a provenance marker, and every code file with a marker must have at least one test that references the same requirement.

Layer 1 runs against the **merged patch** — all work item diffs combined into a single change for the pipeline. By the time layer 1 runs, layer 0 (scope check) has already passed for every individual work item.

## Purpose

Traceability catches the gap where work was done but the machine-readable links weren't created. Without those links, `/shit:spec-status` and `/shit:trace` can't see the new code. This is a structural check — it does not assess whether the code is *correct*, only whether the graph is *complete*. It is not a code review; see `verify-2-invariants.md` for the longer note on what gates can and cannot replace.

## Inputs

- The pipeline document's work breakdown section (to know which requirements were claimed)
- The merged patch (all work item diffs combined) representing the entire pipeline's change
- The current state of all spec modules (to look up requirement definitions)

## Checks

For every requirement ID claimed in the pipeline's work breakdown:

1. **Code marker exists** — at least one code file contains a provenance marker for this requirement ID
2. **Test marker exists** — at least one test file contains a provenance marker or tag for this requirement ID
3. **The code marker actually marks related code** — the marker is adjacent to a declaration (class, function, module), not floating in an unrelated section
4. **The test actually exercises the claimed behavior** — the tagged test's assertions are related to the requirement's testable assertion, not just structurally tagged

Additionally, for every code file changed in the diff:

5. **If the file claims a requirement, the test coverage exists** — a file with a marker must have a corresponding test file with a matching marker or tag

## Output

A traceability matrix — for each requirement, a row showing whether code, tests, and both exist. Any missing link is a gap.

| Requirement | Code Marker | Test Marker | Verdict |
|-------------|:-----------:|:-----------:|---------|
| REQ-XXX-NNN | ✓ file.ext | ✓ test.ext | complete |
| REQ-XXX-MMM | ✓ file.ext | — | incomplete |

Verdicts: **complete**, **incomplete** (missing code or test marker), **orphaned** (marker exists in code but the requirement is not claimed by this pipeline).

## Failure Mode

If any claimed requirement is incomplete, the verification layer fails and the pipeline cannot advance. The fix is always: add the missing marker, or withdraw the claim from the work breakdown.

Orphaned markers are warnings, not failures — they indicate a previous pipeline didn't clean up, but they don't block the current one.

## Distilled Checks

_This section is managed by `/shit:distill`._

<!-- BEGIN DISTILLED -->
<!-- (no distilled checks yet) -->
<!-- END DISTILLED -->
