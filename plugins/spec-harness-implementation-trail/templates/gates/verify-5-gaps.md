# Verification Layer 5: Gap Scan

The gap scan is the zoom-out layer. It asks: *what should have been addressed but wasn't?* It produces new stubs for the pipeline backlog rather than blocking the current pipeline.

Layer 5 runs against the **merged patch** and the full pipeline document — it needs the whole picture to assess what was and wasn't covered.

## Purpose

By the time a pipeline reaches layer 5, layers 1–4 have confirmed the work is traceable, satisfies its claimed invariants, conforms to the recorded architecture, and doesn't break its dependents. Layer 5 looks at what *else* the work surfaced — what new questions it raised, what it touched but didn't address, what it revealed about the spec itself.

This is the layer most prone to being skipped. It feels optional. But skipping it means accumulating quiet debt: every pipeline leaves behind a trail of "we noticed but didn't deal with it" that nobody ever comes back to. The gap scan formalizes the trail.

Like the other layers, this is not a code review. The gap scan only catches things visible from the spec/pipeline perspective — it cannot, for example, notice that a function is harder to read than it should be, or that a module is doing too much. See `verify-2-invariants.md` for the longer note on what gates can and cannot replace.

## Inputs

- The merged patch (all work item diffs combined) representing the entire pipeline's change
- The completed pipeline document (design log, work breakdown, verification reports from layers 0–4)
- The current state of the spec
- The current state of the pipeline backlog

## Checks

1. **Requirement gaps** — Are there requirements in the PRD or spec that should have been addressed by this pipeline but weren't? If the pipeline scope says "auth rework," did every active auth requirement get touched? If not, why not?

2. **New invariants** — Did the work reveal new invariants that should exist in the spec but don't? (Example: "while implementing this we discovered that all session tokens must be salted with the user ID — that's not in the spec yet.")

3. **Open design questions** — Did anything come up during execution that needed a judgment call? Those judgment calls are decisions, and decisions should be recorded. Either as design log notes, ADRs, or new spec content.

4. **Spec drift** — Did the implementation diverge from the spec in ways that the spec should now reflect? (Example: the spec says X, the code does X', and X' is correct — the spec is the one that needs to change.)

5. **Follow-up items** — TODOs or hacks left in the code that need to be tracked as future work, not silently lived with.

6. **Test coverage gaps** — Areas of the change that *technically* pass layer 1 (markers exist) but have weak test depth. These become test-improvement stubs.

## Output

A gap scan report listing every gap found, each in the form of a stub that can become a future pipeline:

```
## Gap Scan

### New Stubs Generated

1. **Salt session tokens with user ID** (REQ-AUTH gap)
   While implementing REQ-AUTH-007, we discovered that session tokens
   should be salted with the user ID to prevent token reuse across users.
   This is not in the spec. → Should become a new requirement and pipeline.

2. **Update REQ-AUTH-003 wording** (spec drift)
   The current wording says "the system stores hashed credentials," but
   we're now storing argon2-hashed credentials with project-specific
   parameters. The spec should reflect the algorithm choice. → Spec edit pipeline.

3. **Add adversarial tests for the login flow** (test depth gap)
   The login tests cover happy paths and basic failures, but not
   timing attacks or credential stuffing. → Test improvement pipeline.

### Spec Modules Needing Updates
- `specs/2-spec/004-auth.md` — needs update for the salt change

### Open Design Questions
- (none in this pipeline)
```

## Failure Mode

Layer 5 does not fail in the blocking sense. Its output becomes new pipeline backlog. The "failure" is when layer 5 is skipped entirely or runs without producing any stubs — which usually means the verifier didn't actually look hard enough.

A pipeline that produces zero gap scan output is suspicious. Real work nearly always reveals something.

## Distilled Checks

_This section is managed by `/shit:distill`._

<!-- BEGIN DISTILLED -->
<!-- (no distilled checks yet) -->
<!-- END DISTILLED -->
