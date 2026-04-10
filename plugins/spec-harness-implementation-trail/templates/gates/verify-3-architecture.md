# Verification Layer 3: Architecture Conformance

The architecture layer checks that the code follows the project's architectural rules — layer boundaries, abstraction placement, framework patterns, structural conventions, and anything else that qualifies as "how this project is built" rather than "what this project does."

Layer 3 runs against the **merged patch** — all work item diffs combined into a single change for the pipeline.

## Purpose

Invariants (layer 2) checks that individual requirements are satisfied. Architecture checks that the code *fits* — that it respects the structural decisions recorded in the project's ADRs and the architecture sections of its specs.

Architecture rules are the most project-specific part of verification. The checks here depend entirely on what your project's specs and ADRs say. The plugin ships with starter rules that apply to most projects; `/shit:distill` adds project-specific ones from your specs.

This is a check against recorded architectural decisions, not a code review of the architecture itself. If the ADR says X and the code does X, layer 3 passes — even if X turns out to be a bad idea. Code review is what catches "X turned out to be a bad idea." See `verify-2-invariants.md` for the longer note on what gates can and cannot replace.

## Inputs

- The merged patch (all work item diffs combined) representing the entire pipeline's change
- All spec modules with architecture-related requirements
- All ADRs
- The existing project structure (layout, module boundaries)

## Universal Checks

These apply to every project, regardless of language:

1. **Module/layer boundaries are respected** — if your project has a layered architecture, code in a lower layer must not import or reference code in a higher layer. The specific layer model comes from your ADRs.

2. **Abstraction placement is appropriate** — utilities live in utility modules, domain logic lives in domain modules, UI logic lives in UI modules. No domain logic leaking into UI, no UI concerns leaking into domain.

3. **Declared patterns are used where the spec says they should be** — if a spec requirement says "all foo must use bar," any new foo must use bar.

4. **No duplicate abstractions** — if the change introduces a new class/module/function that duplicates something that already exists, flag it. This isn't a hard failure, but it's always a warning worth surfacing.

5. **Public surface discipline** — new public API should be intentional. A new public class with no external consumer (yet) is flagged for review.

## Output

A structured report:

```
## Architecture Conformance

### Layer Boundaries
- ✓ No cross-layer violations detected
- ✗ `src/ui/auth.ts` imports from `src/infra/database.ts` — violates ADR-005

### Pattern Conformance
- ✓ REQ-AUTH-003: Uses the project's session interface as required
- ⚠ REQ-AUTH-005: Uses ad-hoc crypto instead of the sanctioned wrapper — see ADR-008

### Duplication
- ⚠ `Credential` class in `src/auth/credential.ts` duplicates `AuthToken` from `src/session/token.ts`
```

## Failure Mode

Layer violations, ADR conflicts, and pattern-discipline failures are hard failures. Duplication warnings and public-surface warnings are advisory — they escalate to human review but don't block advancement.

## Distilled Checks

_This section is managed by `/shit:distill`. Project-specific architectural rules derived from your specs and ADRs appear here — one distilled check per rule. Example distilled check:_

> **Verify pipeline isolation.** ADR-012 requires that pipeline agents only access files under their assigned worktree. For each new file operation in the diff, confirm the path is within the pipeline's worktree or is a clearly global resource (read-only system config, etc.).

<!-- BEGIN DISTILLED -->
<!-- (no distilled checks yet) -->
<!-- END DISTILLED -->
