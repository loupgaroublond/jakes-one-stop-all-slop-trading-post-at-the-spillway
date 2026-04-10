# Gate: Breakdown

This gate describes how the **breakdown phase** of a pipeline works in this project. It takes a reviewed design and decomposes it into concrete, independently executable work items.

## Purpose

Breakdown produces a list of work items that collectively implement the design. Each work item is self-contained: a fresh agent (or a human) should be able to pick one up and implement it without needing to coordinate live with whoever is working on a different item.

## Inputs

- A pipeline document with its design section complete and approved
- The current spec modules (so breakdown knows what's new, what's changing, and what's stable)

## Outputs

A work breakdown section in the pipeline document containing:

1. **Work items**, each with:
   - A short title
   - Scope statement (what's included, what's not)
   - Acceptance criteria (concrete checklist)
   - Context references (which spec modules, ADRs, and existing code a worker needs to read)
   - Dependencies on other work items in the same pipeline
2. **Execution ordering** — partial order that says which items can run in parallel and which are sequential
3. **Verification plan** — which verification layers (1–6) apply to this pipeline, and why

## Completion Criteria

The following checks apply to every breakdown phase:

- [ ] Every work item has acceptance criteria that could be checked mechanically
- [ ] Every work item specifies its context sources (spec modules, ADRs, files)
- [ ] Dependencies between work items form a directed acyclic graph
- [ ] The verification plan explicitly lists which of the six layers apply and which don't (with justification)
- [ ] Work items are small enough to fit in a single agent session comfortably
- [ ] The union of all work items' scope covers the entire design

## Anti-patterns

- **Work items that reference "the design" as their only context** — if the design is the only thing the worker needs to read, the work item isn't broken down enough.
- **Hidden dependencies** — a work item that quietly depends on another but doesn't declare it. The ordering has to be explicit.
- **Overly fine breakdown** — splitting a single 50-line change into three work items just because you can. The unit of breakdown is "coherent work a single agent can complete," not "minimum diff size."

## Distilled Checks

_This section is managed by `/shit:distill`. Manual edits here are preserved across runs._

<!-- BEGIN DISTILLED -->
<!-- (no distilled checks yet) -->
<!-- END DISTILLED -->
