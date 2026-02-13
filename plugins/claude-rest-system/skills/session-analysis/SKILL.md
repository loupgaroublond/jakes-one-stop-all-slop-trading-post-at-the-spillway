---
name: session-analysis
description: Analyze Claude Code sessions to extract learnings and mistakes. Use when processing session JSONL files during /rest workflow, identifying patterns worth documenting, and finding friction points that need better steering.
allowed-tools: Read, Grep, Glob, Bash
---

# Session Analysis Skill

## Purpose

Systematic analysis of Claude Code sessions to identify:
- **Learnings**: Things Claude figured out that are worth documenting for future
- **Mistakes**: Patterns where Claude repeatedly erred, indicating need for better steering
- **Walked-Through Processes**: Multi-step procedures the user taught the agent, candidates for automation

## Analysis Process

**Note:** When a pre-generated transcript is available (from the orchestrator's Wave 1), primary analysis is from reading the transcript directly. The grep-based keyword searches below serve as supplementary detection for targeted raw data extraction from the original JSONL.

### 1. Session Inventory

First, understand what you're analyzing:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rest_session_inventory.sh <session_file>
```

This shows line numbers, message types, and previews. Use this to identify regions of interest.

### 2. Search for Indicators

Look for signals in the session content:

**Error indicators** - Things went wrong:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rest_session_search.sh <session_file> "error|failed|exception|Error|Failed"
```

**Learning moments** - Claude figured something out:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rest_session_search.sh <session_file> "I see|understood|learned|realized|makes sense"
```

**User corrections** - User had to correct Claude:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rest_session_search.sh <session_file> "no,|actually|that's wrong|try again"
```

**Friction points** - Confusion or uncertainty:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rest_session_search.sh <session_file> "confused|unclear|not sure|don't understand"
```

**Process indicators** - User walked agent through steps (supplementary to transcript reading):
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rest_session_search.sh <session_file> "step 1|first do|then do|follow these steps|here's the process"
${CLAUDE_PLUGIN_ROOT}/scripts/rest_session_search.sh <session_file> "now |next |okay now|go ahead and"
```

**Navigation confusion** - Agent searching for file locations (learning candidates):
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rest_session_search.sh <session_file> "let me search|let me try|can't find|where is|trying to find"
```

### 3. Extract Relevant Ranges

When indicators are found, extract the surrounding context:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rest_session_extract.sh <session_file> <start_line> <end_line>
```

### 4. Categorize Findings

For each significant incident, determine:
- Is this a **learning** (worth documenting)?
- Is this a **mistake** (needs better steering)?
- Is this a **process** (user walked agent through reusable steps)?
- What **domain** does it relate to? (shell-scripting, kubernetes, file-ops, etc.)
- What **evidence range** [M#start-end] captures this?

### 5. Check Documentation Freshness

Before flagging a finding, check if relevant docs already address it:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rest_doc_freshness.sh <doc_file> <session_file>
```

**Interpretation:**
- `pre-dates`: Docs existed before incident → note "since addressed in {doc}"
- `post-dates`: Incident occurred before docs → this is actionable, docs may have been added in response
- `not-found`: No relevant docs → actionable, consider documenting

**Add to finding:**
```json
{
  "doc_check": {
    "file": "CLAUDE.md",
    "section": "Path Handling",
    "status": "existed_but_insufficient",
    "doc_timestamp": "2025-01-10T...",
    "incident_timestamp": "2025-01-12T..."
  }
}
```

**Status values:**
- `existed_but_insufficient`: Docs existed, weren't followed → needs stronger guidance
- `added_after`: Docs added post-incident → already addressed
- `not_documented`: No relevant docs exist → consider adding

## Findings Format

Structure each finding with enough detail to understand the substance:

```json
{
  "id": "L1",
  "type": "learning",
  "domain": "yaml-processing",
  "title": "yq array syntax differs from jq",
  "what_happened": "User asked to extract first item from YAML array. Claude tried jq syntax `.items[0]` which failed with parse error. After checking yq docs, discovered yq requires explicit dot: `.items.[0]`. Applied correctly in subsequent YAML processing.",
  "why_it_matters": "Common task when working with Kubernetes manifests. Without this knowledge, every YAML array access would fail on first attempt.",
  "outcome": "success",
  "evidence_range": [45, 52],
  "drill_down_keywords": ["yq", "array", "items", "parse error"]
}
```

For mistakes with multiple occurrences:
```json
{
  "id": "M1",
  "type": "mistake",
  "domain": "shell-scripting",
  "title": "Unquoted paths with spaces",
  "what_happened": "Three separate incidents of using unquoted variables in paths. First: `cp $SOURCE $DEST` failed on '/Users/foo/My Documents'. User corrected. Second: rsync with same issue at M#128. Third: mv command at M#133. Pattern persisted despite corrections.",
  "why_it_matters": "Causes silent failures or wrong behavior on any path with spaces. macOS paths frequently contain spaces (Application Support, iCloud folders).",
  "outcome": "failure",
  "occurrences": [[50, 55], [128, 133], [180, 185]],
  "drill_down_keywords": ["quote", "spaces", "variable", "$SOURCE", "$DEST"]
}
```

For walked-through processes:
```json
{
  "id": "P1",
  "type": "process",
  "domain": "kubernetes",
  "title": "EKS Cluster Deployment Procedure",
  "what_happened": "User walked agent through 4-step EKS deployment: (1) create cluster config YAML with node group specs, (2) apply with `eksctl create cluster`, (3) verify node groups with `kubectl get nodes`, (4) update kubeconfig. Agent needed correction on `--region` parameter at step 4.",
  "why_it_matters": "General-purpose deployment procedure. User had to teach it step by step, suggesting this could be automated or documented as a reusable workflow.",
  "outcome": "success",
  "evidence_range": [120, 185],
  "step_count": 4,
  "user_corrections": 1,
  "multi_turn": true,
  "drill_down_keywords": ["eks", "deploy", "cluster", "eksctl", "kubeconfig"]
}
```

### Required Fields

- **domain**: Emergent category (shell-scripting, kubernetes, file-ops, json-yaml, git, etc.)
- **title**: Short identifier for the finding
- **what_happened**: Specific narrative of the incident - what was attempted, what went wrong/right, what the resolution was
- **why_it_matters**: Why this is worth noting - impact on future work
- **outcome**: success | failure | partial
- **evidence_range**: Line numbers [start, end] in the session file
- **drill_down_keywords**: Specific search terms for deeper investigation

## Report Narrative

### Detail Level: Substance Over Summary

**BAD** (too brief):
> "Both sessions successfully retrieved official documentation."

**GOOD** (explains substance):
> "S12 [M#23-45]: User needed bd (beads) CLI schema. Claude fetched GitHub README, extracted JSON schema for issue creation including required fields (title, type) and optional fields (description, priority 0-4, labels). User confirmed schema matched their bd version. Applied in subsequent `bd create` commands with correct field names."

### Guidelines

- Explain what was retrieved/learned, not just that something happened
- Include actual values, field names, command syntax where relevant
- Show the outcome and how it was applied
- One finding = one coherent narrative paragraph
- Include [M#n-m] references for drill-down
- End domain sections with brief observation if warranted
- End each finding with drill-down keywords in italics
- **Include callout annotations** for each finding:
  - `*Pattern:*` - For learnings: describe the reusable approach or technique discovered
  - `*Friction:*` - For mistakes/issues: explain the underlying UX or design problem
  - `*Mistake:*` - For repeated errors: note what guidance would prevent recurrence
  - `*Process:*` - For walked-through processes: step count, correction count, whether general-purpose
  - `*Drill-down:*` - Always: comprehensive keywords for deeper investigation

### Report Format

Follow the template at [report-template.md](report-template.md).

Key sections:
1. **Header**: Date, session range, total messages
2. **Domain sections**: Grouped findings with narratives
3. **Summary line**: Finding count and domain list
4. **Methodology**: Always included - documents how analysis was performed

See [patterns.md](patterns.md) for common search patterns and jq tips.

## Large Session Handling

For sessions with >100 messages, use keyword search first-pass to avoid reading entire sessions.

### 1. Prefilter Sessions

Check session sizes before deciding approach:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rest_session_prefilter.sh <session_directory>
```

Returns JSON array with session_id, message_count, size_bytes, first_timestamp for each session.

### 2. Keyword Search First-Pass

For large sessions, search BEFORE reading:

```bash
# Run all indicator searches
${CLAUDE_PLUGIN_ROOT}/scripts/rest_session_search.sh <session_file> "error|failed|exception|Error|Failed"
${CLAUDE_PLUGIN_ROOT}/scripts/rest_session_search.sh <session_file> "I see|understood|learned|realized"
${CLAUDE_PLUGIN_ROOT}/scripts/rest_session_search.sh <session_file> "no,|actually|that's wrong|try again"
${CLAUDE_PLUGIN_ROOT}/scripts/rest_session_search.sh <session_file> "confused|unclear|not sure"
```

Collect all line numbers that matched. These are your "regions of interest."

### 3. Build Region Map

Group nearby hits into ranges with context:
- For each hit line N, create range [N-5, N+10]
- Merge overlapping ranges
- Result: list of ranges to extract

**Example:**
```
Hits: 23, 45, 47, 48, 120
Ranges: [18-33], [40-58], [115-130]
```

### 4. Targeted Extraction

Only read the identified ranges:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rest_session_extract.sh <session_file> 18 33
${CLAUDE_PLUGIN_ROOT}/scripts/rest_session_extract.sh <session_file> 40 58
${CLAUDE_PLUGIN_ROOT}/scripts/rest_session_extract.sh <session_file> 115 130
```

Analyze extracted content. This avoids reading 5000 lines when only 50 are relevant.

### 5. When to Use Full Read vs Targeted

| Session Size | Approach |
|--------------|----------|
| < 100 messages | Full read with inventory |
| 100-500 messages | Keyword first-pass, extract regions |
| > 500 messages | Keyword first-pass, may need subagent continuation |

### 6. Handling Zero Hits

If keyword searches return no hits on a large session:
1. The session may be routine/uneventful
2. Try domain-specific searches (e.g., `kubectl`, `docker`, `git rebase`)
3. Sample random ranges: beginning [1-20], middle, end [N-20, N]
4. If still nothing notable, mark session as "reviewed, no significant findings"
