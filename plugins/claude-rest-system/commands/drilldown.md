---
description: Drill down into rest analysis findings for detailed evidence
---

# Drill-Down Analysis

Interactive, multi-tier deep-dive into findings from `/rest` analysis.

## Usage

```
/drilldown <target> [--run <timestamp>]
```

**Targets:**
- Finding ID: `/drilldown S3 T1` or `/drilldown T2` (uses current session)
- Session serial: `/drilldown S47`
- Message range: `/drilldown S47 M#120-135`
- Free-form: `/drilldown path quoting issues`

**Options:**
- `--run <timestamp>`: Drill into a specific analysis run (e.g., `--run 2025-12-30-14-30`)
- Without `--run`: Uses the most recent analysis run for the current project

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

### 2. Determine Project and Run

First, identify the current project and analysis run:

```bash
# Derive project slug from current working directory
PROJECT_SLUG=$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')

# Find the latest run (or use --run parameter)
if [[ -n "$RUN_TIMESTAMP" ]]; then
    RUN_REPORTS_DIR="~/.claude/analysis/reports/${PROJECT_SLUG}/${RUN_TIMESTAMP}"
else
    # Default to most recent run
    LATEST_RUN=$(ls -1 "~/.claude/analysis/reports/${PROJECT_SLUG}" 2>/dev/null | sort -r | head -1)
    RUN_REPORTS_DIR="~/.claude/analysis/reports/${PROJECT_SLUG}/${LATEST_RUN}"
fi

echo "Drilling into: $RUN_REPORTS_DIR"
```

### 3. Locate Source Reports

Find session and pattern reports in the run directory:

```bash
# List session reports
ls "$RUN_REPORTS_DIR/session-reports/"*.md

# List pattern reports
ls "$RUN_REPORTS_DIR/pattern-reports/"*.md

# Find existing drill-downs (stored in sessions/)
ls -t ~/.claude/analysis/sessions/*/drill-*.json | head -5
```

### 4. Search for Target

**If finding ID (S3 T1):**
```bash
# Look in session report for the finding
grep -l "T1" "$RUN_REPORTS_DIR/session-reports/S3-report.md"
```

**If session serial (S47):**
```bash
# Read the session report directly
cat "$RUN_REPORTS_DIR/session-reports/S47-report.md"
```

**If pattern name:**
```bash
# Look in pattern reports
grep -l "path quoting" "$RUN_REPORTS_DIR/pattern-reports/"*.md
```

**If keywords:**
```bash
# Search all reports in the run
grep -r "path quoting" "$RUN_REPORTS_DIR/"
```

### 5. Extract Evidence

For each matching finding, get the actual session content:

```bash
# Get evidence range from finding
jq '.findings[] | select(.id == "T1") | .evidence_range' quick-*.json

# Extract that range from session file
${CLAUDE_PLUGIN_ROOT}/scripts/rest_session_extract.sh <session_file> <start> <end>
```

### 6. Present Detailed Evidence

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

**For process findings**, present the step-by-step walkthrough:

```markdown
## Drill-Down: S7 T5 - EKS Deployment Process

**Steps:** 4 | **Corrections:** 1

### Step 1: Create cluster config [M#122-135]
> User: Create a YAML config with the node group specs...
> Assistant: [creates config]

### Step 2: Apply with eksctl [M#140-152]
> User: Now apply it with eksctl create cluster
> Assistant: [runs command]

### Step 3: Verify nodes [M#155-165]
> User: Check the nodes are up
> Assistant: [runs kubectl get nodes]

### Step 4: Update kubeconfig [M#170-185] ⚠️ Correction
> User: Update the kubeconfig
> Assistant: [uses wrong region]
> User: No, use --region us-east-1
> Assistant: [corrects and runs successfully]
```

### 7. Store Drill-Down

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

### 8. Offer Further Drill-Down

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

Uses same storage structure as `/rest`:
- Default: `~/.claude/analysis/`
- With `--storage test`: `~/.claude/analysis-test/`

**Report location:** `{storage}/reports/{project-slug}/{run-timestamp}/`

Each run is preserved. Use `--run <timestamp>` to drill into older analyses:
```bash
# List available runs for current project
ls ~/.claude/analysis/reports/${PROJECT_SLUG}/

# Drill into a specific run
/drilldown S47 --run 2025-12-30-14-30
```
