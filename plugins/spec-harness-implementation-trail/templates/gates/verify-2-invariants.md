# Verification Layer 2: Invariants

The invariants layer asks whether the code actually satisfies the behavioral properties the spec asserts — not just whether the markers exist. It is a focused, spec-anchored check, not a code review. (See "Gates Are Not Code Review" below.)

Layer 2 runs against the **merged patch** — all work item diffs combined into a single change for the pipeline.

## Gates Are Not Code Review

This is the deepest of the verification layers, and it's the one most likely to be confused for code review. It isn't. Layer 2 only asks whether the code satisfies the specific properties the spec wrote down. It says nothing about readability, idiomaticity, error handling outside the spec, security beyond what the spec covers, performance, or any of the other things a thorough code review touches.

Verification gates can be **part of a complete code review process**, alongside three grapefruit, a glass of orange juice, and a human reviewer who actually reads the diff. They are not a substitute for one. A pipeline that passes every verification layer can still ship code that a competent reviewer would reject in five seconds. Plan accordingly.

## Purpose

Traceability (layer 1) confirms the graph is complete. Invariants confirms the code inside the graph does what it claims. This is the layer that catches the difference between "the provenance marker is on the class" and "the class actually implements the behavior the requirement describes."

Invariants are checked per-requirement, against the **Properties** and **Testable Assertion** fields of the requirement's spec block.

## Inputs

- The merged patch (all work item diffs combined) representing the entire pipeline's change
- The spec blocks for every requirement the pipeline claims
- Any ADRs the pipeline references

## Checks

For each claimed requirement, for each **property** in the requirement's spec block:

1. **Read the property statement**
2. **Examine the implementation code**
3. **Assign a verdict:**
   - **Holds** — the code clearly implements the property. Cite specific file and lines as evidence.
   - **Violated** — the code does not implement the property, or implements the opposite. Explain the specific gap.
   - **Unclear** — the code might implement the property but it's ambiguous. Explain what would need to be checked to resolve the ambiguity.

For each **testable assertion**:

1. **Read the assertion**
2. **Examine the test that claims to cover it**
3. **Assign a verdict:**
   - **Verified** — the test explicitly exercises the assertion's clauses
   - **Unverified** — no test actually exercises the assertion's clauses (or the test only partially exercises them, which counts as unverified — every clause must be covered)

## Output

Per-requirement report card with a row for each property and assertion, showing verdict and evidence.

## Failure Mode

**Violated** properties are hard failures. The pipeline cannot advance with violated invariants.

**Unverified** assertions are hard failures. Every clause of every testable assertion must be exercised by a test. Partial coverage is treated as no coverage — there is no "mostly verified" state.

**Unclear** verdicts escalate to human review. The verifier cannot decide; the human must either clarify the spec, change the code, or accept the ambiguity with a note.

## Distilled Checks

_This section is managed by `/shit:distill`. When your spec modules contain properties or assertions that can be turned into language-agnostic checks, they will appear here._

<!-- BEGIN DISTILLED -->
<!-- (no distilled checks yet) -->
<!-- END DISTILLED -->
