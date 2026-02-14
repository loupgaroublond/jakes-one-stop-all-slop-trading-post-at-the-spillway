# Recommendations

Generated: 2026-02-12
Source: 5 pattern reports, 64 identified patterns, 413 session reports


## Priority 1: CLAUDE.md Changes (User-Level)

Changes to `/Users/yankee/.claude/CLAUDE.md` that address the highest-frequency correction patterns.


### Skill Loading Section (New)

Add after the "Working Style" section in General User Preferences.

```markdown
### Skill Loading Protocol

Before starting any technical task, check available skills for domain matches. Load relevant skills before proceeding with work. This is a pre-flight step, not an optional enhancement.

**Trigger keywords and matching skills:**
- EKS, cluster, upgrade, nodegroup, AMI, deployment -> eks-operations
- bash, script, jq, shell, set -e -> bash-scripting
- ticket, OP-, worktree, INDEX.md -> ticket-workflow
- beads, bd, epic, issue -> beads-issue-creation
- redo, redoconf, .do, .od, configure -> redo-redoconf
- repo, clone, worktree, scratch -> repo-worktree-management
- monitoring, TUI, probe -> zkube-upgrade-monitor

When a user's request contains any of these keywords, load the matching skill(s) before responding. When in doubt, load the skill -- the cost of loading an unnecessary skill is far lower than the cost of operating without domain context.
```

(Addresses pattern #44 "Forgot to Skill Up" -- S69, S73, S106, S136, S158, S161, S235, S258, S307, S337; user-corrections-consolidated sub-pattern 1)


### Sandbox-Aware Operations Section (New)

Add to the "Tool Usage" section.

```markdown
### Sandbox-Aware Operations

The following operations require `dangerouslyDisableSandbox: true` on Bash tool calls:
- **AWS CLI commands** -- SSO proxy runs on localhost and sandbox blocks access to it
- **Teleport (tsh) commands** -- sandbox cannot read ~/.tsh/ credential files
- **uv/pip/npm network operations** -- corporate proxy requires sandbox bypass
- **macOS `open` command** -- sandbox blocks desktop integration

When encountering "Operation not permitted" on credential paths (~/.aws/cli/cache/, ~/.tsh/) or "Failed to connect to proxy URL" errors, use sandbox bypass immediately rather than attempting workarounds or asking the user to re-authenticate.
```

(Addresses authentication-connectivity-consolidated M3; S106, S164, S216, S247, S256, S288)


### Execution Mode Section (New)

Add to the "Working Style" section.

```markdown
### Execution vs. Exploration Mode

Detect which mode the user's request implies and respond accordingly:

**Execution signals** (act first, narrate after): "monthly cycle", "routine", "let's prep", "upgrade time", "deploy", "run the scripts", "just do it"
- Respond with targeted action. Do not explain, summarize, or add unsolicited analysis.

**Exploration signals** (discuss first, act after): "let's design", "let's figure out", "ideation", "how should we", "what do you think"
- Respond with analysis, options, and questions.

**Factual request signals** (data, not commentary): "briefing", "list", "show me", "what's the status"
- Respond with raw data. Do not add recommendations, time estimates, or "why" analysis unless explicitly asked.

When in doubt, ask: "Should I investigate and report, or proceed with execution?"
```

(Addresses user-corrections-consolidated sub-patterns 2 and 3 -- S13, S54, S102, S106, S181, S224, S270)


### Literal Instructions Rule (New)

Add to the "Working Style" section.

```markdown
### User-Provided Values Are Authoritative

When the user provides a specific path, command, value, or term, use it exactly as given. Do not substitute a "better", "standard", or "corrected" version.

- If the user provides `/Users/ynemoy/.claude/plugins/cache/all-slop-marketplace/...`, use that exact path -- do not substitute `~/.claude/rest-plugin/...`
- If the project establishes terminology ("curated" vs "suggested" vs "matched"), use those terms precisely -- do not substitute natural-language synonyms
- If the user-provided value looks wrong, ask rather than silently replacing

This applies to: file paths, CLI commands, configuration values, domain terminology, and variable names.
```

(Addresses user-corrections-consolidated sub-pattern 4 -- S54, S207, S270, S295)


### Verification Checkpoint for Resumed Plans (New)

Add to the "Working Style" section.

```markdown
### Resuming Work from Previous Sessions

When a plan, spec, or configuration from a previous session is referenced:
1. Re-verify all assumptions against current state (cluster counts, AMI versions, branch status)
2. Check timestamps on referenced data sources -- anything older than 24 hours should be re-queried
3. Confirm scope has not changed (new clusters added, environments changed, branches merged)
4. Validate all identifiers (cluster names, ARNs, AMI IDs) against live systems
5. Treat the plan as a starting point, not gospel -- plans drift from reality within days
```

(Addresses verification-chains-consolidated manifestation #5 -- S248; naming-identity-drift sub-pattern 4 -- S248)


## Priority 2: CLAUDE.md Changes (Project-Level)

Changes to `/Users/yankee/Documents/grug-brained-employee/CLAUDE.md`.


### Infrastructure Safety Section Update

The existing "Infrastructure Safety" section should be expanded with concrete verification patterns. Replace the current brief reference with:

```markdown
## Infrastructure Safety

### Verification Chain Protocol

Every infrastructure operation follows: **Read state -> Validate expectations -> Apply change -> Verify result**. Skipping any link risks production incidents.

**Before git merge conflict resolution:**
- Query live cluster state (kubectl, AWS API) for every cluster in the conflict
- Do not assume main branch reflects production reality
- Verify nodegroup existence before accepting or rejecting changes

**Before batch operations:**
- Run pre-flight script against ALL targets, not just a sample
- Verify scope completeness: count expected items vs discovered items, cross-reference against multiple sources
- Use pattern matching for service/resource names -- do not hardcode service names

**Before terraform operations:**
- Compare S3 state file against LIVE AWS infrastructure, not just metadata
- Check S3 version history and DynamoDB for stale locks
- Distinguish expected operational drift (desired_size) from configuration drift (immutable settings)

**Verification of data flow direction:**
- Before implementing pipeline components, confirm: "Is this file an input or output? Does this script write to survey output/ or /tmp?"
- Confirm whether a data file is human-curated (input) or machine-generated (output)

**Scope verification as first step:**
- "Did you look at ALL the files?" -- always verify input completeness
- "Are you looking at peers too?" -- check for additional data sources beyond the obvious ones
- Cross-reference against multiple sources, not just one directory listing
```

(Addresses verification-chains-consolidated -- S207, S256, S287, S292; user-corrections-consolidated sub-pattern 5 -- S270)


### AMI Management Reference (New Section)

Add after the Infrastructure Safety section.

```markdown
## AMI Management

### AMI Identity Disambiguation

AMIs have two distinct identifiers:
- **AMI name** (human-readable): `amazon-eks-node-al2023-x86_64-standard-1.32-v20251103`
- **AMI ID** (machine identifier): `ami-0c8468a278cde316e`

AMI IDs are **region-specific** -- the same AMI image has different IDs in us-west-2 vs eu-central-1.

The config field `ami_name` in stage.yaml actually expects AMI **IDs** despite its name. Always use the AMI ID, not the human-readable name, when setting this field.

### AMI State Model

In upgrade contexts, distinguish three AMI states:
- **Running AMI**: What the AWS API shows as currently deployed on nodes
- **Configured AMI**: What IaC (stage.yaml / values.yaml) declares should be deployed
- **Target AMI**: What the current upgrade operation will deploy

Default to **target AMI** when populating monitoring configs or upgrade scripts.

### AMI Lookup Pattern

When resolving AMI IDs:
1. Use the human-readable AMI name as the search key
2. Query the correct AWS region (AMI IDs differ per region)
3. If AMI appears invalid, try a cross-region search before concluding it doesn't exist
4. Cache results in `data/ami-cache.json` for expensive DescribeImages API calls
5. Always validate against live AWS API -- metadata files go stale
```

(Addresses naming-identity-drift sub-pattern 2 -- S106, S223, S243, S246, S248, S324; pattern #5 AMI Management)


## Priority 3: Skill Updates


### eks-operations Skill

**File:** `/Users/yankee/Documents/grug-brained-employee/.claude/skills/eks-operations/`

1. **Add naming convention matrix.** For each zkube version (1.0, 2.0, snowflake, ZSDK), document the exact naming pattern for every system (EKS name, IaC path, kubectl context, ArgoCD app, AWS profile, AWS region). Include worked examples showing how to derive one name from another. Document known exceptions.

   Example entry:
   ```markdown
   ### zkube 1.0 Naming
   - IaC path: `zk1-{env}/{datacenter}/eks-{cluster_type}{NNN}` (e.g., `zk1-prod/fra5/eks-intpol001`)
   - EKS name: derived from datacenter + product (e.g., `de1-fra5-zpa-eks`) -- NOT predictable from IaC path
   - kubectl context: `prod-{profile}-{datacenter}-eks-{type}{NNN}` (e.g., `prod-zpatwo-fra5-eks-intpol001`)
   - AWS profile: `zpath-{env}.ET-SRE` (e.g., `zpath-prod.ET-SRE`)
   - EXCEPTION: mgmt clusters use `zpath-et-ops-tools.ET-SRE`, not `zpath-eng.ET-SRE`
   ```

   (Addresses naming-identity-drift sub-pattern 1 -- S85, S93, S154, S179, S235, S313; pattern #37 Naming Conventions, 108 sessions)

2. **Add sandbox-aware operations note.** Document that all AWS CLI, Teleport, and kubectl operations require `dangerouslyDisableSandbox: true`.

   (Addresses authentication-connectivity-consolidated M3 -- S106, S216, S256)

3. **Add kubectl JSON output patterns.**
   ```markdown
   ## kubectl JSON Output Patterns
   WRONG: `kubectl config get-contexts -o json` -- Not supported
   CORRECT: `kubectl config view -o json` -- Returns full kubeconfig, parse contexts array
   ```

   (Addresses S37 recommendation)

4. **Add AMI caching pattern reference.** Document the `data/ami-cache.json` pattern for caching EC2 DescribeImages results.

   (Addresses S37 recommendation)


### bash-scripting Skill

**File:** `/Users/yankee/Documents/grug-brained-employee/.claude/skills/bash-scripting/`

1. **Add jq type-safety pattern.**
   ```markdown
   ## jq Type Safety
   Always check field type before string operations on potentially null/non-string fields:
   ```bash
   jq '.[] | select(.field | type == "string" and test("pattern"))'
   ```
   This prevents "null is not iterable" errors when processing beads or JSONL data.
   ```

   (Addresses S145 recommendation)

2. **Add performance anti-pattern warning.**
   ```markdown
   ## Performance: Avoid Nested jq in Loops
   WRONG (O(n*m)):
   ```bash
   while read -r line; do
     jq --arg id "$line" '.[] | select(.id == $id)' bigfile.json
   done < ids.txt
   ```

   CORRECT (O(n)):
   ```bash
   jq --slurpfile ids <(jq -R . ids.txt | jq -s .) '.[] | select(.id as $id | $ids[0][] | . == $id)' bigfile.json
   ```

   For bulk operations on 1000+ records, prefer Python with ThreadPoolExecutor.
   ```

   (Addresses pattern #28 jq Processing, 53 sessions)


### redo-redoconf Skill

**File:** `/Users/yankee/Documents/grug-brained-employee/.claude/skills/redo-redoconf/`

1. **Reinforce the .do vs .od distinction with a decision table.**
   ```markdown
   ## Critical: .do vs .od Files

   | Property | .do files | .od files |
   |----------|----------|----------|
   | Location | Source directory | Source directory |
   | Output goes to | Same location (redo native) | Build directory (redoconf extension) |
   | Dispatched by | redo directly | default.do.sh dispatcher |
   | When to use | Building in source tree | Building from configure/template pattern |

   The dispatcher pattern: configure script creates build dir + config.sh, default.do.sh reads `src` file to find source directory, .od files in source dir generate build outputs.

   NEVER manually copy files between library and deployment directories -- redo manages this.
   ```

   (Addresses tooling-evolution-consolidated lesson #3 -- S93, S136, S247)

2. **Add macOS path resolution note.**
   ```markdown
   ## macOS: /tmp Symlink
   On macOS, /tmp is a symlink to /private/tmp. Use `pwd -P` to resolve physical paths in .do/.od scripts to prevent relative path calculation errors.
   ```

   (Addresses S77 finding)


## Priority 4: New Tools / Scripts


### Pre-Flight Authentication Health Check

**File:** `/Users/yankee/.claude/self/auth_check.sh` (new)

Add authentication state verification to the session start workflow. Integrate into the existing `session_start.sh` hook.

```bash
#!/bin/bash
# auth_check.sh - Pre-flight authentication health check
# Run at session start to detect expired credentials before work begins

echo "=== Authentication Health Check ==="

# AWS SSO
if aws sts get-caller-identity --profile zpath-dev 2>/dev/null | jq -r '.Account' >/dev/null 2>&1; then
    echo "AWS SSO: VALID"
else
    echo "AWS SSO: EXPIRED -- run 'aws sso login --profile zpath-dev'"
fi

# MCP servers
for server in google-workspace zscaler-atlassian slack; do
    if pgrep -f "$server" >/dev/null 2>&1; then
        echo "MCP $server: RUNNING"
    else
        echo "MCP $server: NOT RUNNING"
    fi
done

# Podman machine (needed for zscaler-atlassian MCP)
if podman machine info 2>/dev/null | grep -q "Running"; then
    echo "Podman: RUNNING"
else
    echo "Podman: NOT RUNNING -- run 'podman machine start'"
fi

echo "==================================="
```

Display results at session start so the user can proactively fix issues before work begins. This converts reactive authentication failure diagnosis (5-20 wasted tool calls per incident) into a 2-second proactive check.

(Addresses authentication-connectivity-consolidated M1 -- S256, S293, S301, S314, S319)


### MCP Server Recovery Script

**File:** `/Users/yankee/.claude/self/mcp_recovery.sh` (new)

Automate the most common MCP failure recovery steps:

```bash
#!/bin/bash
# mcp_recovery.sh - Attempt to recover failed MCP servers

# Kill stale OAuth callback servers on port 8000
if lsof -i :8000 >/dev/null 2>&1; then
    echo "Killing stale process on port 8000..."
    kill "$(lsof -t -i :8000)" 2>/dev/null
fi

# Start Podman machine if stopped (needed for zscaler-atlassian)
if ! podman machine info 2>/dev/null | grep -q "Running"; then
    echo "Starting Podman machine..."
    podman machine start 2>/dev/null
fi

echo "MCP recovery steps complete. Restart Claude Code or run /mcp to reconnect."
```

(Addresses authentication-connectivity-consolidated M2 -- S301, S314)


### MCP Configuration Hardening

**File:** Update MCP server configurations in `~/.claude/settings.json` or `.mcp.json`

Pin Python version for Google Workspace MCP to prevent version incompatibility:

```json
{
  "mcpServers": {
    "google-workspace": {
      "command": "uvx",
      "args": ["--python", "3.14", "workspace-mcp"]
    }
  }
}
```

(Addresses authentication-connectivity-consolidated M6 -- S301)


## Priority 5: Workflow and Process Changes


### Teach-Twice-Then-Skill Rule

When the user teaches the same concept in multiple sessions, that concept should become a skill. Track informally by watching for:
- Same user correction appearing 2+ times across sessions (e.g., "that's an input, not an output")
- Same domain explanation needed by different agent instances
- Same workaround applied repeatedly (e.g., sandbox bypass for specific tools)

After the second occurrence, create a skill capturing that knowledge. Apply retroactively to existing multi-session teaching patterns that have not yet been captured:
- Git merge conflict resolution for infrastructure repos (S207 corrections)
- ArgoCD login patterns per environment (S145: `argocd login argocd-eng.mgmt.zpath.net --sso --grpc-web --insecure`)

(Addresses tooling-evolution-consolidated lesson #7 -- S136, S207, S247)


### Mandatory Completion Verification for Beads

Before closing any beads issue, verify against acceptance criteria explicitly:
- For test tasks: confirm the specific test type was executed (script-level, integration, command-level invocation)
- For investigation tasks: confirm findings were acted on, not just documented
- Do not conflate "partially tested" or "covered by other tests" with "done"

This should be added to the beads-issue-creation skill as a "Closing Checklist" section.

(Addresses tooling-evolution-consolidated lesson #5 -- S5, S65)


### Session Analysis Pipeline Improvements

For the `/rest` analysis system:

1. **Timestamped output directories** -- already implemented in this run, continue the pattern
2. **Analyzer completion markers** -- each analyzer should write `.complete` or `.error` file on finish
3. **Subagent session inclusion** -- ensure `agent-*.jsonl` sessions are included in analysis inventory, not just top-level sessions
4. **Atomic operations** -- use temporary directories for analysis output, move to final location only on success

(Addresses S24, S46, S65, S308 recommendations; tooling-evolution-consolidated #6)


### Scope Verification Checklist

Before any batch infrastructure operation, explicitly verify:
1. Count expected items vs discovered items
2. Cross-reference against multiple sources (AWS API + IaC + ArgoCD, not just one)
3. Check for peer/alternate sources ("are you looking at peers too?")
4. Log and display scope summary for human review before proceeding
5. Use `continue testing even after finding a match` principle -- gather ALL evidence before classifying

(Addresses verification-chains-consolidated manifestation #8 -- S59, S292; S304 multi-source principle)


## Priority 6: Future Infrastructure Investments

These are larger efforts that address systemic root causes. They should be tracked as beads issues.


### Canonical Identity Registry (beads issue)

Build and maintain a single lookup mapping all representations of each cluster. Source from the S316 three-source reconciliation output. Expose as CLI tool: `cluster-lookup --context prod-fra5-eks-zms001` returns all aliases (EKS name, IaC path, kubectl context, ArgoCD app, AWS profile, region).

This directly addresses the single largest source of per-cluster overhead: 5-15 minutes of name resolution per cluster, multiplied across 90+ clusters.

(Addresses naming-identity-drift M1 -- S85, S154, S235, S313; pattern #37, 108 sessions)


### AMI Resolution Library (beads issue)

Create a region-aware AMI lookup utility:
```bash
ami-resolve "amazon-eks-node-al2023-x86_64-standard-1.32-v20251103" --region us-west-2
# Output: ami-0c8468a278cde316e

ami-resolve "amazon-eks-node-al2023-x86_64-standard-1.32-v20251103" --all-regions
# Output: JSON map of region -> AMI ID
```

Eliminates the `ami_name` field confusion and cross-region lookup overhead.

(Addresses naming-identity-drift M2 -- S243, S246; pattern #5, 103 sessions)


### Continuous Drift Detection (beads issue)

Extend the S316 three-source reconciliation (AWS + ArgoCD + IaC) into a scheduled/on-demand process:
1. Run weekly or before upgrade campaigns
2. Flag entities that exist in one source but not others
3. Flag attribute differences between sources (version, AMI, region)
4. Generate drift report with actionable items

Converts drift from "discovered during incidents" to "detected during routine checks."

(Addresses naming-identity-drift M3 -- S85, S289, S316, S324; pattern #40, 22 sessions; pattern #61, 23 sessions)


### Guardrail Workaround Documentation (beads issue)

Document known Vertex AI guardrail false positive triggers and fallback strategies:

| Trigger | Fallback |
|---------|----------|
| Gmail search by person name | Search by subject line instead |
| MCP skill content rewriting | Break into smaller chunks, retry |
| Task/Plan subagent research | Use direct tool calls instead of Task |
| Large content blocks | Chunk into smaller operations |

Accept that some operations will be blocked and plan alternatives proactively.

(Addresses authentication-connectivity-consolidated M4 -- S113, S216, S285, S293)


## Cross-Reference: Pattern-to-Recommendation Mapping

| Pattern | Recommendations |
|---------|----------------|
| Verification Chains (190+ sessions) | Infrastructure Safety section update, Scope Verification Checklist |
| User Corrections (190+ sessions) | Skill Loading Protocol, Execution Mode, Literal Instructions Rule |
| Naming Conventions (108 sessions) | eks-operations naming matrix, Canonical Identity Registry |
| AMI Management (103 sessions) | AMI Management section, AMI Resolution Library |
| Auth/Connectivity (100+ sessions) | Sandbox-Aware Ops, Auth Health Check, MCP Recovery, MCP Config Hardening |
| Skill System (125 sessions) | Skill Loading Protocol, Teach-Twice-Then-Skill |
| Redo/Redoconf (27 sessions) | redo-redoconf skill updates |
| Session Analysis (55 sessions) | Pipeline Improvements |
| Documentation Drift (23 sessions) | Continuous Drift Detection |
| Scope Creep (9 sessions) | Execution Mode section |
| Beads Tracking (77 sessions) | Completion Verification for Beads |
| Forgot to Skill Up (8+ sessions) | Skill Loading Protocol |
| Explanation-First (6+ sessions) | Execution Mode section |
