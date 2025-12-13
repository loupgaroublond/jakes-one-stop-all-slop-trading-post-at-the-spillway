---
description: Analyze unseen sessions and produce rest report
---

# Rest Analysis

You are running the Rest System - a session analysis workflow that reviews prior sessions to identify learnings and mistakes.

## Workflow

### 1. Archive and Fatigue Check

First, run the session start script to archive sessions and check fatigue:
```bash
~/.claude/self/session_start.sh
```

This shows the current fatigue level (unseen sessions/messages by project).

### 2. Identify Current Project

Determine which project to analyze based on current working directory:
- Extract project path from `pwd`
- Map to session directory pattern: `~/.claude/projects/{encoded-project-path}/`

When running from `~/.claude`, analyze only `.claude` sessions.

### 3. Discover Unseen Sessions

Find all session files for this project (both regular sessions and agent logs):
```bash
ls ~/.claude/projects/{project-path}/*.jsonl          # includes agent-*.jsonl
ls ~/.claude/session-archives/{project-path}/*.jsonl 2>/dev/null
```

**Discover peer sessions** (if configured):
1. Check for `.claude/project-peers.json` in the current project directory
2. For each configured peer (machine → remote-path):
   ```bash
   ls ~/.claude/session-archives/other-machines/{machine}/{remote-path}/*.jsonl
   ```
3. Include peer sessions in the work queue, tagged with their source machine

For each session, check if analyzed:
- Read metadata from `~/.claude/analysis/sessions/{session-id}/metadata.json`
- If `analyzed_through_message < total_messages`, session has unseen content
- If no metadata exists, session is entirely unseen

**Identify agent logs**: Files matching `agent-*.jsonl` are subagent sessions. They are analyzed alongside regular sessions but serialize differently (see below).

Build work queue of sessions to analyze (local + peer sessions).

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

**Pass to subagents:** Include `session_serial: "S3"` or `session_serial: "S3 A2"` when spawning rest-analyzer

### 5. Analyze Sessions

For each unseen session, spawn rest-analyzer subagent with:
- `session_file`: Path to JSONL
- `storage_path`: Analysis storage location (e.g., `~/.claude/analysis-preprod/`)
- `session_serial`: The S number (e.g., "S3")

Subagents assign T numbers (T1, T2...) to findings within their session.

**Small sessions** (< 100 messages): Read and analyze in single pass

**Large sessions**:
- Use keyword search first-pass to find regions of interest
- Extract and analyze targeted ranges
- If context fills, spawn continuation subagent

**Subagent output locations:**
```
{storage_path}/sessions/{session-id}/
├── metadata.json                        # Session metadata with S number
├── findings-{agent-id}-{timestamp}.json # Findings from this subagent
└── partial-{agent-id}-{timestamp}.json  # (if continuation needed)
```

Subagents include their agent ID in filenames for traceability.
Each subagent writes directly to storage BEFORE returning.

### 6. Generate Draft Report

Aggregate findings across all analyzed sessions into a draft report (without recommendations).

**Draft report format** (consolidated by domain):
```markdown
# Rest Analysis: {date} {time}

Analyzed sessions S{n}-S{m}, {total} messages.

## {Domain}

**{Finding Title}** (S{n}, S{m})
{Narrative about what happened, citing specific incidents with [M#start-end] references}

*{Brief inline hint if warranted, e.g., "may need CLAUDE.md reinforcement"}*

---

*{count} findings across {count} domains. Request drill-down on any item for full evidence.*
```

### 7. Assemble Recommendations

Spawn **recommendations-assembler** subagent with:
- `draft_report`: The draft report content (findings only)
- `storage_path`: Analysis storage path for drill-down access

The assembler will:
1. Extract inline hints from findings
2. Group suggestions by target (CLAUDE.md, scripts, etc.)
3. Drill down as needed to make suggestions concrete
4. Deduplicate and merge related suggestions
5. Return a Recommendations section

**Append the Recommendations section** to the draft report.

### 8. Save Final Report

Save complete report (findings + recommendations) to:
`~/.claude/analysis/reports/rest-{YYYY-MM-DD}-{HH-MM}.md` (24-hour local time)

### 9. Update Metadata

For each analyzed session, update metadata:
- Set `analyzed_through_message` to current total
- Add entry to `analysis_runs` array
- Set `status` to `complete`

### 10. Present and Await Review

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

**Use cases:**
1. **Test isolation**: Run test analyses without affecting production state
2. **Re-analysis**: Re-analyze past sessions with evolved methodology while preserving old analysis
3. **Experiments**: Try different analysis approaches side-by-side

Each storage location has independent:
- Session metadata and serial numbers
- Findings files
- Reports

**Shorthand:** `--test` is equivalent to `--storage test`

### Methodology Section

Always include a methodology section at the end of reports:

```markdown
## Analysis Methodology

### Storage
Location: `~/.claude/analysis/` (or alternate location if specified)

### Session Selection
- Total sessions found: {n}
- Sessions analyzed: {n}
- Sessions skipped: {n} (reason if any)

### Session Processing Strategy
- {How each session was handled: full read vs keyword search}
- {Regions of interest identified for large sessions}

### Search Patterns Used
- Error indicators: `error|failed|exception`
- Learning moments: `I see|understood|learned`
- User corrections: `no,|actually|wrong`
- Domain-specific: `{any additional patterns used}`

### Decision Points
- {Key choices made during analysis and why}

### Findings Distribution
- Learning: {count}
- Mistakes: {count}
```

This metacognition helps understand the analysis approach and improve future iterations.

To clean up non-production storage:
```bash
rm -rf ~/.claude/analysis-<name>/
```

## EPUB Generation

For large analyses or offline reading, generate an EPUB:

```bash
~/.claude/rest-plugin/scripts/rest_build_epub.sh [storage-path]
```

**Automatic trigger:** If `--epub` is passed OR analysis exceeds 1000 messages, generate EPUB after report.

**Manual generation:** Run the script anytime to package existing reports.

**Output:** `{storage}/reports/REST-ANALYSIS.epub` - opens automatically in Books.app.

The EPUB includes:
- All rest-*.md reports in chronological order
- Table of contents by date
- Metadata (date range, report count)

## Drill-Down

Use `/drilldown` command for detailed evidence on any finding.

```
/drilldown M1              # Evidence for finding M1
/drilldown S47             # Full session S47 detail
/drilldown S47 M#120-135   # Specific message range
```

### Breadcrumbs

Every finding MUST include `drill_down_keywords` - specific search terms for `/drilldown`:

**BAD** (vague):
> "Larger session - would benefit from keyword search first-pass."

**GOOD** (actionable):
> "Larger session (111 messages). Drill-down: `bd ready`, `bd daemon`, `socket`, `startup time`."

## Constraints

- Only analyze current project's sessions
- Keep reports readable in < 30 minutes (query user for large backlogs)
- Be specific about incidents, not generic
- Suggestions light, at end of sections
- No appendices unless truly needed for indexing
