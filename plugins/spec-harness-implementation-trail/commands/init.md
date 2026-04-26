---
description: Scaffold the specs/ directory in the current project
allowed-tools: Bash(*schema-check.sh*)
---

# Initialize Spec Harness

Scaffold the `specs/` directory in the current project and populate it with starter content.

## Schema check

This command targets schema version **2**.

Active project state:

!`"${CLAUDE_PLUGIN_ROOT}/scripts/schema-check.sh"`

Decide based on the output above:
- `STATUS=UNINITIALIZED` — proceed with initialization (this is the expected case).
- `STATUS=OK` — `specs/` already exists at the latest schema. Tell the user the project is already initialized; do not overwrite anything. Print `ACTIVE` and `LATEST` for confirmation, then stop.
- `STATUS=LEGACY` or `STATUS=MISMATCH` — `specs/` exists at an older schema. Do not re-scaffold. Report `ACTIVE` vs `LATEST` and recommend `/shit:migrate` to bring the project up to date.

## Process

### 1. Confirm the working directory

Before creating anything, confirm you're in the project root. The `specs/` directory will be created here. The schema check above already verified that `specs/` does not exist (`STATUS=UNINITIALIZED`); if it does for any reason, stop.

### 2. Create the directory structure

Create this tree at the project root:

```
specs/
├── 0-transcripts/
├── 1-prd/
├── 2-spec/
│   └── compiled/
├── 3-adr/
├── 4-docs/
├── gates/
└── pipeline/
    ├── active/
    └── archive/
```

Use `mkdir -p` to create all directories in one pass.

### 3. Write the reification chain concept doc

Write `specs/reification.md` with the content from `${CLAUDE_PLUGIN_ROOT}/templates/reification.md`. This document explains the reification chain — the flow from transcripts to code — and is the conceptual entry point for anyone new to the project's process.

### 4. Write the spec index starter

Write `specs/2-spec/000-index.md` with the content from `${CLAUDE_PLUGIN_ROOT}/templates/spec-index.md`. This is the traceability matrix and module list. It starts empty; the user fills it in as they create spec modules.

### 5. Write the starter gate files

Copy each file from `${CLAUDE_PLUGIN_ROOT}/templates/gates/` into `specs/gates/`:

- `design.md` — describes how the design phase of a pipeline works
- `breakdown.md` — describes how breakdown works
- `verify-0-scope-check.md` — layer 0 verification (per-work-item scope review, runs before merge)
- `verify-1-traceability.md` — layer 1 verification (runs against the merged patch)
- `verify-2-invariants.md` — layer 2 verification
- `verify-3-architecture.md` — layer 3 verification
- `verify-4-blast-radius.md` — layer 4 verification
- `verify-5-gaps.md` — layer 5 verification

These are starters. The user edits them to match their project's specs. The `/shit:distill` command updates them when the specs change.

### 6. Write the schema marker

Copy `${CLAUDE_PLUGIN_ROOT}/templates/shit.toml` to `specs/.shit.toml`. This marks the project as following the latest schema (currently v2). `/shit:migrate` reads this file when the schema bumps in future plugin releases.

### 7. Write a minimal starter transcript process doc

Write `specs/0-transcripts/process.md` as an empty meta-document that tracks open questions and tangent notes. Use this template:

```markdown
# Conception Process Meta-Document

## Current State
_Not started yet. Run `/shit:conceive` to begin the first design interview._

## Open Questions
_None yet._

## Tangent Legend
_None yet._
```

### 8. Report what was created

Print a summary:

```
Created specs/ directory structure:
  specs/.shit.toml — schema version marker (v2)
  specs/0-transcripts/ — design interview transcripts
  specs/1-prd/ — product requirements
  specs/2-spec/ — formal specifications
  specs/3-adr/ — architecture decisions
  specs/4-docs/ — generated reports
  specs/gates/ — process specs (distilled checks)
  specs/pipeline/ — change management

Next steps:
  1. Run /shit:conceive to start your first design interview
     OR write an initial PRD at specs/1-prd/000-{slug}.md
     (e.g. for a project named "foo": specs/1-prd/000-foo.md)
  2. Review specs/gates/ — the starter files describe a generic process.
     Edit them to match your project, or run /shit:distill once you have specs.
  3. Read specs/reification.md for the full conceptual overview.
```

## Notes

- Do not create `.gitignore` entries — the plugin stays out of the adopter's VCS configuration.
- Do not create any files under `specs/4-docs/` — those are generated on demand by other commands.
- Do not populate any PRD, ADR, or spec modules — those are the user's content, not the plugin's.
