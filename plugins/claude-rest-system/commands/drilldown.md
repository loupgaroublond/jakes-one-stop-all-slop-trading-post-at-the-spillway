---
description: Drill down into rest analysis findings for detailed evidence
---

# Drill-Down Analysis

Interactive, multi-tier deep-dive into findings from `/rest` analysis.

## Usage

```
/drilldown <target>
```

**Targets:**
- Finding ID: `/drilldown S3 T1` or `/drilldown T2` (uses current session)
- Session serial: `/drilldown S47`
- Message range: `/drilldown S47 M#120-135`
- Free-form: `/drilldown path quoting issues`

## User Input

$ARGUMENTS

## Tier Progression

| Tier | Scope | Example |
|------|-------|---------|
| 0 | Consolidated report | (initial `/rest` output) |
| 1 | Finding detail | `/drilldown S3 T1` |
| 2 | Single session detail | `/drilldown S47` |
| 3 | Incident context | `/drilldown S47 M#180` |
| N | Further detail | Any follow-up |

## Workflow

### 1. Parse Target

Extract from user input:
- Finding ID pattern: `S\d+ T\d+` (S3 T1) or just `T\d+` (T1, uses context)
- Session pattern: `S\d+` (S47, S123)
- Message range: `M#\d+-\d+` or `M#\d+`
- Keywords: remaining text

### 2. Locate Source Findings

Find the most recent analysis to drill into:

```bash
# Find latest quick analysis files
ls -t ~/.claude/analysis/sessions/*/quick-*.json | head -5

# Or find existing drill-downs to continue from
ls -t ~/.claude/analysis/sessions/*/drill-*.json | head -5
```

### 3. Search for Target

**If finding ID (S3 T1):**
```bash
# Search all quick-*.json for the finding ID
grep -l '"id": "T1"' ~/.claude/analysis/sessions/*/quick-*.json
# Then filter by session_serial: "S3"
```

**If session serial (S47):**
```bash
# Find session with that serial number
grep -l '"serial_number": 47' ~/.claude/analysis/sessions/*/metadata.json
```

**If keywords:**
```bash
# Search findings for matching text
grep -l "path quoting" ~/.claude/analysis/sessions/*/*.json
```

### 4. Extract Evidence

For each matching finding, get the actual session content:

```bash
# Get evidence range from finding
jq '.findings[] | select(.id == "T1") | .evidence_range' quick-*.json

# Extract that range from session file
~/.claude/rest-plugin/scripts/rest_session_extract.sh <session_file> <start> <end>
```

### 5. Present Detailed Evidence

Format with actual content, not summaries:

```markdown
## Drill-Down: S47 T1 - Path Quoting

### S47 [M#50-55]

**User request:**
> Copy the config file to my documents

**Claude's action:**
```bash
cp $SOURCE $DEST
```

**Result:**
```
cp: target 'Documents' is not a directory
```

**Context:** Path was `/Users/foo/My Documents` - space caused word splitting.

---

### S49 [M#128-133]

[Similar detailed breakdown...]
```

### 6. Store Drill-Down

Save for potential further drill-down:

```bash
# Location: ~/.claude/analysis/sessions/{session-id}/drill-{timestamp}.json
```

**Schema:**
```json
{
  "timestamp": "2025-01-15T11:00:00Z",
  "tier": 1,
  "parent": "quick-2025-01-15T10-30-00.json",
  "focus": "M1",
  "query": "path quoting",
  "sessions_examined": ["abc123", "def456"],
  "detailed_evidence": [
    {
      "session_id": "abc123",
      "serial": "S47",
      "range": [50, 55],
      "context": "User asked to copy file, Claude used unquoted path",
      "actual_content": "[extracted JSONL content]",
      "outcome": "cp failed on space in path"
    }
  ]
}
```

### 7. Offer Further Drill-Down

After presenting, suggest next steps:

```markdown
---

*Drill-down complete. Further options:*
- `/drilldown S47` - Full session S47 chronology
- `/drilldown S47 M#52` - What Claude read before M#52
- `/drilldown S49 M#128-133` - Details on S49 incident
```

## Chaining Example

```
/rest                           → Tier 0: "Path quoting issues (S47, S49, S51)"
/drilldown M1                   → Tier 1: Evidence from all 3 sessions
/drilldown S47                  → Tier 2: Full S47 chronology
/drilldown S47 M#52             → Tier 3: What was Claude copying, what failed
/drilldown S47 M#40-51          → Tier 4: What Claude read before the copy
```

Each tier's `parent` field links back, creating a traceable chain.

## Storage Location

Uses same storage as `/rest`:
- Default: `~/.claude/analysis/`
- With `--storage test`: `~/.claude/analysis-test/`

Inherits storage location from the findings being drilled into.
