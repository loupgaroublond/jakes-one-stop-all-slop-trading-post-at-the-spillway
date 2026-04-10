# Reification Chain

## Overview

Reification is the progressive materialization of abstract ideas into concrete artifacts. Every document in this project belongs to exactly one stage in the reification chain. Documents flow forward through numbered stages, with each stage consuming and refining the output of prior stages — a search through latent space that finds code, tests, and documentation.

```
0-transcripts → 1-prd → 2-spec → 3-adr → [code] → [tests] → 4-docs → [product]
```

Stages 4-6 (code, tests, product) live in the main project structure, not in `specs/`.

## Stages

### Stage 0: Transcripts (`0-transcripts/`)

Raw design conversations and their artifacts. This is the primary source material.

**Contents:**
- Interview transcripts (`transcript_*.md`) — High-fidelity records of design discussions using [U]/[C]/[T]/[S] notation
- Reader syntheses (`reader_*.md`) — Compiled summaries of all transcripts (machine-generated, latest is authoritative)
- Vocabulary files (`vocab_*.md`) — Collected terminology decisions
- Notes (`notes_*.md`) — Topical notes from early sessions
- Process meta-doc (`process.md`) — Tracks open questions, tangent legend, current state

**Update trigger:** After any design conversation (via `/shit:conceive`)
**Verification:** `/shit:audit-transcripts` checks all sessions have corresponding transcripts

### Stage 1: Product Requirements (`1-prd/`)

Formal requirements derived from transcripts. The PRD is the canonical statement of what the system must do.

**Contents:**
- `prd_*.md` — Current PRD (versioned by date)

**Update trigger:** When design conversations reveal new requirements or change existing ones
**Verification:** Every transcript topic should be reflected in PRD sections

### Stage 2: Formal Specifications (`2-spec/`)

Testable, traceable specifications derived from the PRD. Each spec module covers a domain and maps requirements back to PRD sections. Requirements follow the pattern `REQ-PREFIX-NNN` where `PREFIX` identifies the module (three or more uppercase letters) and `NNN` is a three-digit number.

**Contents:**
- `000-index.md` — Traceability matrix + coverage tracking
- `001-introduction.md` — Conventions, numbering, cross-reference syntax
- `NNN-<name>.md` — Domain spec modules (numbered, prefixed)
- `compiled/` — Generated compiled spec reader (from `/shit:spec-reader`)

**Update trigger:** When PRD changes or when implementation reveals specification gaps
**Verification:** `000-index.md` must account for every PRD section; each module tracks its own completeness

### Stage 3: Architecture Decision Records (`3-adr/`)

Architectural decisions and the research that informed them. ADRs record the "why" behind technical choices.

**Contents:**
- `ADR-NNN-*.md` — Formal decision records

**Update trigger:** When spec requirements drive architectural choices
**Verification:** Each ADR should reference the spec requirements it addresses

### Stages 4-6: Code, Tests, Product

These live in the main project structure (`src/`, `tests/`, or whatever your project uses) and the built application. They consume specs and ADRs.

Code and test files carry provenance markers linking back to spec requirements:

```
// @provenance: REQ-AUTH-003
class AuthenticationService { ... }
```

The exact marker syntax depends on your language. The plugin looks for both comment-style markers and test-framework tags (e.g., `@Tag(.reqAUTH003)`).

### Stage 7: Documentation (`4-docs/`)

Post-implementation documentation that describes the built system, plus generated reports from verification commands. Written after code exists.

**Contents:**
- Architecture documentation (describes what was built)
- Status tracking (current implementation state) — updated by `/shit:status`
- Generated reports:
  - `spec-status-report_*.md` — from `/shit:spec-status`
  - `audit-spec-report_*.md` — from `/shit:audit-spec`
  - `attestation-report_*.md` — from `/shit:attest-report`
  - `verification-report_*.md` — from `/shit:verify`

**Update trigger:** After significant implementation milestones, or as part of verification runs
**Verification:** Should accurately reflect current code state

### Gates (`gates/`)

Gate files are *process specs* — they describe how work moves through the pipeline in *your* project. They are distilled from the upstream specs (stages 1-3) by `/shit:distill`, then used by the verification commands to run project-specific checks.

There are two categories of gates:

1. **Phase gates** — `design.md`, `breakdown.md`. These describe the process of each phase.
2. **Verification layers** — `verify-0-scope-check.md` through `verify-5-gaps.md`. These describe what each verification layer checks. Layer 0 (scope check) runs against each work item's diff individually before merge; layers 1–5 run against the merged patch (all work item diffs combined into a single change).

The plugin ships with starter gate files. You edit them or regenerate them via `/shit:distill`.

### Pipeline (`pipeline/`)

The pipeline tracks changes as they move through the reification chain. Each significant change becomes a pipeline document with YAML frontmatter tracking its phase (design → breakdown → execution → verification → archived).

The pipeline is *about* the spec system — it's how the spec evolves over time. It's not an agent orchestration system. If you want agent orchestration, plug the pipeline into your own harness.

## Flow Rules

1. **Forward only** — Each stage consumes from stages before it, never after
2. **Traceability** — Every document references its upstream sources. Code and tests carry provenance markers linking back to spec requirements. Forward references (spec → code) are computed by tooling, not manually maintained.
3. **Single home** — Every document belongs to exactly one stage
4. **No "reference" bucket** — Everything is either input, requirement, specification, decision, gate, pipeline work, or post-code documentation
5. **Plans are ephemeral** — OODA loop artifacts are not a permanent stage

## Incremental Update Flow

When new design conversations happen:

1. Transcribe → new `transcript_*.md` in `0-transcripts/`
2. Update reader (via `/shit:reader`)
3. Update PRD in `1-prd/` if requirements changed
4. Update relevant spec modules in `2-spec/`
5. Update `000-index.md` traceability + status
6. If spec changes affect architecture → update/create ADRs in `3-adr/`
7. Run `/shit:distill` to update gate files with any new distilled checks
8. Downstream: code → tests → docs as needed

## Verification Checks

Each reification stage can be verified against its upstream:

| Check | Upstream | Downstream | Tool |
|-------|----------|------------|------|
| Transcript coverage | Sessions | Transcripts | `/shit:audit-transcripts` |
| Spec coverage | PRD | Spec modules | `/shit:audit-spec` |
| Code coverage | Spec | Code | `/shit:spec-status` (provenance markers) |
| Test coverage | Spec | Tests | `/shit:spec-status` (provenance tags) |
| Semantic conformance | Spec properties | Code + Tests | `/shit:attest` — verifies code satisfies behavioral properties, not just structural links |
| Requirement traceability | Requirement | Full chain | `/shit:trace REQ-ID` |
| Unified verification | Everything | Everything | `/shit:verify` |
