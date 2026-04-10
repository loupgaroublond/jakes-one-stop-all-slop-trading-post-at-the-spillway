---
id: pNNNN
slug: short-name
title: "Pipeline Title"
phase: design
priority: 2
source: ""
blocked-by: []
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# pNNNN — Pipeline Title

## Brief
One-paragraph summary of what this pipeline accomplishes.

## Status
Currently in **design** phase. Next action: (what needs to happen next).

## Stub
The original idea, need, or gap that prompted this pipeline. Keep this section pristine — it's the historical record of why the pipeline exists.

## Design Log
Chronological record of research, discussions, and decisions during the design phase. Each entry is dated. Include references to specs, ADRs, and transcripts that informed the design.

### YYYY-MM-DD — First entry
(Notes go here.)

## Design Statements
At the end of the design phase, distill the design log into a small set of concrete decisions that the breakdown phase can act on. Each decision is one sentence.

1. (Decision goes here.)
2. ...

## Work Breakdown
Filled in during the breakdown phase. List work items with:

- A short title
- Scope (what's included, what's not)
- Acceptance criteria (concrete checklist)
- Context references (which spec modules, ADRs, files a worker needs to read)
- Dependencies on other work items

### wi001 — (work item title)
- **Scope:** ...
- **Acceptance criteria:**
  - [ ] ...
- **Context:** ...
- **Depends on:** (other wi IDs, or "none")

## Verification Results
Filled in during the verification phase. Layers that don't apply are explicitly noted as "not applicable" with justification.

Layer 0 runs against each work item's diff individually before any merging. Layers 1–5 run once against the merged patch (all work items combined into a single change).

### Layer 0 — Scope Check (per work item)
One subsection per work item. Each work item must pass scope check before its diff enters the merge.

#### wi001
(Scope check results for wi001.)

#### wi002
(Scope check results for wi002.)

### Merge
After all work items pass layer 0, their diffs are merged into a single patch. Note here when the merge happened and any merge issues encountered.

### Layer 1 — Traceability
(Results go here.)

### Layer 2 — Invariants
(Results go here.)

### Layer 3 — Architecture
(Results go here.)

### Layer 4 — Blast Radius
(Results go here.)

### Layer 5 — Gaps
(Results go here.)

## Generated Stubs
New ideas, gaps, or follow-up items discovered during this pipeline. Each becomes a candidate for a future pipeline.

1. (Stub goes here.)
