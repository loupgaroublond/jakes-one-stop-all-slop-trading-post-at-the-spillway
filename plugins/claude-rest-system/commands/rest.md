---
description: Analyze unseen sessions and produce rest report
---

# Rest Analysis

You are running the Rest System - a session analysis workflow that reviews prior sessions to identify learnings and mistakes.

## Workflow Overview

```
1. Fatigue Check (writes inventory JSON)
   └─ ~/.claude/analysis/fatigue_inventory.json

2. Session Classifier (haiku, fast)
   └─ Group A (rest-analysis) → META path
   └─ Group B (regular work) → INLINE or BEEFY path

3. User Pace Confirmation
   └─ Concurrent analyzers, beefy batch pace

4. Analyze Sessions in Parallel:
   ├─ Group A → meta-analyzer (token-efficient)
   ├─ Group B inline (≤10 subagents) → inline-analyzer
   └─ Group B beefy (>10 subagents):
       ├─ beefy-analyzer (main session)
       ├─ beefy-subagent-analyzer × N (batches of 5)
       └─ beefy-reporter (assemble)

5. Pattern Identification → Pattern Consolidators
6. Recommendations Assembler → Final Report + EPUB
```

## Workflow

### 1. Archive and Fatigue Check

First, run the session start script to archive sessions and check fatigue:
```bash
~/.claude/self/session_start.sh
```

This shows the current fatigue level (unseen sessions/messages by project) and writes the session inventory to:
- `~/.claude/analysis/fatigue_inventory.json`

The inventory includes main sessions with their subagents:
```json
[
  {
    "file": "/path/to/session.jsonl",
    "project": "project-name",
    "unseen_messages": 42,
    "subagents": [
      {"file": "/path/to/agent-abc.jsonl", "messages": 10, "unseen_messages": 10}
    ]
  }
]
```

### 2. Identify Current Project

Determine which project to analyze based on current working directory:
- Extract project path from `pwd`
- Map to session directory pattern: `~/.claude/projects/{encoded-project-path}/`

When running from `~/.claude`, analyze only `.claude` sessions.

### 2.5. Initialize Storage

Determine storage path based on `--storage` flag:
- Default: `~/.claude/analysis/`
- With `--storage <name>`: `~/.claude/analysis-<name>/`

**If storage exists and versioning/stashing requested:**
1. Find highest existing version:
   ```bash
   ls -d ~/.claude/analysis-<name>.v* 2>/dev/null | sed 's/.*\.v//' | sort -n | tail -1
   ```
2. Increment to next version number
3. Move existing storage:
   ```bash
   mv ~/.claude/analysis-<name> ~/.claude/analysis-<name>.vN
   ```

**Create fresh storage structure:**
```bash
rm -rf ~/.claude/analysis-<name>/sessions ~/.claude/analysis-<name>/reports ~/.claude/analysis-<name>/inventory
mkdir -p ~/.claude/analysis-<name>/sessions
mkdir -p ~/.claude/analysis-<name>/reports/session-reports
mkdir -p ~/.claude/analysis-<name>/reports/pattern-reports
mkdir -p ~/.claude/analysis-<name>/inventory
```

**Verify pristine state before proceeding:**
- `sessions/` must be empty
- `reports/` must be empty (no leftover files from prior runs)
- `inventory/` must be empty

This ensures each analysis run starts clean and reports don't accumulate across runs.

### 3. Discover Unseen Sessions (with deduplication)

Sessions can exist in multiple locations (active, archived, peer copies). Deduplicate by session ID (UUID) with precedence order ensuring most current version is used.

**Discovery order (lowest to highest precedence):**

1. **Peer sessions** (if configured):
   Check for `.claude/project-peers.json` in the current project directory:
   ```bash
   cat .claude/project-peers.json 2>/dev/null
   ```

   If the file exists, it maps machine names to arrays of remote project paths:
   ```json
   {
     "work": ["-Users-ynemoy-Documents-grug-brained-employee"],
     "home": ["-Users-john-Projects-myproject"]
   }
   ```

   For each machine and each remote-path in that machine's array, scan for sessions:
   ```bash
   # Example for machine "work" with remote-path "-Users-ynemoy-Documents-grug-brained-employee"
   # Lowest precedence - remote copies may be stale
   for file in ~/.claude/session-archives/other-machines/work/-Users-ynemoy-Documents-grug-brained-employee/**/*.jsonl(N); do
     session_id=$(basename "$file" .jsonl)
     sessions["$session_id"]="$file"
   done
   ```

   **IMPORTANT:** You MUST read project-peers.json and iterate over ALL machines and ALL paths. Do not skip this step.

2. **Archived sessions**:
   ```bash
   # Medium precedence - archived copies
   for file in ~/.claude/session-archives/{project-path}/**/*.jsonl(N); do
     session_id=$(basename "$file" .jsonl)
     sessions["$session_id"]="$file"
   done
   ```

3. **Active project sessions**:
   ```bash
   # Highest precedence - current active sessions (overwrites archived)
   for file in ~/.claude/projects/{project-path}/**/*.jsonl(N); do
     session_id=$(basename "$file" .jsonl)
     sessions["$session_id"]="$file"
   done
   ```

**Result:** `sessions` array contains exactly one path per unique session ID, preferring most current copy.

**Identify agent logs**: Files matching `agent-*.jsonl` are subagent sessions. They are analyzed alongside regular sessions but serialize differently (see below).

For each unique session, check if analyzed:
- Read metadata from `~/.claude/analysis/sessions/{session-id}/metadata.json`
- If `analyzed_through_message < total_messages`, session has unseen content
- If no metadata exists, session is entirely unseen

Build work queue of sessions to analyze.

### 3.5. Classify Sessions

Read the inventory from `~/.claude/analysis/fatigue_inventory.json` and spawn `session-classifier` agent (runs on haiku for speed):

**Input:** The session inventory JSON
**Output:** Classified session list with group + path assignments

```json
{
  "classified": [
    {"file": "...", "group": "A", "path": "META"},
    {"file": "...", "group": "B", "path": "INLINE", "subagent_count": 5},
    {"file": "...", "group": "B", "path": "BEEFY", "subagent_count": 25}
  ],
  "summary": {
    "group_a_count": 1,
    "group_b_inline_count": 3,
    "group_b_beefy_count": 1
  }
}
```

**Classification criteria:**
- **Group A** (rest-analysis sessions): Sessions analyzing other sessions (rest-analyzer, meta-analyzer, session-analysis)
- **Group B** (regular work): Everything else
  - **INLINE**: ≤10 subagents (analyze main + subagents together)
  - **BEEFY**: >10 subagents (staged analysis with user pacing)

**Parallel streams:** If >20 unseen sessions, classifier breaks them into parallel streams for efficient processing.

### 3.6. User Pace Confirmation

Before dispatching analyzers, confirm pace settings with the user:

```
=== Analysis Pace Settings ===

Sessions to analyze: {count}
  - Group A (meta): {count}
  - Group B inline: {count}
  - Group B beefy: {count}

Recommended defaults:
  - Concurrent analyzers: 3
  - Beefy batch size: 5 subagents
  - Confirm between batches: No

Proceed with defaults? Or specify:
  - Different concurrency (1-5)
  - Different batch size (3-10)
  - Pause between beefy batches
```

**Always get confirmation before proceeding.** User may adjust based on:
- Available context window (5-hour token budget)
- Desire for more/less parallelism
- Need to review between batches

### 4. Assign Serial Numbers (BEFORE dispatching subagents)

The orchestrator assigns ALL serial numbers before analysis begins:

**Session serials (S1, S2, ...) for regular sessions:**
1. Sort all regular sessions (not agent-*.jsonl) by `first_message_timestamp`
2. Find highest existing S number in storage metadata files
3. Assign next S number to each unassigned session
4. Write S number to each session's `metadata.json`

**Agent serials (A1, A2, ...) within parent sessions:**
1. For each regular session, find its agent logs (agent-*.jsonl files)
2. Link agents to parent by examining session content or timestamps
3. Sort agents by `first_message_timestamp` within parent
4. Assign A1, A2... within that parent session
5. Write metadata: `is_agent: true`, `parent_session_id`, `agent_number`
6. Reference format: S32 A2 (agent 2 of session 32)

**Pass to subagents:** Include `session_serial: "S3"` or `session_serial: "S3 A2"` when spawning analyzers (meta-analyzer, inline-analyzer, or beefy-*)

### 5. Analyze Sessions (DISPATCHING BY GROUP)

Dispatch sessions to appropriate analyzers based on classification (all run in parallel at user-confirmed pace):

**Group A (rest-analysis sessions) → meta-analyzer:**
```
Input:
- session_file: Path to JSONL
- subagent_files: List of subagent paths
- storage_path: Analysis storage location
- session_serial: The S number
```
Meta-analyzer is token-efficient, reads subagents inline, focuses on patterns.

**Group B INLINE (≤10 subagents) → inline-analyzer:**
```
Input:
- session_file: Path to JSONL
- subagent_files: List of subagent paths (≤10)
- storage_path: Analysis storage location
- session_serial: The S number
```
Inline-analyzer processes main session + all subagents in single pass.

**Group B BEEFY (>10 subagents) → beefy pipeline:**
```
Stage 1: beefy-analyzer
- Analyzes main session only
- Produces intermediate report

Stage 2: beefy-subagent-analyzer (× N batches)
- Processes 5 subagents per batch
- User-paced between batches (if configured)

Stage 3: beefy-reporter
- Assembles intermediate + all batch reports
- Produces final combined report
```

**The only difference between groups is which analyzer is called.** All run in parallel at user-confirmed concurrency.

**CRITICAL: All analyzers produce NARRATIVE MARKDOWN REPORTS, not JSON.**

**Session Report Standards:**

Each session analyzer writes a markdown report to:
`{storage_path}/reports/session-reports/{session-serial}-report.md`

**Required report structure:**

```markdown
# Session {serial}: {Brief Title}

**Session ID:** {id}
**Messages:** {count}
**Source:** {local|icloud|peer:machine}
**Date:** {timestamp range}

## Summary

{2-3 paragraph narrative overview of what happened in this session. What was the user trying to accomplish? What were the major activities? How did it go?}

## Findings

### {Finding Title} (T1)

{Full narrative description of what happened. Include:
- The context leading up to the event
- What actually occurred
- How it was resolved or what the outcome was
- Why this matters for future sessions}

**Session excerpt (M#{start}-{end}):**

> User: {actual message content}
>
> Assistant: {actual response content}
>
> User: {follow-up showing correction or resolution}

**Keywords:** `keyword1`, `keyword2`, `keyword3`

---

### {Next Finding Title} (T2)

{Continue with same narrative depth...}

## Session Characteristics

- **Complexity:** {simple|moderate|complex}
- **Dominant themes:** {list}
- **Error density:** {low|medium|high}
- **Learning density:** {low|medium|high}
- **User corrections:** {count}

## Potential Pattern Connections

{Note any patterns that might connect to other sessions:
- "AMI naming confusion similar to other infrastructure sessions"
- "Google Docs index issues likely recurring pattern"
- "Same kubectl namespace assumption error seen elsewhere"}
```

**Findings Quality Bar:**

- Sessions > 500 messages: Expect 2-3 findings minimum, use keyword-search-first
- Sessions 100-500 messages: Expect 1-2 findings minimum
- Sessions < 100 messages: 0-1 findings acceptable
- If no findings after thorough search: Document as "Reviewed - routine work" with brief summary
- **Never** write "deferred due to token constraints" - use continuation protocol instead

**Large Session Strategy:**

For sessions > 500 messages:
1. Run keyword search first-pass to identify regions of interest
2. Extract and deeply analyze targeted ranges
3. **If context fills before complete: Return `continuation_needed: true` with progress marker**
4. Orchestrator will spawn continuation subagent

**Continuation Protocol:**
```markdown
## Analysis Status

**Status:** Partial (continuation needed)
**Analyzed through:** M#{last_message}
**Remaining:** M#{next_message}-{end}
**Findings so far:** {count}
```

### 5.5. Verify Coverage (for analyses with 10+ sessions)

**When analyzing more than 10 sessions**, verify comprehensive coverage before proceeding to pattern identification:

**Coverage verification steps:**

1. **Count substantive sessions** (>= 20 messages) from serial_map.jsonl:
   ```bash
   jq -r 'select(.messages >= 20) | .serial' {storage}/inventory/serial_map.jsonl | wc -l
   ```

2. **Count actual reports generated:**
   ```bash
   ls {storage}/reports/session-reports/S*-report.md | wc -l
   ```

3. **Identify gaps** - sessions with >= 20 messages but no report:
   ```bash
   for serial in $(seq 1 {max_serial}); do
     if [[ ! -f {storage}/reports/session-reports/S${serial}-report.md ]]; then
       jq -r "select(.serial == \"S$serial\") | select(.messages >= 20) | \"\(.serial): \(.messages) msgs\"" \
         {storage}/inventory/serial_map.jsonl
     fi
   done
   ```

4. **Display coverage summary:**
   ```
   === Session Coverage ===
   Sessions < 20 messages: {n} (skipped as too small)
   Sessions >= 20 messages: {n}
     - Analyzed: {n}
     - Missing: {n}
   Coverage: {percent}%
   ```

5. **If gaps exist**, dispatch additional analyzers for missing substantive sessions before proceeding.

**Coverage threshold:** Proceed to pattern identification only when >= 95% of substantive sessions (>= 20 messages) have reports. Any session with >= 100 messages MUST have a report.

**Small session handling:** Sessions with < 20 messages are intentionally skipped - they rarely contain significant findings worth the analysis overhead.

### 6. Identify Common Patterns

After all session reports are complete, the orchestrator:

1. Read all session reports from `{storage}/reports/session-reports/`
2. Extract "Potential Pattern Connections" sections
3. Identify patterns mentioned across multiple sessions
4. Group related findings by theme

**Pattern identification criteria:**
- Same issue mentioned in 2+ session reports
- Similar keywords appearing across sessions
- Related domain (infrastructure, MCP, Google Docs, etc.)
- Connected error types or user correction patterns

**Build pattern work queue:**
```
Pattern: "AMI naming confusion"
  - S35: T2 (zkube 1.0 vs 2.0 AMI storage)
  - S35: T4 (current vs target AMI confusion)
  - S173: T1 (AMI report pipeline issues)
  Sessions to consolidate: S35-report.md, S173-report.md

Pattern: "Google Docs index shifting"
  - S66: T1 (index refresh after edits)
  - S126: T2 (insertion at wrong location)
  Sessions to consolidate: S66-report.md, S126-report.md
```

### 7. Consolidate Patterns (PARALLEL)

For each identified pattern, spawn a **pattern-consolidator** subagent:

**Input:**
- `pattern_name`: e.g., "AMI naming confusion"
- `session_reports`: List of relevant session report paths
- `finding_references`: Which findings (T numbers) relate to this pattern
- `storage_path`: Analysis storage path

**Pattern consolidator task:**
1. Read the relevant session reports (full narrative, not summaries)
2. Extract the specific findings related to this pattern
3. Synthesize a consolidated pattern report that:
   - Tells the complete story across all sessions
   - Shows how the pattern manifested differently in each context
   - Includes representative excerpts from multiple sessions
   - Identifies root causes and contributing factors
   - Suggests concrete mitigations

**Pattern Report Standards:**

Write to: `{storage_path}/reports/pattern-reports/{pattern-slug}-consolidated.md`

**Maximum length:** Up to 2x the average length of the contributing session findings.

```markdown
# Pattern: {Pattern Name}

**Sessions involved:** {S35, S66, S173}
**Total occurrences:** {count}
**Severity:** {Critical|High|Medium|Low}

## Pattern Overview

{Comprehensive narrative explaining this pattern. What is it? Why does it happen? How does it manifest?}

## Manifestations

### In Session S35: {Context}

{Narrative of how this pattern appeared in S35, with excerpts}

> User: {excerpt}
> Assistant: {excerpt}

### In Session S66: {Context}

{Narrative of how this pattern appeared in S66, with excerpts}

### In Session S173: {Context}

{Narrative of how this pattern appeared in S173, with excerpts}

## Root Cause Analysis

{Why does this pattern keep occurring? What are the underlying causes?}

## Impact Assessment

{What are the consequences when this pattern occurs? Time lost? User frustration? Incorrect outputs?}

## Recommended Mitigations

{Specific, actionable suggestions to prevent this pattern:
- Documentation additions
- Workflow changes
- Tool improvements
- Prompt modifications}

## Keywords for Future Detection

`keyword1`, `keyword2`, `keyword3`
```

**Spawn pattern consolidators in parallel** - they read different session reports so no conflicts.

### 8. Assemble Recommendations

After pattern reports are complete, spawn **recommendations-assembler** subagent with:
- `session_reports_dir`: Path to session reports
- `pattern_reports_dir`: Path to pattern reports
- `storage_path`: Analysis storage path

The assembler will:
1. Read all session reports and pattern reports (narrative content)
2. Extract mitigation suggestions from pattern reports
3. Group recommendations by target (CLAUDE.md, AGENTS.md, scripts, etc.)
4. Prioritize by severity and frequency
5. Write concrete, copy-paste-ready recommendations
6. Deduplicate and merge related suggestions

**Recommendations output:**
Write to: `{storage_path}/reports/recommendations-{timestamp}.md`

### 9. Generate Final Report

The orchestrator assembles the final report with **no duplication**:

**Hierarchy principle:** Pattern reports "promote" findings out of session reports. If a finding was consolidated into a pattern, it does NOT appear separately in the final report.

**Content organization:**

1. **Patterns** (consolidated cross-session findings) - Full narrative in final report
2. **Standalone findings** (single-session, not part of any pattern) - Included in final report
3. **Consolidated findings** (part of a pattern) - NOT in final report, available via drill-down to session reports

**Example:**
- S35 T2 (zkube AMI storage) → consolidated into "AMI Confusion" pattern → NOT in final report
- S35 T4 (current vs target AMI) → consolidated into "AMI Confusion" pattern → NOT in final report
- S66 T3 (MCP tool limitations) → standalone, no pattern → IN final report
- "AMI Confusion" pattern report → IN final report (covers S35 T2, T4, S173 T1)

**Structure:**
```markdown
# Rest Analysis Report: {date}

## Executive Summary
{Sessions analyzed, patterns found, standalone findings, key recommendations}

## Cross-Session Patterns

{Full pattern reports - these are the promoted/consolidated findings}

### Pattern: AMI Naming Confusion
{Full narrative from pattern-reports/ami-confusion-consolidated.md}
Sessions: S35, S173 | Findings consolidated: S35-T2, S35-T4, S173-T1

### Pattern: Google Docs Index Shifting
{Full narrative from pattern-reports/google-docs-index-consolidated.md}
Sessions: S66, S126 | Findings consolidated: S66-T1, S126-T2

## Standalone Findings

{Findings that appeared in only one session and weren't part of any pattern}

### MCP Tool Wrapper Limitations (S66-T3)
{Narrative from session report, not consolidated into a pattern}

### Kubernetes Namespace Confusion (S113-T1)
{Narrative from session report, not consolidated into a pattern}

## Recommendations

{Full recommendations section}

## Methodology

{How the analysis was conducted}

## Drill-Down Reference

Session reports available in appendix for detailed evidence:
- S35: Full report with T1-T4 (T2, T4 consolidated into AMI pattern)
- S66: Full report with T1-T3 (T1 consolidated into Google Docs pattern)
- ...
```

**Save to:** `{storage}/reports/rest-{YYYY-MM-DD}-{HH-MM}.md`

### 10. EPUB Generation and Verification

Before generating EPUB, verify all expected content is present:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rest_build_epub.sh [storage-path]
```

**Pre-flight checks (performed by script):**
- [ ] At least one `rest-*.md` final report exists
- [ ] Recommendations file exists if patterns were found
- [ ] All referenced session reports exist
- [ ] All referenced pattern reports exist
- [ ] Total word count exceeds minimum threshold

**EPUB includes (in order):**
1. Book info and table of contents
2. Final report (`rest-*.md`)
3. Recommendations (`recommendations-*.md`)
4. Pattern reports (`pattern-reports/*.md`)
5. Session reports (`session-reports/*.md`) - as appendix

### 11. Update Metadata

For each analyzed session, update metadata:
- Set `analyzed_through_message` to current total
- Add entry to `analysis_runs` array
- Set `status` to `complete`

### 12. Present and Await Review

Display the report and wait for user response. User may:
- Request drill-down on specific findings
- Ask questions about patterns
- Instruct changes (direct edits or beads issues)

## User Instructions

Follow these instructions over defaults when provided:

$ARGUMENTS

## Storage Locations

By default, analysis data is stored in `~/.claude/analysis/`.

Use `--storage <name>` to use an alternate storage location:
- `--storage test` → `~/.claude/analysis-test/`
- `--storage v2` → `~/.claude/analysis-v2/`
- `--storage <name>` → `~/.claude/analysis-<name>/`

**Directory structure:**
```
~/.claude/analysis-{name}/
├── inventory/
│   ├── all_sessions.txt
│   └── serial_map.jsonl
├── sessions/
│   └── {session-id}/
│       └── metadata.json
└── reports/
    ├── session-reports/
    │   ├── S1-report.md
    │   ├── S2-report.md
    │   └── ...
    ├── pattern-reports/
    │   ├── ami-confusion-consolidated.md
    │   ├── google-docs-index-consolidated.md
    │   └── ...
    ├── recommendations-{timestamp}.md
    ├── rest-{timestamp}.md
    └── REST-ANALYSIS.epub
```

**Use cases:**
1. **Test isolation**: Run test analyses without affecting production state
2. **Re-analysis**: Re-analyze past sessions with evolved methodology while preserving old analysis
3. **Experiments**: Try different analysis approaches side-by-side

**Shorthand:** `--test` is equivalent to `--storage test`

### Methodology Section

Always include a methodology section at the end of reports:

```markdown
## Analysis Methodology

### Storage
Location: `~/.claude/analysis/` (or alternate location if specified)

### Session Selection
- Total sessions in inventory: {n}
- Sessions < 20 messages: {n} (skipped as too small)
- Substantive sessions (>= 20 msgs): {n}
  - Analyzed: {n}
  - Missing: {n}
- Coverage: {percent}%

### Session Processing
- Small sessions (< 100 msgs): Full read, single pass
- Medium sessions (100-500 msgs): Full read with targeted extraction
- Large sessions (> 500 msgs): Keyword-search-first, then deep dive on regions of interest
- Massive sessions (> 1000 msgs): Dedicated analyzer with continuation protocol

### Pattern Consolidation
- Patterns identified: {n}
- Pattern consolidators spawned: {n}
- Cross-session themes: {list}

### Findings Distribution
- Total session findings: {count}
- Total pattern reports: {count}
- Recommendations generated: {count}
```

To clean up non-production storage:
```bash
rm -rf ~/.claude/analysis-<name>/
```

## EPUB Generation

For large analyses or offline reading, generate an EPUB:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rest_build_epub.sh [storage-path]
```

**Automatic trigger:** If `--epub` is passed OR analysis exceeds 1000 messages, generate EPUB after report.

**Manual generation:** Run the script anytime to package existing reports.

**Output:** `{storage}/reports/REST-ANALYSIS.epub` - opens automatically in Books.app.

The EPUB includes:
- Final rest analysis report
- Recommendations
- Pattern consolidation reports
- Session reports (as appendix)
- Table of contents for navigation

## Drill-Down

Use `/drilldown` command for detailed evidence on any finding.

```
/drilldown T1              # Evidence for finding T1
/drilldown S47             # Full session S47 detail
/drilldown S47 M#120-135   # Specific message range
/drilldown pattern:ami     # Pattern report for AMI issues
```

### Breadcrumbs

Every finding MUST include actionable drill-down keywords:

**BAD** (vague):
> "Larger session - would benefit from keyword search first-pass."

**GOOD** (actionable):
> "Larger session (111 messages). Keywords: `bd ready`, `bd daemon`, `socket`, `startup time`."

## Quality Gates

Before finalizing analysis:

- [ ] **Coverage check passed** (>= 95% of sessions with >= 20 messages have reports)
- [ ] **No gaps in large sessions** (all sessions >= 100 messages have reports)
- [ ] Findings-per-session ratio > 0.4 (excluding tiny sessions)
- [ ] All sessions > 500 messages have dedicated analysis (not "sampled")
- [ ] Large sessions use continuation protocol, not "deferred"
- [ ] Pattern reports exist for themes appearing in 2+ sessions
- [ ] Recommendations reference specific findings
- [ ] EPUB pre-flight checks pass

## Constraints

- Only analyze current project's sessions
- Keep reports readable in < 30 minutes (query user for large backlogs)
- Be specific about incidents with actual excerpts, not generic summaries
- Never produce JSON findings - always narrative markdown
- Never skip large sessions - use continuation protocol
- Include session excerpts showing actual conversation content
