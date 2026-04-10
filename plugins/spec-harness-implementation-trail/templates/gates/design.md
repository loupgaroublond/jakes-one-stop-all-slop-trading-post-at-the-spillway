# Gate: Design

This gate describes how the **design phase** of a pipeline works in this project. It is a process spec — distilled from the upstream PRD, specs, and ADRs by `/shit:distill`. Edit this file to match your project's design practice, or regenerate its distilled sections when the upstream specs change.

## Purpose

The design phase takes a stub — an idea, gap, or need that has entered the system — and turns it into a concrete, reviewed design ready for breakdown. At the end of this phase, you know *what* will be built and *why*, but not yet *how* to decompose it into work items.

## Inputs

- A pipeline document in `specs/pipeline/active/` with a stub section describing the idea
- Relevant spec modules (`specs/2-spec/`) and ADRs (`specs/3-adr/`) that inform the design
- Any referenced transcripts from `specs/0-transcripts/`

## Outputs

The pipeline document's design section contains, at minimum:

1. **Problem statement** — what need this addresses, in terms of existing requirements (cite `REQ-*` IDs)
2. **Approach** — the chosen approach, with alternatives considered briefly
3. **Spec impact** — which spec modules need updates, which requirements are new, which ADRs are affected
4. **Open questions** — anything unresolved that requires human input before breakdown

## Completion Criteria

_Distilled checks from upstream specs go here. Run `/shit:distill` to populate this section with project-specific checks derived from your spec modules and ADRs._

The following checks apply to every design phase:

- [ ] Problem statement cites at least one existing requirement, or declares the work as introducing new requirements (with a draft of them)
- [ ] Approach references the relevant ADRs, or explains why no ADR applies
- [ ] Spec impact section lists every spec module that will change
- [ ] Open questions section is either empty or flagged for human review
- [ ] Design is self-contained enough that a fresh agent could implement it without re-researching context

## Anti-patterns

- **Skipping the alternatives** — a one-line "we'll do X" with no mention of what else was considered. Even if the alternative was "do nothing," name it.
- **Hand-waving the spec impact** — saying "this touches the auth spec" without saying *which requirements* and *how*. Be specific.
- **Leaving open questions buried in prose** — if there's an open question, give it a label and put it in the Open Questions section so it can't be missed.

## Distilled Checks

_This section is managed by `/shit:distill`. Manual edits here are preserved across runs, but new distilled checks from the spec may be added or updated._

<!-- BEGIN DISTILLED -->
<!-- (no distilled checks yet — run /shit:distill after writing your first spec modules) -->
<!-- END DISTILLED -->
