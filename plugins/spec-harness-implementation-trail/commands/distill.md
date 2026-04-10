# Distill Spec Rules into Gate Checks

Read the project's specs and ADRs and produce distilled, actionable checks for each gate file in `specs/gates/`. This is the workflow that turns abstract spec rules into concrete verification steps that `/shit:verify` can execute.

**Usage:** `/shit:distill` (single sweep across all specs and all gates)

## Purpose

The plugin separates two things:

1. **Specs** (in `specs/2-spec/` and `specs/3-adr/`) describe what the system *is* — the requirements, properties, invariants, architectural rules.
2. **Gates** (in `specs/gates/`) describe how to *verify* those things during the pipeline — the concrete checks each verification layer runs.

Distillation is the transformation between them. A spec module says "All session tokens must be salted with the user ID." The distilled gate check says "For each session token creation in the diff, confirm the user ID is included in the salt input." Same rule, different form. The spec is declarative; the distilled check is operational.

This command runs the transformation across the whole project in one pass.

## Process

### 1. Inventory all upstream rules

Read every spec module in `specs/2-spec/` (excluding `000-index.md` and `001-introduction.md`) and every ADR in `specs/3-adr/`. For each, extract:

- **Requirements** — the `### REQ-XXX-NNN: Title` blocks with their properties and testable assertions
- **Invariants** — properties that apply project-wide, not just to one requirement
- **Architectural rules** — module boundaries, layer dependencies, framework patterns
- **Process rules** — anything the spec says about *how* the project is built

Categorize each rule by which gate it belongs to:

| Rule type | Target gate |
|-----------|-------------|
| Process for design phase | `gates/design.md` |
| Process for breakdown phase | `gates/breakdown.md` |
| Per-work-item scope rules (run before merge) | `gates/verify-0-scope-check.md` |
| Spec → code → test traceability (run on merged patch) | `gates/verify-1-traceability.md` |
| Per-requirement properties and assertions | `gates/verify-2-invariants.md` |
| Module/layer boundaries, framework patterns | `gates/verify-3-architecture.md` |
| Dependency surfaces, blast radius rules | `gates/verify-4-blast-radius.md` |
| Coverage expectations, follow-up rules | `gates/verify-5-gaps.md` |

A rule may belong to more than one gate; that's fine — it gets distilled for each.

### 2. Distill each rule

For each rule, write an actionable check. The check must:

- **Describe what to verify, not how to verify it.** Don't prescribe `grep`, `find`, or any specific tool. The agent that runs the check picks the right mechanism.
- **Be language-agnostic.** Refer to "declarations," "modules," "files" — not `class`, `func`, or any language keyword. If the rule is intrinsically language-specific, name the language and explain why.
- **Cite its source.** Every distilled check ends with a reference to the upstream rule it came from: `(from REQ-AUTH-007)` or `(from ADR-005 §3)`.
- **Be testable in principle.** Even if no automation exists, an agent reading the check should know what evidence to look for.

A good distilled check looks like:

> **Verify session token salting.** For each session token creation in the change, confirm the user's identifier is included in the salt input. Reject any creation that uses only random bytes or only the username string. (from REQ-AUTH-007)

A bad distilled check looks like:

> Run `grep -r 'createToken' src/ | grep -v 'salt.*userId'`

(Too prescriptive — assumes shell, assumes paths, assumes a specific implementation pattern.)

### 3. Update the gate files

For each gate file in `specs/gates/`, update the section between `<!-- BEGIN DISTILLED -->` and `<!-- END DISTILLED -->`. Replace the contents with the distilled checks for that gate, organized by source rule.

Format each distilled check as:

```markdown
### From REQ-AUTH-007: Session Token Salting

**Verify session token salting.** For each session token creation in the change, confirm the user's identifier is included in the salt input. Reject any creation that uses only random bytes or only the username string.
```

Group checks by source: all checks from one requirement go under the same heading. Order checks within a gate by source ID.

**Preservation rule:** Anything outside the `BEGIN DISTILLED` / `END DISTILLED` markers is user content and must not be touched. The user's manual edits to the gate's purpose, completion criteria, anti-patterns, etc. are preserved across runs.

### 4. Detect orphans and conflicts

After updating the gates, scan for:

- **Orphaned distilled checks** — checks that reference a requirement ID that no longer exists in any spec module. These are removed and listed in the report.
- **Stale checks** — checks whose upstream rule has changed wording. The check may need rewriting; flag it for human review rather than silently rewriting it.
- **Conflicts** — two rules from different sources that produce contradictory checks. Flag for human review.

### 5. Report

Print a summary:

```
## Distillation Summary

Sources read:
- Spec modules: N
- ADRs: N

Distilled checks written:
- gates/design.md: N checks (N from specs, N from ADRs)
- gates/breakdown.md: N checks
- gates/verify-0-scope-check.md: N checks
- gates/verify-1-traceability.md: N checks
- gates/verify-2-invariants.md: N checks
- gates/verify-3-architecture.md: N checks
- gates/verify-4-blast-radius.md: N checks
- gates/verify-5-gaps.md: N checks

Orphans removed: N
Stale checks (need review): N
Conflicts (need review): N
```

If any stale checks or conflicts exist, list them with file paths so the user can address them.

## Key Files

- `specs/2-spec/*.md` — spec modules (input)
- `specs/3-adr/*.md` — ADRs (input)
- `specs/gates/*.md` — gate files (output, BEGIN/END DISTILLED blocks only)

## When to Run

- After significant changes to spec modules or ADRs
- As part of `/shit:update-verifications` (heavy cleanup, step 8)
- Before `/shit:verify` if the user has updated specs since the last verification

## Notes

- Distillation is *read-only* for specs and ADRs. It never modifies upstream sources.
- Distillation is *idempotent for gate non-distilled content*. Running `/shit:distill` twice in a row should produce the same gate files (assuming no spec changes between runs) without duplicating or destroying user content.
- If a gate file has been deleted, distillation does NOT recreate it. Use `/shit:init` to scaffold missing gate files.
