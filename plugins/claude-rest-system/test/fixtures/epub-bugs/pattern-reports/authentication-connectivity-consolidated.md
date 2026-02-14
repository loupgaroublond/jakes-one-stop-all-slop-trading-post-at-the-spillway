# Pattern: Authentication and Connectivity Friction

**Sessions involved:** S109, S113, S123, S130, S131, S133, S145, S152, S155, S184, S216, S226, S256, S261, S285, S293, S299, S300, S301, S314, S319, S332, S341 (and 80+ additional sessions with related mentions)

**Total occurrences:** 100+ across 413 analyzed sessions

**Severity:** High -- this is the single most pervasive source of non-productive time in the project. It affects nearly every session that touches external services and routinely blocks or delays legitimate work.


## Pattern Overview

The grug-brained-employee project operates within a corporate enterprise environment (Zscaler) where multiple overlapping security and authentication systems create compounding friction for AI-assisted automation workflows. The pattern manifests as a "friction stack" where any one layer can independently block work, and the layers interact unpredictably.

The friction stack, from outermost to innermost:

1. **Corporate AI guardrails** (Vertex AI / Zscaler GenAI policies) -- block requests flagged as prompt injection
2. **Network proxy** (Zscaler Internet Access) -- intercepts and sometimes blocks HTTP/HTTPS calls
3. **SSO session expiry** (Okta) -- AWS, ArgoCD, Teleport, and other services lose authentication after timeout
4. **MCP server lifecycle** -- servers crash, lose OAuth tokens, encounter dependency rot, or fail to start
5. **OAuth token management** -- Google Workspace, Slack, and Atlassian tokens expire or become invalid
6. **Sandbox isolation** -- Claude Code sandbox prevents access to credential stores and proxy configurations

These six layers interact: an expired SSO session behind a corporate proxy running inside a sandboxed shell, trying to reach an MCP server that needs an OAuth refresh, can produce error messages that point to the wrong layer entirely.


## Manifestations


### MCP Server Failures (24+ sessions)

**Representative sessions:** S301, S314, S319, S293, S285, S184, S261, S130, S152

MCP servers are the primary mechanism for extending Claude's reach to external services (Google Workspace, Jira/Confluence, Slack). They fail in multiple distinct ways:

**Startup failures:**
- Python version incompatibility -- MCP server package requires Python 3.10+ but system Python is 3.9.18 (S301). Fix: `uvx --python 3.14 workspace-mcp`
- Podman machine not running -- containerized MCP servers (zscaler-atlassian) require Podman VM, which stops after system sleep or reboot (S314). Error: "Cannot connect to Podman socket: connection refused"
- Port conflicts -- stale OAuth callback servers hold port 8000, preventing new server startup (S301). Fix: `lsof -i :8000` then `kill <pid>`
- Missing API enablement -- Gmail API not enabled in GCP project, causing cryptic failures until user manually enables it in Cloud Console (S113)

**Runtime failures:**
- 404 errors on document access -- Google Workspace MCP returns "unexpected status code: 404" for documents the user owns (S319, S293). Persistent across retries, suggesting auth/permission issue rather than transient glitch
- `supportsAllDrives` parameter bug -- MCP tool passes unsupported parameter to Google Drive API (S113). Upstream bug requiring MCP package update
- OAuth token expiry mid-session -- Google Workspace tokens expire, requiring browser-based re-authentication that interrupts agent workflow (S226, S155, S123)

**Configuration failures:**
- Disabled config files -- `.mcp.json.disabled` found in project root, indicating user previously disabled MCP due to issues (S293). Re-enabling and restarting Claude still fails
- Connection error messages that hide root cause -- "Failed to reconnect to google-workspace" doesn't indicate whether the issue is Python version, port conflict, OAuth expiry, or network (S301)

**Impact:** MCP failures are the most disruptive manifestation because they block entire categories of work (document access, Jira ticket creation, Confluence research). In S293, the user's simple goal -- "get me a list of clusters not yet upgraded" from a Google Doc -- was blocked at every turn by cascading MCP, WebFetch, and guardrail failures. The session ended with zero progress on the actual task.


### AWS SSO Expiry (52+ sessions)

**Representative sessions:** S256, S131, S216, S133, S145, S332

AWS SSO sessions expire after a fixed timeout, silently invalidating cached credentials. This manifests in several ways:

**Proxy URL connection failures:**
- Error: "Failed to connect to proxy URL: http://localhost:64824" (S256)
- Root cause: SSO proxy process died or restarted on different port
- User correction in S256: "try running these commands outside of the sandbox" -- sandbox isolation prevents access to SSO proxy

**Credential permission errors:**
- Error: "[Errno 1] Operation not permitted: '/Users/ynemoy/.aws/cli/cache/...'" (S216)
- Root cause: sandbox cannot read credential cache files
- Workaround: `dangerouslyDisableSandbox: true` on AWS CLI bash calls

**Silent credential staleness:**
- No error message -- commands simply return empty results or hang (S133, finding T5 mentions 27% kubectl access failure rate partly due to expired credentials)
- Agent may not realize credentials are stale and waste many tool calls before discovering the issue

**Interaction with sandbox:**
- Claude Code sandbox interferes with AWS SSO proxy access
- Running commands outside sandbox fixes proxy issues but bypasses security isolation
- Pattern: agent hits proxy error --> asks user to re-authenticate --> user says "try outside sandbox" --> works without re-auth

**Impact:** AWS SSO expiry is the most frequent interruption during infrastructure operations. Every session involving AWS CLI commands (cluster surveys, terraform operations, EKS queries) is vulnerable. The agent typically wastes 5-15 tool calls before diagnosing the issue, then requires user intervention to resolve.


### Corporate Guardrail Friction (52+ sessions)

**Representative sessions:** S293, S113, S285, S216, S299

Zscaler's enterprise AI guardrails (Vertex AI integration) block requests that trigger the prompt injection detector. These blocks hit legitimate work:

**False positive prompt injection detection:**
- Searching Gmail for messages about a person named "Haris" triggers prompt injection detector (S113). Two retries, both blocked
- Restarting Claude and trying MCP tools after re-enabling config triggers guardrail (S293): `'error_type': 'Guardrail Policy Violation', 'blockingDetectors': ['prompt_injection']`
- Writing MCP skill documentation triggers guardrail -- 504 Gateway Timeout and 400 Guardrail Policy Violation during documentation rewrites (S285)
- Using Task/Plan subagent triggers guardrail -- research task about bumpami.py blocked (S216)

**Gateway timeouts through proxy:**
- 504 Gateway Timeout errors during normal operations (S285)
- May be Zscaler proxy intercepting and timing out requests to external APIs
- Intermittent -- same request may succeed on retry

**Model access restrictions:**
- Vertex AI model not available in GCP project: "Publisher Model claude-opus-4-5 was not found or your project does not have access" (S299)
- Forces fallback to different model, potentially changing behavior

**Impact:** Guardrail blocks are the most frustrating manifestation because they are unpredictable, not debuggable by the agent, and have no programmatic workaround. The resolution guidance points to a Confluence page about guardrail bypass, but disabling guardrails is not appropriate for normal work. In S285, the user retried 5+ times ("try again") attempting to work around guardrail blocks during legitimate documentation work. The session achieved only 1 of 3 planned skill rewrites.


### OAuth Flow Friction (16+ sessions)

**Representative sessions:** S123, S130, S155, S226, S152, S145

OAuth authentication flows require browser interaction, creating a hard dependency on user availability:

**Browser-based authentication interrupts workflow:**
- Every Google Workspace MCP session starts with an OAuth URL the user must click (S123, S226). The "deed is done" pattern appears repeatedly
- Okta SSO for ArgoCD requires browser authentication (S145): `argocd login ... --sso`
- PagerDuty CLI OAuth conflicts with MCP server on port 8080 (S155). Workaround: use API token instead

**Enterprise identity provider complications:**
- Okta SSO adds layers beyond standard Google OAuth (S130): "note that we use okta for oauth"
- Standard OAuth flows documented in tool READMEs may not work with Okta intermediary
- Multiple proxies with different authentication scopes: eng, beta, prod for Teleport (S300)

**Token/session lifetime issues:**
- Google Workspace OAuth tokens expire, requiring re-authentication mid-work (S226)
- Clipboard operations for OAuth URLs are finicky -- `echo | pbcopy` fails (S123)
- Wrong email used in OAuth flow requires correction: "i'm not yair, i'm ynemoy@zscaler.com" (S155)

**Impact:** OAuth is the most predictable friction point -- it happens at the start of nearly every session that uses external services. The 30-60 second interruption per OAuth flow multiplied across multiple services (Google, Atlassian, Slack, ArgoCD) adds up to significant cumulative delay.


## Root Cause Analysis

The root causes fall into three categories:


### 1. Architectural: Too Many Independent Auth Systems

The enterprise environment requires authentication with 6+ independent systems, each with its own token lifecycle:
- AWS SSO (Okta --> AWS STS, ~8 hour session)
- Google Workspace OAuth (tokens with variable expiry)
- Atlassian MCP (API tokens in encrypted env file)
- Slack MCP (browser tokens xoxc/xoxd or OAuth xoxp)
- ArgoCD SSO (Okta --> OIDC, per-cluster)
- Teleport (Okta --> certificates, per-proxy)

None of these systems coordinate. A session that needs AWS, Google Docs, and Jira requires three separate authentication states to be valid simultaneously.


### 2. Environmental: Sandbox Isolation vs Credential Access

Claude Code's security sandbox prevents access to:
- AWS SSO proxy on localhost (port changes between restarts)
- Credential cache files (~/.aws/cli/cache/)
- System keychain entries
- MCP server processes running in other shells

This creates a catch-22: sandbox protects against unauthorized access, but legitimate credential access requires sandbox bypass (`dangerouslyDisableSandbox: true`).


### 3. Operational: No Proactive Health Checking

No mechanism exists to verify authentication state before attempting work:
- MCP server connectivity is not checked until first tool call fails
- AWS SSO expiry is not detected until a command returns an error
- OAuth token validity is not verified until a request is rejected
- Podman machine state is not checked until container startup fails

The agent discovers authentication problems reactively, often after wasting 5-20 tool calls on the wrong diagnosis.


## Impact Assessment


### Quantified Time Loss

Based on session evidence:

- **MCP startup troubleshooting:** 15-30 tool calls per incident (S301: ~20 turns to diagnose and fix)
- **AWS SSO re-authentication:** 5-15 tool calls to diagnose, plus user intervention time
- **Guardrail blocks:** 3-10 retries per incident, often unresolvable (S285: 5+ retries, partial completion)
- **OAuth flow interruption:** 2-5 minutes per service per session

Estimated that 10-20% of total session time in infrastructure-touching sessions is consumed by authentication/connectivity friction.


### Qualitative Impact

- **Task abandonment:** Some sessions end without completing their original goal (S293, S319)
- **Cognitive load on user:** User must diagnose whether to re-authenticate, restart MCP, disable sandbox, or retry
- **Workflow fragmentation:** Authentication failures interrupt multi-step operations, requiring state reconstruction
- **Reduced trust in automation:** Repeated failures erode confidence in using MCP tools, leading to manual alternatives


### Sessions Most Severely Impacted

| Session | Original Goal | Actual Outcome | Blocker |
|---------|--------------|----------------|---------|
| S293 | Get cluster list from Google Doc | Zero progress | MCP 404, WebFetch blocked, guardrail violation |
| S319 | Cache Google Doc as markdown | Zero progress | MCP 404 errors, user interrupted |
| S285 | Rewrite 3 MCP skills | 1 of 3 completed | 504 timeouts, guardrail violations |
| S301 | NLB troubleshooting in Google Doc | Spent entire session on MCP fix | Python version + port conflict |
| S299 | Model testing | Could not use desired model | Vertex AI model access restriction |


## Recommended Mitigations


### M1: Pre-Flight Authentication Health Check (session_start hook)

Add authentication verification to the existing `session_start.sh` hook:

```bash
# Check AWS SSO session validity
aws sts get-caller-identity --profile zpath-dev 2>/dev/null && echo "AWS SSO: valid" || echo "AWS SSO: EXPIRED"

# Check MCP server processes
for server in google-workspace zscaler-atlassian slack; do
    pgrep -f "$server" >/dev/null && echo "MCP $server: running" || echo "MCP $server: NOT RUNNING"
done

# Check Podman machine state
podman machine info 2>/dev/null | grep -q "Running" && echo "Podman: running" || echo "Podman: NOT RUNNING"
```

Display results at session start so user can proactively fix issues before work begins.


### M2: MCP Server Auto-Recovery Script

Create a script that attempts to restart failed MCP servers with known fixes:

- Check and start Podman machine if stopped
- Kill stale OAuth processes on port 8000
- Verify Python version compatibility
- Test connectivity before declaring ready

This could be triggered automatically on MCP connection failure rather than requiring manual diagnosis.


### M3: Sandbox-Aware AWS CLI Wrapper

Document and standardize the pattern for AWS CLI operations:

- Always use `dangerouslyDisableSandbox: true` for AWS CLI commands
- Add this as a project instruction in CLAUDE.md (or the eks-operations skill)
- Prevent the repeated pattern of: sandboxed command fails --> agent confused --> user says "try outside sandbox"


### M4: Guardrail Workaround Documentation

Since guardrail false positives cannot be fixed by the agent:

- Document known triggers (email search by name, MCP skill content, Task tool)
- Document fallback strategies for each (direct tool use instead of Task, search by subject instead of name)
- Accept that some operations will be blocked and plan alternatives


### M5: Unified Token Refresh Workflow

Create a single command that refreshes all authentication tokens:

```bash
#!/bin/bash
# refresh-all-auth.sh
aws sso login --profile zpath-dev          # Refreshes all AWS SSO profiles
podman machine start 2>/dev/null           # Ensure Podman running for Atlassian MCP
# Google Workspace and Slack tokens require browser -- prompt user
echo "Please complete Google Workspace OAuth if prompted"
echo "Please verify Slack token if needed"
```

Run at start of day or when multiple auth failures detected.


### M6: MCP Configuration Hardening

Based on S301 findings, add Python version to all MCP server configs:

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

This prevents the Python version incompatibility failure mode entirely.


## Keywords for Future Detection

Use these keywords when searching session transcripts for this pattern:

**MCP failures:** `mcp`, `MCP`, `Failed to reconnect`, `unexpected status code`, `mcp-authentication`, `mcp-server`, `google-workspace`, `zscaler-atlassian`, `slack`, `Podman`, `podman machine`, `port 8000`, `port 41001`, `uvx`, `workspace-mcp`

**SSO/credential issues:** `SSO`, `sso`, `re-authenticate`, `credential`, `proxy URL`, `localhost:64824`, `Operation not permitted`, `aws/cli/cache`, `sso_start_url`, `aws-sso-util`, `session expired`, `token expired`

**OAuth:** `OAuth`, `oauth`, `authorization URL`, `the deed is done`, `callback server`, `Okta`, `okta`, `OIDC`, `cli_client_id`, `xoxc`, `xoxd`, `xoxp`

**Guardrails:** `Guardrail Policy Violation`, `prompt_injection`, `blocking_info`, `blockingDetectors`, `504 Gateway Timeout`, `400`, `Vertex AI`, `vertex-ai`

**Sandbox:** `sandbox`, `dangerouslyDisableSandbox`, `outside of the sandbox`, `Operation not permitted`

**General connectivity:** `connection refused`, `connection timeout`, `gRPC`, `grpc-web`, `TLS`, `proxy`, `certificate`, `401`, `403`, `404`, `dial tcp`
