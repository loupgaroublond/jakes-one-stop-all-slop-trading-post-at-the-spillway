---
description: Display the pipeline dashboard
allowed-tools: Bash(*schema-check.sh*)
---

# Pipeline Dashboard

Generate and display the pipeline dashboard.

## Schema check

This command targets schema version **2**.

Active project state:

!`"${CLAUDE_PLUGIN_ROOT}/scripts/schema-check.sh"`

Decide based on the output above:
- `STATUS=OK` — proceed.
- `STATUS=MISMATCH` or `STATUS=LEGACY` — the project is on schema v$ACTIVE; this command targets v$LATEST. Recommend `/shit:migrate`. If the user wants to defer and the rest of this command does not depend on the changed layout, you may proceed in best-effort mode and warn about possibly stale results.
- `STATUS=UNINITIALIZED` — tell the user to run `/shit:init` first.

## What This Does

Parses YAML frontmatter from every pipeline document in `specs/pipeline/active/` and produces a categorized view by phase: design, breakdown, execution, verification, blocked, archived. Pipelines with `blocked-by` entries always go in the blocked bucket regardless of their phase.

## Steps

1. Run the dashboard script to parse all active pipeline docs:

   ```bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/pipeline/dashboard.sh --markdown
   ```

   The script writes the dashboard to `specs/pipeline/dashboard.md` and also prints it to stdout.

2. Read `specs/pipeline/dashboard.md` and display the full content to the user.

3. If there are pipelines that need attention, summarize them briefly:
   - How many are in design
   - How many are in breakdown
   - How many are in execution
   - How many are in verification
   - How many are blocked (and on what)

4. If asked to update the dashboard without showing it, just run the script silently.

## Pipeline Document Format

Pipeline documents in `specs/pipeline/active/` follow this format. The script parses the YAML frontmatter; the body is for human consumption.

```markdown
---
id: p0042
slug: auth-rework
title: "Authentication Rework"
phase: design
priority: 2
source: "REQ-AUTH-003"
blocked-by: []
created: 2026-04-09
updated: 2026-04-09
---

# p0042 — Authentication Rework

## Brief
One-paragraph summary of what this pipeline accomplishes.

## Status
Currently in design phase. Next: research existing auth code, propose new approach, get human approval.

## Stub
The original idea or need that prompted this pipeline.

## Design Log
Chronological record of research, decisions, and discussions during the design phase.

## Work Breakdown
(Filled in during the breakdown phase. Lists work items with scope, acceptance criteria, and context references.)

## Verification Results
(Filled in during the verification phase. Layer-by-layer findings.)

## Generated Stubs
(New ideas or gaps discovered during this pipeline. These become future pipelines.)
```

**Required frontmatter fields:**
- `id` — Pipeline ID, format `pNNNN` (e.g., `p0042`)
- `slug` — URL-safe short name
- `title` — Human-readable title
- `phase` — One of: `design`, `breakdown`, `execution`, `verification`, `archived`
- `priority` — Integer 0–4 (0 = critical, 4 = backlog)
- `created` — Date in `YYYY-MM-DD`
- `updated` — Date in `YYYY-MM-DD`

**Optional frontmatter fields:**
- `source` — Originating requirement ID(s) or stub reference
- `blocked-by` — Array of pipeline IDs that must complete first

## Notes

- The dashboard is read-only with respect to pipeline documents. It only parses; it never modifies.
- Pipelines that have completed move from `specs/pipeline/active/` to `specs/pipeline/archive/`. The script counts archived files but does not categorize them — once a pipeline is in archive/, it's done.
- This plugin's pipeline tracks *spec changes*, not agent assignments. If you want to associate work with specific agents or workers, that's the job of your orchestration harness (not this plugin).
