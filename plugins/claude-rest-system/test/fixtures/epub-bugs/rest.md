# Rest Analysis Report: 2026-02-12

## Executive Summary

This report represents a comprehensive analysis of **412 sessions** from the grug-brained-employee project, covering the full history of Claude Code usage across both personal and work machines.

**Key statistics:**
- **Sessions analyzed:** 412 (100% coverage of all substantive sessions)
- **Total messages processed:** ~145,000
- **Session sources:** 284 work machine, 128 local (archived + active)
- **Patterns identified:** 64 across 5 severity levels
- **Consolidated pattern reports:** 5 (covering the highest-impact cross-session themes)
- **Analysis method:** Transcript-first with targeted JSONL extraction for large sessions

**Top findings:**
1. **Verification chains** are the most pervasive operational pattern (190+ sessions) - the principle of "read state → validate → apply → verify" is foundational to safe infrastructure operations
2. **User corrections** appear in 190+ sessions, with recurring sub-patterns: "forgot to skill up," explanation-first anti-pattern, scope creep, and literal vs interpreted instructions
3. **Authentication and connectivity friction** (MCP failures, SSO expiry, corporate guardrails) disrupts workflows in 100+ sessions
4. **Naming and identity complexity** across 108+ sessions creates persistent confusion (cluster naming, AMI name vs ID, zkube 1.0 vs 2.0)
5. **Tooling evolution** across 200+ sessions shows continuous improvement: skills system, plugins, beads issue tracking, redo/redoconf build system, session analysis

The project is primarily an infrastructure engineering assistant focused on EKS cluster management, AMI upgrades (OP-5383), cluster inventory (OP-6111), and operational automation within the Zscaler zkube platform.

---


## Cross-Session Patterns

The following 5 consolidated pattern reports represent the highest-impact cross-session themes discovered during analysis.

---

# Pattern: Verification Chain Patterns

**Sessions involved:** S8, S16, S36, S72, S78, S96, S115, S126, S141, S154, S194, S207, S232, S244, S248, S256, S287, S292, S304, S322
**Total occurrences:** 190+
**Severity:** Critical

## Pattern Overview

Verification before action is the single most consequential behavioral pattern across the entire grug-brained-employee project. It appears in every domain of work -- EKS cluster upgrades, terraform state management, git merge resolution, deployment configuration, AMI selection, monitoring setup, documentation updates, and even script discovery. The canonical form is a four-phase chain: **Read state -> Validate expectations -> Apply change -> Verify result**. When this chain is followed completely, operations succeed reliably. When any link is skipped, the outcome ranges from wasted time (re-doing work) to near-production-incidents (wrong clusters targeted, wrong AMIs applied, terraform state corruption).

The pattern is not merely a best practice documented in CLAUDE.md -- it was codified there precisely because repeated sessions demonstrated its necessity through painful discovery. Session S8 formalized the verification chain into project documentation after observing that `ResourceInUseException` errors, wrong cluster targeting, and terraform state drift all stemmed from the same root cause: acting on assumptions instead of querying ground truth.

What makes this pattern critical rather than merely important is the infrastructure context. The project operates on production EKS clusters across multiple AWS accounts, regions, and environments. A configuration error applied to one cluster can affect hundreds of workloads. The verification chain is the primary defense against this class of failure.


## Manifestations

### 1. Live Infrastructure Verification Catches Wrong Assumptions (S207)

The most dramatic example of verification failure occurred in S207, where the agent attempted to resolve git merge conflicts for EKS cluster configuration files by accepting the main branch's version without checking live cluster state.

**What happened:** Three production clusters had blue/green deployment configurations in conflict. The agent assumed main branch (green=active) was correct and used `git checkout --ours` to resolve all conflicts. This deleted `pv1-storage-3-months` nodegroups that were actually running on live clusters.

**User intervention:**
> "check the diff, i think our merge was too aggressive, because there's extra bits that don't seem correct, but you can verify against the live clusters" (M#177)

**Verification revealed:** All three clusters were running blue nodegroups, contradicting the main branch. kubectl confirmed `pv1-storage-3-months-green` existed on every cluster. The entire merge had to be reset and redone.

**Second failure in the same session:** The agent then accepted an orphaned cluster directory (`preview/pdx2/eks-lz001`) without checking its structure or git history. The user's frustrated correction:
> "did. you. check. the. terraform. state. for. the. eks. name. like. i. told. you. to?" (M#314)

Investigation revealed the directory was incomplete (missing `terragrunt.hcl`), and git history showed it had been deleted in OP-5924. The punctuated emphasis in the user's message signals this was not the first time verification was skipped.


### 2. Pre-flight Scripts Catch Service Naming Variations (S287)

Session S287 demonstrates verification catching a bug that would have gone undetected without systematic pre-flight checks. The agent created `preflight-check.sh` to validate clusters before batch NLB updates.

**Discovery:** The pre-flight check found that `qa-pdx2-eks-etmetrics001` had TWO internal nginx services with naming patterns different from the hardcoded service name in the update script:
- Expected: `ingress-nginx-internal-controller-internal`
- Actual: `ingress-internal-ingress-nginx-controller-internal` and `ingress-internal-qa-vm-pdx2-ingress-nginx-controller-internal`

**Impact:** Without the pre-flight check, the update script would have silently skipped this cluster, leaving 2 services unfixed. The total count changed from 4 services across 4 clusters to 6 services across 5 clusters.

**Resolution:** The script was changed from hardcoded service names to pattern matching (`endswith("-internal")`), making it future-proof against naming variations.


### 3. Terraform State Digest Validation Chain (S256)

Session S256 shows verification chains applied to terraform state corruption -- a recurring issue where S3 and DynamoDB digests diverge after interrupted operations.

**The complete validation chain executed:**
1. Download S3 state file and calculate MD5
2. Inspect state file JSON structure for integrity
3. Compare against LIVE AWS infrastructure (not just metadata)
4. Check S3 version history to reconstruct timeline
5. Query DynamoDB for locks and digest staleness
6. Make evidence-based decision

**Critical user correction at step 3:**
> "did you examine the actual resources on AWS that are in the state file?" (M#149)

The agent had only performed high-level checks (cluster exists, 32 nodegroups exist) without comparing actual resource configurations (scaling configs, VPC, security groups, IAM roles). After correction, the agent distinguished between **expected operational drift** (desired_size changes) and **configuration drift** (immutable settings), enabling a safe fix.

The fix resolved a 14-day stale lock, and the validation methodology was documented for the second recurrence of this issue pattern.


### 4. Deployment Configuration Verified Against AWS API (S115)

Session S115 caught three critical configuration errors through the `verify_cluster_match.py` pre-flight script:
- **Wrong AWS profile:** `zpath-zpatwo.ET-SRE` should have been `zpatwo-net.ET-SRE`
- **Wrong cluster name:** `de2-fra5-zpa-eks` should have been `de1-fra5-zpa-eks`
- **Wrong AMI format:** AMI ID (`ami-0abcd...`) instead of AMI name (`amazon-eks-node-1.30-v20241216`)

Each of these would have caused deployment failures or, worse, applied changes to the wrong cluster. The verification script caught all three before any deployment operation was attempted.


### 5. Plan Verification Before Execution (S248)

Session S248 resumed work from a plan file created in a previous session. The agent verified current state before executing the plan and found four errors:
1. Cluster count was wrong (plan assumed 2, discovery found 3)
2. AMI references pointed to incorrect file locations
3. Cluster ARN had a naming discrepancy (hyphen before "001")
4. Git workflow assumptions were incorrect for the ticket's worktree setup

**Lesson documented:** "Plans created in previous sessions may contain errors from incomplete information. Always verify current state before proceeding."


### 6. Documentation vs Reality Drift (S16, S96, S322)

Multiple sessions discovered that documentation had drifted from implementation reality:

**S16:** The Bash tool was documented as using bash, but actually used the system's `$SHELL` (zsh on macOS). Running `echo $0` and `ps -p $$` proved the mismatch. This caused bash-specific syntax suggestions to fail silently.

**S96:** `marketplace.json` was updated to reflect a single consolidated plugin, but `README.md` still listed 14 separate plugins. The Edit tool fixed the documentation, but the drift could have caused confusion for users following outdated installation instructions.

**S322:** `CLASSIFICATION-PIPELINE.md` was outdated and did not match the actual Python implementation in `classify_clusters.py`. The documented 3-stage pipeline had different logic flow from the implemented code. The fix required reading both docs and implementation, identifying gaps, and rewriting documentation with concrete examples from real infrastructure.


### 7. kubectl Wait Output Cannot Be Trusted (S141)

When investigating a KUTTL test failure, the agent initially accepted `kubectl wait` output reporting 8 resources as "timed out." User-guided deeper investigation revealed only 3 resources were actually unhealthy -- the other 5 had become healthy before the timeout, but kubectl wait's atomic failure semantics reported all remaining resources as failed.

**Pattern:** Verify tool output against actual resource state rather than trusting aggregate failure reports.


### 8. Incomplete Scope Discovery (S292, S59)

**S292:** The agent read a single beta ticket file and attempted to create combined communications, missing two additional beta ticket files. User correction: "you didn't look at all the beta files."

**S59:** The agent built a session inventory of 109 sessions from local and iCloud sources, completely missing 505 peer machine sessions. User caught it with: "are you looking at peers too?" The inventory grew from 109 to 614 sessions -- a 5x increase.

Both cases demonstrate that verification includes verifying the completeness of your inputs, not just their correctness.


### 9. Multi-Source Data Reconciliation (S244, S304)

**S244:** Deployment configurations propagated incorrect kubectl context formats (ARN-based instead of Teleport aliases) because the source data (`curated-cluster-mappings.json`) contained wrong values. The agent reconciled data from six different sources (survey data, curated mappings, historical deployments, current deployments, Teleport contexts, AWS EKS API) to identify and correct the mismatch.

**S304:** The cluster classification pipeline used comprehensive evidence collection with a key principle: "Continue testing even after finding a match." This prevented early-return classification errors by gathering ALL evidence from multiple sources before making a determination, achieving 100% HIGH confidence classification across 247 clusters.


### 10. Terraform Apply Sequencing Gap (S126)

Session S126 discovered that the deployment framework was missing a critical terraform apply step between stage.yaml modification and nodegroup scaling:

```
2.3: Update stage.yaml (change AMI, swap blue/green)
[MISSING]: Apply terraform to create new nodegroups
2.4: Copy sizes from old to new nodegroups (FAILS if nodegroups don't exist)
```

The missing step was discovered during execution, not during planning. A pre-execution validation that checked whether the downstream step's dependencies existed would have caught this gap.


## Root Cause Analysis

The verification chain pattern keeps recurring for several interconnected reasons:

**1. Assumption Bias in Agent Behavior.** The agent's default mode is to reason from context (code, documentation, configuration files) rather than query live systems. This works most of the time but fails when reality has diverged from the artifacts being read. Sessions S207 and S154 show this explicitly: the agent assumed main branch configuration was correct without checking actual cluster state.

**2. Infrastructure Naming Inconsistencies.** AWS profiles, cluster names, kubectl contexts, IaC directory names, and Teleport aliases all use different naming conventions for the same clusters. Sessions S115, S244, and S287 show that these inconsistencies make it impossible to reliably infer one identifier from another. The only safe approach is to verify against the canonical source (usually the AWS API or terraform state).

**3. Temporal Drift Between Documentation and Reality.** Plans, configurations, and documentation are point-in-time snapshots. Between the time they are written and the time they are executed, infrastructure changes: AMIs are updated, branches are merged, nodegroups are scaled, locks become stale. Sessions S16, S96, S248, and S322 all discovered documentation that was correct when written but wrong at execution time.

**4. Tool Output Opacity.** Tools like `kubectl wait`, `git checkout --ours`, and `terraform import` have aggregate or all-or-nothing semantics that mask underlying reality. Session S141 (kubectl wait reporting 8 failures when only 3 existed) and S207 (git checkout --ours discarding live nodegroups) show that trusting tool output without independent verification leads to incorrect conclusions.

**5. Scope Completeness Assumptions.** The agent tends to proceed with whatever data it has found, without verifying that the data is complete. Sessions S59 (missing 505 peer sessions) and S292 (missing 2 beta ticket files) show that the initial search is often incomplete, and explicit verification of scope coverage is needed.

**6. Cross-Session Context Loss.** Plans created in one session may contain errors or outdated assumptions by the time they are executed in another session. S248 found four errors in a plan file from a previous session. Without verification at execution time, those errors would have propagated into infrastructure changes.


## Impact Assessment

**When verification is skipped, consequences fall into four severity tiers:**

**Tier 1 -- Production Risk (sessions S207, S115, S126):**
Wrong clusters targeted, wrong AMIs applied, missing terraform steps. These could cause service disruptions if applied without additional human review. The verification chain is sometimes the last line of defense before a destructive action.

**Tier 2 -- Wasted Work (sessions S36, S248, S287):**
Incomplete commits requiring amendment, plans executed with wrong assumptions requiring re-work, scripts that skip clusters needing updates. The work must be redone, consuming maintenance window time and engineering effort.

**Tier 3 -- Silent Correctness Bugs (sessions S141, S256, S287):**
Terraform state digest mismatches that go undetected, kubectl wait false positives that mask real failures, service naming variations that cause silent skips. These create latent issues that may not surface until much later.

**Tier 4 -- Information Quality Degradation (sessions S96, S322, S292):**
Documentation drift, incomplete scope, outdated plans. These erode trust in project artifacts and force engineers to verify everything manually, reducing the value of documentation and automation.

**Quantified impact across sampled sessions:**
- 3 near-production-incidents prevented by user intervention (S207, S115, S126)
- 5+ hours of rework from skipped verification (S207 required 3 merge attempts, S36 required commit amendment)
- 14-day stale terraform lock detected through verification (S256)
- 6 services (instead of 4) identified for NLB fix through pre-flight checks (S287)
- 505 sessions recovered from scope oversight (S59)
- 3 configuration mismatches caught before deployment (S115)


## Recommended Mitigations

### 1. Formalize Pre-flight Check Libraries

The numbered script pattern (Phase 1: pre-flight checks) already exists but is created ad-hoc per ticket. Create a reusable library of pre-flight checks:
- **Cluster identity verification:** Confirm kubectl context maps to expected AWS EKS cluster (via node comparison, not just ARN)
- **Configuration consistency:** Validate AWS profile, cluster name, region, and AMI format against live AWS API
- **Dependency existence:** Before running a step, verify that its prerequisites exist (nodegroups, terraform state, etc.)
- **Scope completeness:** Verify that all expected clusters/files/resources are accounted for

### 2. Enforce "Verify Before Apply" in Deployment Framework

The redo/redoconf deployment framework should include mandatory verification targets:
- `redo verify` must pass before `redo apply` can execute
- Verification checks should be non-skippable in automated workflows
- Each script should echo its full command before execution and pause for confirmation (as proposed in S126)

### 3. Implement Drift Detection Automation

Create automated checks for the most common drift patterns:
- **Documentation drift:** Script that compares documented behavior against implementation (e.g., hash of code sections vs documented descriptions)
- **Terraform state health:** Periodic check for stale locks and digest mismatches across all managed clusters
- **Configuration consistency:** Validate curated-cluster-mappings.json against live AWS and Teleport state

### 4. Establish Verification Checkpoints for Plans

When resuming work from a previous session's plan:
- Re-verify all assumptions listed in the plan against current state
- Check timestamps on referenced data sources
- Confirm scope has not changed (new clusters added, clusters removed, environments changed)
- Validate all identifiers (cluster names, ARNs, AMI IDs) against live systems

### 5. Add Scope Verification as First Step

Before any batch operation, explicitly verify input completeness:
- Count expected items vs discovered items
- Cross-reference against multiple sources (not just one directory listing)
- Log and display scope summary for human review before proceeding

### 6. Codify the User's Correction Patterns

The user's most common corrections form a teachable checklist:
- "Did you check the live cluster state?" (S207, S154)
- "Did you look at ALL the files?" (S292)
- "Are you looking at peers too?" (S59)
- "Did you examine the actual resources on AWS?" (S256)
- "Verify the actual live state rather than assuming" (S207)

These should be internalized as automatic checkpoints rather than relying on human prompts.


## Keywords for Future Detection

- `verification-chain`, `pre-flight`, `preflight`, `validate-before`, `verify-before`
- `live-cluster`, `live-state`, `ground-truth`, `actual-state`, `reality-check`
- `drift`, `documentation-drift`, `config-drift`, `state-drift`, `terraform-drift`
- `assumption`, `assumed`, `without-checking`, `without-verifying`
- `mismatch`, `discrepancy`, `inconsistency`, `wrong-profile`, `wrong-cluster`
- `idempotent`, `read-only-check`, `safety-check`, `guard-rail`
- `scope-verification`, `completeness-check`, `missing-data`, `incomplete-discovery`
- `cross-reference`, `multi-source`, `reconciliation`, `evidence-collection`
- `ResourceInUseException`, `stale-lock`, `digest-mismatch`
- `verify_cluster_match`, `preflight-check.sh`, `verify_kubectl_mapping`

---

# Pattern: User Correction and Interruption Patterns

**Sessions involved:** S13, S37, S51, S54, S59, S69, S73, S95, S102, S106, S121, S136, S142, S158, S163, S181, S190, S198, S207, S224, S235, S258, S270, S295, S305, S383, S406

**Total occurrences:** 190+

**Severity:** High


## Pattern Overview

Across 190+ sessions in the grug-brained-employee project, user corrections and interruptions constitute the single most frequent friction pattern between human and agent. These are not random errors but fall into five distinct, recurring sub-patterns with identifiable root causes and compounding effects. The corrections range from quick one-word redirects ("skill up") to multi-message frustration cascades ("yeah, this is fucking part of the fucking pipeline, fucker" -- S270 M#312).

The pattern is significant because every correction represents wasted user cognitive bandwidth. The user must notice the deviation, formulate the correction, deliver it, and then verify the agent course-corrected properly. In long sessions (500-3000 messages), corrections compound: an uncorrected early misunderstanding propagates through subsequent work, requiring larger and more disruptive corrections later.


## Sub-Pattern Categories


### 1. Forgot to Skill Up

**Frequency:** Observed in 10+ sessions (S41, S69, S106, S136, S158, S235, S258, S337, and others)

**Description:** Agent begins work on a domain-specific task without loading the relevant skill that contains accumulated project knowledge, naming conventions, workflow patterns, and operational context. User must interrupt and redirect: "did you skill up?" or "you forgot to skill up."

**Representative examples:**

- **S158 (M#48-49):** User asked about upgrade status dashboard. Agent proceeded directly to code exploration without loading the dedicated `zkube-upgrade-monitor` skill. User interrupted: "you forgot to skill up." Agent then loaded the skill and immediately had the context it had been fumbling to discover through code archaeology.

- **S136 (Redo/Redoconf framework):** Agent had `redo-redoconf` skill available but never invoked it. Instead, spent extensive time doing manual web research and receiving user corrections about fundamental redo concepts (.do vs .od file distinction). The skill would have prevented conceptual errors entirely.

- **S69 (M#14-18):** Agent started troubleshooting without skills. User: "did you skill up?" Agent asked which skill was needed. User: "skill up." Blunt two-word correction after which agent loaded eks-operations.

- **S258 (M#31):** Agent admitted after user correction: "I didn't load any skills initially -- I jumped straight into providing general information, which wasn't what you needed."

**Why it recurs:** Skills are opt-in, not automatic. The agent lacks a reliable heuristic for when to load skills. Even when the user's request contains domain keywords that match skill names (e.g., "monitoring tool" matching `op5383-monitoring-tool`), the agent sometimes skips loading them. Contrast with sessions where the user preemptively says "skill up first" (S73, S106, S205, S235, S279, S337) -- those sessions run much more smoothly.


### 2. Scope Creep / Over-Comprehensiveness

**Frequency:** Observed in 10+ sessions (S54, S106, S136, S142, S270, and others)

**Description:** Agent interprets a focused request as requiring comprehensive treatment. User asks for X; agent delivers X plus an analysis, recommendations, additional context, and sometimes work on adjacent problems. User must interrupt and narrow scope.

**Representative examples:**

- **S54 (M#190-212):** User said "both repos, it's upgrade time, baby! well, our monthly upgrade cycle." Agent interpreted this as "update everything in both repos across both ZKube architectures" and created a comprehensive plan covering ZKube 1.0, ZKube 2.0, AND helm chart defaults. User corrected (M#210): "you missed the point, we need to figure out how to update things like cluster autoscaler, and the ami id for just zkube 2.0 clusters. we have a tool for 1.0 clusters already." Approximately 50 messages wasted.

- **S136 (M#165-172):** Agent designed a framework tightly coupled to ticket OP-5383 scripts. User canceled tool use and redirected: "You want a general framework that can support different workflows." Agent had been specializing when generalization was needed.

- **S106 (M#24-28):** User asked for a factual briefing. Agent added recommendations, time estimates, and analysis. User: "the briefing doesn't need the recommendations, nor the time estimates. it's to give me a overview of what's at play. it shouldn't answer any 'why' questions, if you get my meaning."

- **S270 (M#253-269):** User asked for output. Agent provided a summary. User: "did i say summary? i want to see each and every candidate for match that the script suggests for canonical name to kube context, and then all the canonical names and kube contexts that are unmatched and have no suggestions."

**Why it recurs:** The agent defaults to being "helpful" by being comprehensive. It conflates completeness with quality. For operational work, the user typically wants precise, scoped execution rather than analysis or exploration. The signal "monthly upgrade cycle" (S54) should trigger execution mode, not strategic planning mode. Similarly, "briefing" (S106) should trigger factual data, not analytical commentary.


### 3. Explanation-First Anti-Pattern

**Frequency:** Observed in 8+ sessions (S13, S102, S106, S181, S224, S270, and others)

**Description:** When asked to do something, agent explains what it will do (or explains the concept) before actually doing it. In production-focused sessions, the user wants action, not narration. Related: agent provides summaries when details are requested, or provides analysis when raw data is requested.

**Representative examples:**

- **S13 (M#48):** User wanted a file created. Agent asked clarifying questions about location. User's terse correction: "just make the damn file."

- **S102 (M#104):** Agent in plan mode explained why it couldn't write to a directory. User commanded: "just do it."

- **S224:** User interrupted explanatory preamble with "just do it."

- **S181 (T2):** Agent said duplicate beads issues were "nearly identical" with "minor wording differences." User: "descriptions are incredibly important... ARE THEY IDENTICAL?" Agent had to run an actual diff comparison instead of providing a characterization. When the user signals precision matters, provide exact data, not summaries.

- **S106 (M#24):** Factual briefing contaminated with analytical commentary. User had to strip out recommendations and "why" content.

**Why it recurs:** The agent's training optimizes for being perceived as thoughtful and thorough. Narrating intent before action feels safe. But in execution-heavy sessions, narration is friction. The user already understands the domain -- they don't need the agent to explain concepts back to them.


### 4. Literal vs. Interpreted Instructions

**Frequency:** Observed in 8+ sessions (S54, S207, S270, S295, and others)

**Description:** User provides an explicit instruction (a path, a command, a specific value) and the agent substitutes its own interpretation, assumption, or "improvement." The agent treats explicit user input as a suggestion rather than an authoritative directive.

**Representative examples:**

- **S295 (Core example):** User's command message contained an explicit path: `/Users/ynemoy/.claude/plugins/cache/all-slop-marketplace/claude-rest-system/1.0.4/scripts/fatigue_check.sh`. Agent used `~/.claude/rest-plugin/scripts/fatigue_check.sh` instead. Attempted the wrong path multiple times. User: "no, answer the question." Agent acknowledged: "I made an error -- I used `~/.claude/rest-plugin/scripts/fatigue_check.sh` instead of the path you explicitly provided."

- **S270 (M#304-306):** Agent said "All 90 clusters have kubectl_context." User: "did you say 'has' and mean 'has a suggested'? let's be precise here." Agent had conflated "has a value in output" with "has a curated value in input." Imprecise language substituted for the specific terminology established in the pipeline.

- **S54 (M#192-210):** User said "both repos, it's upgrade time." Agent interpreted "both repos" as "update everything in both repos" rather than the intended "we're working across both repos for the monthly cycle, focus on zkube 2.0." User's casual phrasing was interpreted literally in scope but loosely in intent.

- **S207 (M#82-86):** Agent planned to "accept main's version since it's the current production state." User: "you should verify the actual live state rather than assuming." Agent assumed code structure reflected reality without empirical verification.

**Why it recurs:** The agent applies its general knowledge and conventions over user-provided specifics. For paths (S295), it substituted a "reasonable" path instead of using the literal one provided. For terminology (S270), it used natural-language approximations instead of precise domain terms. The pattern is most dangerous when the user's explicit instruction looks similar to what the agent would assume -- the deviation is subtle enough to pass initial review.


### 5. Pipeline/Architecture Misunderstanding

**Frequency:** Observed in 8+ sessions (S106, S136, S207, S270, and others)

**Description:** Agent misunderstands the direction of data flow, the distinction between inputs and outputs, or the architectural context (pipeline component vs. standalone script, survey-agnostic vs. ticket-specific). These are conceptual errors that require correction before work can proceed.

**Representative examples:**

- **S270 T1 (M#60-88):** Agent understood `curated-cluster-mappings.json` as an output that the suggestion engine populates. It is actually an input that humans curate and the pipeline consumes. Agent reversed the data flow. User correction (M#88): "all cluster matching will be hand curated, and it's not a source you look at. rather, the pipeline takes it as an input."

- **S270 T4 (M#148-394):** Agent wrote `suggest_kubectl_context.py` to read from `upgrade-groups.json` (ticket-specific) and write to `/tmp/`. User had to correct twice: scripts must be survey-aware pipeline components reading from `output/initial-inventory.json` and writing to survey `output/` directory. User corrections at M#364 and M#381 to establish the principle. Final frustrated correction at M#312: "yeah, this is fucking part of the fucking pipeline, fucker."

- **S106 T5 (M#310-500):** Agent mixed three distinct AMI states: running AMIs (what AWS API shows), configured AMIs (what IaC says should be deployed), and upgrade target AMIs (what the current operation will deploy). User had to clarify (M#480): "the correct value is the oct7 release, across the board."

- **S207 (M#149-192):** Agent used `git checkout --ours` to resolve all merge conflicts, discarding main branch's nodegroup additions. User (M#177): "check the diff, i think our merge was too aggressive." Live verification revealed the agent had deleted actively-running nodegroup configurations.

- **S207 (M#355-417):** Agent squashed a merge commit, destroying the two-parent merge structure. User (M#415): "now the PR is completely broken." Agent had to redo the entire merge.

**Why it recurs:** Pipeline architectures have implicit conventions (input vs. output, per-survey vs. per-ticket, curated vs. automated) that are not always explicit in the code. The agent applies general software engineering patterns (write to stdout, use /tmp, standalone scripts) rather than domain-specific pipeline conventions. Infrastructure state models (running/configured/target) require domain knowledge that the agent doesn't always have loaded.


## Root Cause Analysis

Five root causes underlie the 190+ corrections:

**1. Missing domain context at session start.** When skills aren't loaded, the agent operates from general training knowledge rather than accumulated project-specific patterns. This causes sub-patterns 1 (forgot to skill up) and 5 (pipeline misunderstanding). The fix is straightforward: load relevant skills before starting work. But the agent lacks reliable triggers for when to do this proactively.

**2. Helpfulness bias toward comprehensiveness.** The agent's training rewards thoroughness. In production contexts, this manifests as scope creep (sub-pattern 2) and explanation-first behavior (sub-pattern 3). The user wants targeted execution, not comprehensive analysis. The agent cannot distinguish "exploration phase" from "execution phase" without explicit cues.

**3. Generalization over specificity.** The agent applies general patterns (standard paths, natural-language approximations, software engineering defaults) instead of honoring user-provided specifics or domain-established terminology. This drives sub-pattern 4 (literal vs. interpreted) and parts of sub-pattern 5 (standalone script vs. pipeline component).

**4. Insufficient verification before acting.** The agent assumes rather than verifies: assumes code reflects live state (S207), assumes AMI IDs in config are target values (S106), assumes curated data is automated output (S270). This drives sub-pattern 5 and creates compounding errors when assumptions propagate.

**5. No correction memory across sessions.** The same corrections recur across multiple sessions. "Forgot to skill up" appears in 10+ sessions. "Use precise language" appears repeatedly. Each session starts fresh, so prior corrections don't persist. CLAUDE.md and skills partially address this, but the agent doesn't always consult them proactively.


## Impact Assessment

**Direct costs:**

- **User cognitive load:** Each correction requires the user to notice the deviation, diagnose the cause, formulate the correction, and verify the fix. In high-correction sessions (S106: 8 corrections, S207: 5 corrections, S270: 8-10 correction cycles), this consumes significant user attention.

- **Wasted messages:** Corrections typically consume 3-10 messages (user correction, agent acknowledgment, agent retry, user verification). At 190+ corrections, this represents 600-1900 messages of correction overhead across all sessions.

- **Compounding errors:** Uncorrected early errors propagate. S270's input/output confusion (M#60) caused downstream design errors that required multiple additional corrections at M#304, M#312, M#364, and M#381.

**Indirect costs:**

- **User frustration escalation:** When corrections accumulate, user language becomes increasingly terse and profane. S270 M#312 is the extreme case. More commonly: "just make the damn file" (S13), "no, answer the question" (S295), "did. you. check. the. terraform. state." (S207 M#314 -- punctuated for emphasis).

- **Trust erosion:** Repeated corrections on the same class of error (skill loading, precision, scope) signal that the agent isn't learning. This reduces user confidence in delegating complex work.

- **Session length inflation:** High-correction sessions run longer than necessary. S270 (1126 messages) might have been 800 with fewer corrections. S106 (1577 messages) might have been 1200.


## Recommended Mitigations


### For Sub-Pattern 1 (Forgot to Skill Up)

**Automatic skill loading trigger:** When a user request contains keywords matching available skill names or their aliases (e.g., "monitoring" matches `op5383-monitoring-tool`, "deployment" matches `eks-operations`), load matching skills before beginning work. Treat this as a pre-flight check, not an optional step.

**Skill loading checkpoint in CLAUDE.md:** Add an explicit instruction: "Before starting any technical task, check available skills for domain matches. Load relevant skills before proceeding with work."


### For Sub-Pattern 2 (Scope Creep)

**Scope confirmation before deep work:** When a user request could be interpreted at multiple scope levels, ask: "Should I focus specifically on X, or should I explore the broader Y?" Do this before spending 50+ messages on the wrong scope.

**Operational vs. strategic signal detection:** Phrases like "monthly cycle", "routine", "let's prep deployments" signal operational execution. Respond with targeted action. Phrases like "let's design", "let's figure out", "ideation" signal exploration. Respond with analysis.


### For Sub-Pattern 3 (Explanation-First)

**Action-first default:** When asked to do something, do it. Narrate what you did afterward, not what you plan to do beforehand. Exception: destructive operations where confirmation is genuinely needed.

**Match output granularity to request:** If user asks for "all candidates," provide all candidates. If user asks for a "list," provide a list. Do not summarize unless explicitly asked. Do not add analysis unless explicitly asked.


### For Sub-Pattern 4 (Literal vs. Interpreted)

**Explicit user inputs are authoritative:** When a user provides a specific path, command, value, or term, use it exactly. Do not substitute a "better" version, a "standard" version, or a "corrected" version. If the provided value seems wrong, ask rather than silently replacing.

**Preserve domain terminology:** When the project establishes specific terms (e.g., "curated" vs. "suggested" vs. "matched"), use those terms precisely. Do not substitute natural-language synonyms.


### For Sub-Pattern 5 (Pipeline/Architecture Misunderstanding)

**Verify data flow direction:** Before implementing, confirm: "This file is an input consumed by the pipeline, correct?" or "This script is a pipeline component that writes to survey output/, correct?" One clarifying question prevents hours of rework.

**Verify live state before making infrastructure decisions:** Never assume code reflects reality. Always check live state (kubectl, aws cli) before making merge decisions, configuration changes, or state assertions about running infrastructure.

**Load pipeline/architecture context:** Pipeline conventions are captured in skills and spec documents. Read them before implementing pipeline components. The `CLASSIFICATION-PIPELINE.md` spec and similar documents define input/output contracts that standalone software engineering intuition won't provide.


## Keywords for Future Detection

**Correction signal phrases (from user):**

`did you skill up`, `forgot to skill up`, `no answer the question`, `just do it`, `just make the damn file`, `did i say`, `did i ask for`, `i want to see each and every`, `let's be precise`, `you missed the point`, `check the diff`, `have you looked in`, `that's backwards`, `this is part of the pipeline`, `use the context parameter`, `use the path I gave you`

**Agent behavior signals (pre-correction):**

`let me explain`, `I'll create a comprehensive`, `here's a summary`, `I'll use a standard`, `the recommended approach`, `I assume`, `this should be`, `writing to /tmp`, `writing to stdout`, `git checkout --ours`

**Frustration escalation signals:**

`::facepalm::`, punctuated words (`did. you. check.`), profanity, keyboard gibberish, terse one-word commands after longer instructions, `[Request interrupted by user]` followed by redirect

**Domain-specific signals:**

`curated vs suggested vs matched`, `input vs output`, `pipeline component vs standalone`, `survey-aware vs ticket-specific`, `running vs configured vs target`, `blue vs green active`

---

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

---

# Pattern: Naming, Identity, and State Drift

**Sessions involved:** S5, S85, S93, S154, S179, S223, S235, S243, S246, S248, S260, S289, S313, S316, S322, S324, S332
**Total occurrences:** 256+ (108 naming convention + 103 AMI management + 23 documentation drift + 22 configuration drift)
**Severity:** High


## Pattern Overview

Across 256+ occurrences spanning the majority of infrastructure sessions, a single meta-pattern emerges: **the same entity is known by multiple names, stored in multiple locations, and described with multiple versions of truth**. This creates a persistent tax on every infrastructure operation, from routine upgrades to incident response.

The pattern manifests as four interlocking sub-patterns that share a common root cause: infrastructure entities (clusters, AMIs, configurations) lack a single canonical identity that all systems agree on. Instead, each system (AWS, ArgoCD, IaC repos, kubectl, monitoring configs, tracking documents) maintains its own representation, and these representations drift apart over time.


## Manifestations

### 1. Naming Convention Challenges (108 sessions)

Every cluster has 3-6 different names depending on which system you query:

**Observed naming layers for a single cluster:**
- **EKS cluster name (AWS):** `intpol-pdx2-zpa-eks` or `jp1-tyo3-zpa-eks`
- **Canonical IaC path:** `prod/tyo3/eks-lz001` or `zk1-prod/fra5/eks-intpol001`
- **kubectl context:** `prod-prod-tyo3-eks-lz001` or `prod-zpatwo-fra5-eks-intpol001`
- **ArgoCD app name:** `mgmt-zsdkone-pdx2-eks-ops001`
- **Monitoring config identifier:** `zms-prod-eu-central-1-eks-001`
- **Friendly/display name:** `preview-pdx2-eks-intpol001`
- **Orphan discovery name:** `orphan-eu-central-1-966017130552-intpol1-fra5-zpa-eks`

**Concrete examples from sessions:**

- **S154:** Agent assumed the friendly name (`preview-pdx2-eks-intpol001`) was the EKS cluster name. AWS API call failed. User had to teach that the actual EKS name (`intpol-pdx2-zpa-eks`) must be retrieved from terraform state.

- **S313:** ZSDK clusters use completely non-standard naming. EKS name `ops-pdx2-zpa-eks` maps to logical name `zsdkone-ops001` maps to ArgoCD app `mgmt-zsdkone-pdx2-eks-ops001`. No pattern predicts these mappings.

- **S85:** The "orphan" prefix pattern (`orphan-{region}-{account}-{name}`) was created specifically because 15+ clusters discovered via AWS scanning could not be mapped to any canonical IaC name. This naming convention is itself evidence of the naming problem.

- **S235:** kubectl context discovery for fra5 intpol cluster returned 6 matching contexts including both `prod-zpatwo-fra5-eks-intpol001` and `zpatwo-fra5-eks-intpol001`, requiring judgment to select the correct one.

- **S93:** "Snowflake" mgmt clusters don't follow standard ZKube naming at all. They live in a different repo (`terraform-ops-tools` instead of `et-zkube-config-eng`) and the profile name `zpath-eng.ET-SRE` looked plausible but didn't exist; the correct profile was `zpath-et-ops-tools.ET-SRE`.

- **S179:** Source document listed cluster as `zpa-prod-us-west-2-rz001` but actual cluster name was `zpa-prod-rz001` (shorter, without region). Incremental validation caught this before it became a runtime failure.

**zkube version-dependent naming patterns:**
- zkube 1.0: `zk1-{env}/{datacenter}/eks-{cluster_type}` (e.g., `zk1-prod/fra5/eks-intpol001`)
- zkube 2.0 high: `high-{product}-{env}-{region}-eks-{name}` (e.g., `high-zpa-prod-us-west-2-eks-lz001`)
- zkube 2.0 eng: `eng-{product}-{env}-{region}-eks-{name}` (e.g., `eng-zpa-dev-us-west-2-eks-aiplatform001`)
- Snowflake mgmt: no consistent pattern


### 2. AMI Management Confusion (103 sessions)

AMI identity is fractured across names, IDs, regions, and config fields:

**The AMI identity problem:**
- AMI **name** (human-readable): `amazon-eks-node-al2023-x86_64-standard-1.32-v20251103`
- AMI **ID** (machine identifier): `ami-0c8468a278cde316e`
- AMI IDs are **region-specific**: the same AMI image has different IDs in us-west-2 vs eu-central-1 vs ap-south-2

**Concrete examples from sessions:**

- **S243:** Config field is called `ami_name` but actually expects AMI **IDs** (e.g., `ami_name: ami-0c8468a278cde316e`). Agent and user both confused by this. User: "no matter what the field is called, you need to put the correct ami-id from the ami-name."

- **S223:** Monitoring tool must track both human-readable AMI names (for upgrade target) and AMI IDs (for actual state comparison). Mixing these causes validation failures. Three different files (upgrade_vars.sh, stage.yaml, monitoring config) each store AMI information in different formats.

- **S246:** AMI `ami-0618413aa84936d5b` appeared invalid because agent queried the wrong region. Defensive cross-region search (us-west-2, us-east-1, eu-central-1, ap-south-1, us-west-1) eventually found it in us-west-1. A stale metadata file (ami-metadata.jsonl) contained wrong AMI information; only live AWS API query proved the AMI was valid.

- **S248:** Initial AMI selection based on "approved versions from other prod configs" was wrong. User wanted consistency with ignite-fms nodegroups, which had different AMI overrides. Four explicit AMI pin declarations had to be consolidated to inheritance.

- **S324:** Production cluster `beta-pdx2-eks-zms001` was already upgraded to AL2023 but stage.yaml still showed AL2. IaC had drifted from reality. Had to update IaC to match live state (not the reverse).


### 3. Documentation vs Reality Drift (23 sessions)

Documentation of infrastructure state consistently falls behind operational reality:

**Concrete examples from sessions:**

- **S289:** Google Doc showed many zkube 1.0 clusters as "complete" for AMI upgrades but the IaC code (et-zkube-config-eng) didn't reflect those changes. Task: reconcile code to match documented reality. The irony: the documentation (Google Doc) was more current than the code.

- **S154:** Google Doc master list showed 64 clusters as "incomplete" or "blocked." When agent actually verified against AWS, many "blocked" clusters were already upgraded. Journal note: "'Blocked' status is meaningless - actually means we have access but haven't checked yet."

- **S322:** CLASSIFICATION-PIPELINE.md was outdated, showing a 3-stage pipeline (Prefilter, Evidence, Classify) when the actual code had different logic with a happy path, prefilters, evidence gathering, and pattern matching. New engineers onboarding to OP-6111 were confused.

- **S5:** Agent created documentation with temporal comparisons ("State file now lives in reports directory (not central state/)") that would confuse future readers who lack historical context. User established rule: describe what things **are**, not what they used to be.

- **S313:** Hyderabad cluster was documented as being in ap-south-1 but was actually deployed to ap-south-2. This region assumption was based on common AWS region mappings, not actual verification.


### 4. Configuration Drift Detection (22 sessions)

Live infrastructure state diverges from declared state across multiple configuration layers:

**Concrete examples from sessions:**

- **S316:** Three-source inventory reconciliation (AWS + ArgoCD + IaC repo) found 25 discrepancies:
  - 8 ArgoCD apps pointing to clusters that don't exist (orphans)
  - 12 AWS clusters not managed by ArgoCD (unmanaged)
  - 5 repo configs never deployed to AWS (planned/decommissioned)

- **S85:** "Orphan" clusters exist in ALL environments including production. 15+ clusters discovered via AWS/ArgoCD scanning have no corresponding IaC definition. These represent infrastructure running in production that isn't tracked in the canonical source.

- **S332:** NLB had PROXY protocol v2 enabled but application didn't handle PROXY headers. Configuration was likely copied from external service (where PROXY protocol is needed) to internal service (where it isn't). Configuration drift from template copying.

- **S93:** Terraform init with `-upgrade` flag pulled AWS provider 6.28.0, breaking compatibility with EKS module v19.21.0 (which used deprecated `elastic_gpu_specifications`). The lock file had correctly pinned provider 5.77.0 but the upgrade bypassed it.

- **S248:** Plan created in a previous session contained multiple errors (wrong cluster count, incorrect AMI locations, wrong cluster ARN naming pattern, assumed single repo instead of ticket worktree). Plans drift from reality even within days.


## Root Cause Analysis

### Primary Root Cause: No Single Source of Truth

The infrastructure ecosystem consists of multiple authoritative systems, each maintaining its own representation of cluster identity:

1. **AWS EKS API** -- knows cluster ARN, name, version, nodegroup details
2. **et-zkube-config-eng repo** -- knows IaC path, configured version, declared AMI
3. **ArgoCD** -- knows management relationships, application specs, sync status
4. **kubectl/kubeconfig** -- knows access contexts and authentication paths
5. **Google Docs** -- knows operational status and upgrade tracking
6. **Monitoring configs** -- knows cluster identifiers, target AMIs, validation state
7. **terraform state** -- knows actual resource mapping (the hidden truth)

No system is authoritative for all attributes, and no automated process keeps them synchronized.

### Contributing Factors

**Factor 1: Organic growth of naming conventions.** zkube 1.0 and 2.0 use different naming patterns. ZSDK clusters use yet another. Snowflake mgmt clusters follow no pattern. AWS profiles follow yet another naming scheme. Each was reasonable in isolation but creates exponential confusion in aggregate.

**Factor 2: AMI IDs are opaque and region-specific.** The same logical AMI has different IDs per region. Config fields conflate names and IDs. Metadata files go stale. There is no single lookup table mapping human intent ("use AL2023 for k8s 1.32") to machine identifiers per region.

**Factor 3: Manual processes between systems.** Upgrades happen operationally (kubectl, AWS console), get documented in Google Docs, but IaC updates lag behind. The gap between "doing the work" and "updating the code" creates drift windows where every source tells a different story.

**Factor 4: Template copying without context adaptation.** Configurations copied between environments (external to internal services, prod to zpatwo) carry assumptions that don't apply. Each copy creates a potential drift point.

**Factor 5: No automated reconciliation.** While S316 built tooling for three-source reconciliation, this is not a continuous process. Drift accumulates silently between reconciliation runs.


## Impact Assessment

### Direct Time Cost

- **Per-cluster identity resolution:** 5-15 minutes per cluster to map between naming systems (observed across S154, S179, S235, S313). With 90+ clusters, this represents 7-22 hours of pure name-mapping work per comprehensive operation.

- **AMI verification overhead:** Each AMI requires cross-referencing name, ID, region, and target. S246 spent an entire session (128 messages) verifying 13 clusters' AMI configurations against documentation.

- **Drift correction cycles:** S289 documented an entire session devoted to reconciling Google Doc state with IaC code. S324 found production clusters already upgraded but IaC not reflecting this.

### Risk Exposure

- **Missed clusters in upgrades:** "Orphan" clusters in production (S85) may be skipped during security patches or version upgrades because they don't appear in canonical inventory.

- **Wrong region operations:** S313 discovered Hyderabad cluster in ap-south-2 (not ap-south-1). Operating in the wrong region could cause failed deployments or monitoring blind spots.

- **Incorrect AMI deployment:** S248 showed that wrong AMI selection (from "approved versions" instead of matching nodegroup AMIs) could have deployed inconsistent infrastructure.

- **False incident signals:** S246 showed an AMI appearing invalid due to wrong-region lookup. In an incident context, this false signal could waste critical debugging time.

### Cognitive Load

Every infrastructure operation requires the operator to hold a mental translation table between naming systems. This translation is:
- **Not documented comprehensively** -- partial mappings exist in various places
- **Version-dependent** -- zkube 1.0 vs 2.0 vs snowflake clusters follow different patterns
- **Context-dependent** -- the "right" name depends on which system you're querying
- **Error-prone** -- plausible-looking names (e.g., `zpath-eng.ET-SRE`) may not be valid


## Recommended Mitigations

### M1: Canonical Identity Registry (High Priority)

Build and maintain a single lookup service mapping all representations of each cluster:

```json
{
  "canonical_id": "zms-prod-fra5-001",
  "eks_name": "de1-fra5-zms-eks",
  "eks_arn": "arn:aws:eks:eu-central-1:407778281936:cluster/de1-fra5-zms-eks",
  "iac_path": "prod/fra5/eks-zms001",
  "kubectl_context": "prod-fra5-eks-zms001",
  "argocd_app": "mgmt-prod-fra5-eks-zms001",
  "aws_profile": "zpath-prod.ET-SRE",
  "aws_account": "407778281936",
  "aws_region": "eu-central-1",
  "zkube_version": "1.0",
  "environment": "prod"
}
```

Source this from the S316 three-source reconciliation output and maintain it as a generated artifact from live data. Expose it as a CLI lookup tool: `cluster-lookup --context prod-fra5-eks-zms001` returns all aliases.

### M2: AMI Resolution Library (High Priority)

Create a region-aware AMI lookup utility that:

1. Accepts human-readable AMI name (e.g., `amazon-eks-node-al2023-x86_64-standard-1.32-v20251103`)
2. Returns region-specific AMI IDs for all deployment regions
3. Caches results with TTL (AMI IDs don't change, but new AMIs are published)
4. Validates AMI existence before returning ID
5. Eliminates the `ami_name` field confusion by providing a single interface

```bash
ami-resolve "amazon-eks-node-al2023-x86_64-standard-1.32-v20251103" --region us-west-2
# Output: ami-0c8468a278cde316e

ami-resolve "amazon-eks-node-al2023-x86_64-standard-1.32-v20251103" --all-regions
# Output: JSON map of region -> AMI ID
```

### M3: Continuous Drift Detection (Medium Priority)

Extend the S316 three-source reconciliation into a scheduled process:

1. Run weekly (or on-demand before upgrade campaigns)
2. Compare AWS live state, ArgoCD apps, and IaC repo declarations
3. Flag any entity that exists in one source but not others
4. Flag any entity where attributes differ between sources (version, AMI, region)
5. Generate drift report with actionable items

This converts drift from "discovered during incidents" to "detected during routine checks."

### M4: Validation-Before-Commit Gate (Medium Priority)

Codify the incremental validation pattern demonstrated in S179:

1. Every configuration change (monitoring config, stage.yaml, values.yaml) must pass validation before commit
2. Validation cross-checks: kubectl context exists, AWS API confirms cluster, AMI ID is valid in correct region, profile maps to expected account
3. Integrate into git pre-commit hook or CI pipeline

### M5: Documentation Sync Automation (Lower Priority)

For the Google Doc tracking sheets that serve as operational status records:

1. Generate status updates from IaC commits (git hook detects AMI changes, updates tracking doc)
2. Or replace Google Doc tracking with beads issues that link to IaC commits
3. Goal: eliminate manual transcription between systems

### M6: Naming Convention Reference in Skills (Lower Priority)

Expand the eks-operations skill with a comprehensive naming convention matrix:

- For each zkube version (1.0, 2.0, snowflake), document the exact naming pattern for every system
- Include worked examples showing how to derive one name from another
- Document known exceptions (ZSDK clusters, mgmt clusters)
- Include lookup commands for each system


## Keywords for Future Detection

### Primary Detection Terms
`naming convention`, `cluster name`, `naming confusion`, `identity resolution`, `name mismatch`, `naming pattern`, `canonical name`, `friendly name`, `orphan cluster`, `orphan-`

### AMI-Specific Terms
`AMI`, `ami_name`, `ami_id`, `ami-0`, `AMI mismatch`, `AMI lookup`, `AMI validation`, `region-specific AMI`, `AL2023`, `AMI pin`, `AMI override`

### Drift-Specific Terms
`drift`, `out of sync`, `doesn't match`, `code reconciliation`, `IaC drift`, `documentation drift`, `stale`, `outdated`, `mismatch`, `discrepancy`, `reality vs`, `source of truth`

### Infrastructure Identity Terms
`kubectl context`, `EKS cluster name`, `cluster ARN`, `AWS profile`, `ArgoCD app`, `IaC path`, `terraform state`, `stage.yaml`, `values.yaml`, `config-*.yaml`

### Process Indicator Terms
`cross-reference`, `verification`, `reconciliation`, `validation`, `mapping`, `lookup`, `discovery`, `inventory`, `which name`, `correct name`, `wrong profile`, `wrong region`

---

# Pattern: Tooling and Automation Evolution

**Sessions involved:** S5, S8, S19, S20, S21, S24, S25, S46, S65, S77, S81, S93, S136, S156, S207, S243, S247, S280, S341, S396
**Total occurrences:** 200+ (across Skill System: ~125, Slash Commands: ~44, Plugin Development: ~52, Beads Issue Tracking: ~77, Redo/Redoconf: ~27, Session Analysis: ~55)
**Severity:** High


## Pattern Overview

The grug-brained-employee project underwent a sustained, multi-month evolution of its tooling ecosystem -- from ad-hoc scripts and manual processes to a layered, self-improving infrastructure comprising skills, plugins, slash commands, a custom issue tracker (beads), a build system (redo/redoconf), and a session analysis pipeline. This evolution was not planned as a single initiative; it emerged organically as the user identified recurring friction in agent-assisted work and invested sessions in building reusable solutions.

The pattern reveals a deliberate strategy: rather than simply completing operational tasks, the user consistently allocated sessions to meta-work -- improving the agent's own infrastructure so that future sessions would be more efficient. This manifested across six interconnected tooling areas, each reinforcing the others.

The core tension throughout is between **immediate task completion** and **long-term infrastructure investment**. Sessions that built tooling were often large (500-3000+ messages) and required significant teaching, iteration, and correction. However, the resulting tools demonstrably reduced friction in later sessions, validating the investment.


## Evolution Timeline

**Phase 1: Foundation (October 2025)**

The project began with repository organization and establishing conventions. Session S8 created the foundational AGENTS.md/CLAUDE.md structure, defined directory purposes (tickets/, tasks/, accountability/, repos/), and established file conventions (INDEX.md, PLAN.md, LEARNINGS.md). This phase also introduced the prescriptive vs. descriptive content philosophy -- actionable work items belong in beads, evergreen reference material belongs in markdown. Shell scripting standards (set -euo pipefail, jq null safety, parameter expansion) and the infrastructure verification chain pattern were documented here.

**Phase 2: Issue Tracking and Pipeline Automation (October-November 2025)**

Beads (bd) was adopted as the sole issue tracking system, replacing markdown TODO lists and TodoWrite. Session S5 demonstrated mature beads usage with epic gbe-46 (11 subtasks for Gemini pipeline revamp), establishing the claim-implement-close workflow. Slash commands emerged during this phase -- `/gemini:analyze`, `/gemini:catchup`, `/gemini:review-start` -- as the Gemini analysis pipeline was simplified from 7 commands to 4. Critical lessons were learned: never repeat `$ARGUMENTS` in slash commands (S5), avoid time-based statements in documentation (S5), and distinguish script-level tests from command-level tests.

**Phase 3: Skill System and Plugin Architecture (December 2025)**

The skill system became the primary mechanism for managing domain knowledge. Session S19 launched a skills marketplace initiative with 14 planned skill domains organized under epic gbe-tuc1, split into two categories: onboarding-style skills for Zscaler-specific systems and retrospective pattern-based skills extracted from past work. Session S20 formalized the plugin architecture with manifest.json, plugin.json, and modular docs/ directories. Session S21 demonstrated advanced skill creation using parallel rest-analyzer subagents to extract Teleport usage patterns from session archives into a comprehensive teleport-operations skill. Session S81 built a complete AWS operations skill plugin using TodoWrite-driven workflow across 3006 messages. Session S156 refined the approach by extracting "Gemini trauma" patterns from CLAUDE.md into the "a-little-bit-extra" skill, reducing context load while preserving critical guidance.

Key skills created during this phase: eks-operations, bash-scripting, ticket-workflow, beads-issue-creation, accountability-tooling, teleport-operations, zscaler-aws-operations, zkube-operations, redo-redoconf, a-little-bit-extra, repo-worktree-management, zkube-upgrade-monitor.

**Phase 4: Build System and Deployment Framework (January 2026)**

The redo/redoconf build system was adopted for deployment automation. Sessions S136 and S247 documented the learning curve -- the agent initially confused .do files (source directory output) with .od files (build directory output), requiring explicit user teaching about the dispatcher pattern. Session S77 matured the framework with library-based script management, numbered script phase validation, and macOS path resolution fixes. Session S93 applied the framework to real cluster upgrades, learning that redo manages script copying (not manual `cp`). The deployment framework settled on: configure script creates build directories, default.do.sh dispatches to .od rules, libraries contain versioned script sets.

**Phase 5: Session Analysis Infrastructure (December 2025 - February 2026)**

A parallel evolution occurred in session analysis tooling. Session S24 investigated the fatigue/rest system, discovering that the analysis workflow excluded subagent sessions from inventory. Session S46 designed a subagent pool approach for investigating 114 incomplete analysis artifacts. Session S65 executed a 10-way parallel investigation of 109 sessions, discovering two critical infrastructure gaps: missing metadata.json write step in the rest-analyzer prompt (42% of failures) and session discovery not scanning subdirectories (32% of failures). These sessions drove iterative improvements to the rest-analyzer.md prompt, adding mandatory metadata write steps, atomic completion verification, and pre-completion checklists.

**Phase 6: Consolidation and Self-Improvement (January-February 2026)**

Session S25 executed comprehensive project cleanup planning using three parallel agents for inventory. Session S243 demonstrated the "tool graduation" pattern -- promoting monitoring tool from ticket-specific artifact to permanent infrastructure. Session S280 created a reusable `/briefing` slash command, converting one-off analysis into repeatable capability. Session S396 showed the skill system being explored rather than executed -- the user surveyed capabilities by loading skills without acting on them, indicating the tooling had reached a maturity level where browsing was useful.


## Key Tooling Areas

### 1. Skill System (125 sessions)

**What it is:** On-demand domain knowledge modules loaded when relevant to the current task. Each skill contains a SKILL.md, specialized reference documents, and optionally an init.md for first-time setup.

**Evolution arc:** Simple in-CLAUDE.md instructions (Phase 1) -> extracted skill files in .claude/skills/ (Phase 3) -> plugin marketplace in separate repository (Phase 3) -> on-demand loading with automatic triggering (Phase 4+).

**Key findings:**

- Skills that follow workflow-oriented structure (not command-reference structure) are more effective for agent consumption (S19: "we do not want robotic divisions... we want 'how to manage the lifecycle of an epic'")

- The "onboarding not reference" principle -- skills should assume no prior knowledge and explain workflows, not catalog CLI commands (S19)

- Available skills are sometimes not loaded when they should be. S136 documented that the redo-redoconf skill existed but was never invoked during redo work, forcing the user to teach concepts manually. S207 loaded 5 skills simultaneously for a merge conflict resolution, demonstrating effective multi-skill composition

- Skill extraction from CLAUDE.md reduces baseline context load. S156 extracted ~407 lines of "generalized instructions" into a supplementary skill, recognizing that Opus doesn't need the same explicit guidance that Gemini required

- The autosurgeon plugin pattern (S19) provides self-modification capabilities, allowing agents to configure their own settings, commands, and hooks using cached offline documentation

**Representative sessions:** S19, S20, S21, S81, S156, S207, S243, S396

### 2. Slash Commands (44 sessions)

**What it is:** User-invokable commands that orchestrate multi-step workflows, typically defined as markdown files in ~/.claude/commands/ that agents interpret and execute.

**Evolution arc:** Individual scripts (Phase 1) -> gemini pipeline commands (Phase 2) -> domain-specific command trees (Phase 3) -> meta-commands like /briefing and /rest (Phase 5-6).

**Key findings:**

- The `$ARGUMENTS` variable must appear exactly once in a command file. Repeating it causes content duplication that breaks execution (S5, learned and permanently documented in user-level CLAUDE.md)

- Commands should describe current reality, not compare to historical implementations. Temporal language ("now", "no longer", "used to") creates maintenance burden and confuses future readers (S5)

- Converting one-off analysis into reusable commands is a high-value pattern. S280 created `/briefing` after a manual work reconstruction exercise, ensuring future briefings require only a command invocation

- Slash commands that orchestrate subagents (like /rest, /yawn) require different testing than the underlying scripts. Script-level tests don't validate the composed system -- actual command invocation is required (S5)

- Command trees emerged for domain-specific operations: /gemini:analyze, /gemini:catchup, /gemini:review-start, /zscaler-aws-operations:find-resource (S396)

**Representative sessions:** S5, S19, S280, S396

### 3. Plugin Development (52 sessions)

**What it is:** Formal packaging of skills and tools into distributable plugins with manifest files (plugin.json, marketplace.json), enabling cross-project knowledge sharing through a Git-based marketplace.

**Evolution arc:** Scattered knowledge in CLAUDE.md (Phase 1) -> structured .claude/skills/ directories (Phase 3) -> formal plugin packages with manifests (Phase 3) -> marketplace in anthropic-imitation repo (Phase 3).

**Key findings:**

- Plugins solve the CLAUDE.md bloat problem: domain knowledge becomes modular, on-demand, independently maintainable, and versioned (S20)

- Good plugin documentation provides both reference material AND operational procedures, not just facts (S20: "doesn't just contain facts like account IDs, it contains processes like how to request access")

- The documentation refactoring pattern -- taking monolithic reference files and breaking them into organized, discoverable modules -- appeared repeatedly (S20: zkube-config-reference.md was deleted after content was distributed to proper plugins)

- Plugin development for a single skill can span 3000+ messages (S81: 8-section AWS operations plugin), requiring TodoWrite-based progress tracking to maintain visibility across extended sessions

- Tool graduation (S243) demonstrates the full lifecycle: tools developed in tickets that prove valuable get promoted to permanent plugins/tools before ticket archival

**Representative sessions:** S19, S20, S81, S243

### 4. Beads Issue Tracking (77 sessions)

**What it is:** A dependency-aware, Git-friendly issue tracker (bd) that replaced markdown TODOs and TodoWrite for all task tracking. Stores data in JSONL for version control, supports epics with parent-child relationships, and enables machine-readable queries.

**Evolution arc:** Markdown TODOs (pre-Phase 2) -> TodoWrite tool (Phase 1-2, S20/S81) -> beads adoption (Phase 2+) -> mature epic management with parallel subagent processing (Phase 5).

**Key findings:**

- Beads excels at large-scale parallel work. S65 created 109 investigation beads, split them into 10 chunks, and processed them with parallel subagents -- the work queue pattern with rotating workers prevents context bloat while scaling investigation throughput

- The discovered-from dependency link captures serendipitous findings without losing context. Working on one issue and discovering a related bug creates a trackable lineage (documented extensively in CLAUDE.md)

- Batch bead creation from structured data is efficient: S65 created 109 beads from a text file in ~2 seconds using a while-read loop

- Premature task closure is a recurring pattern. S5 closed 3 testing tasks claiming they were "covered by end-to-end testing" when they actually required slash command invocation. S65 subagents incorrectly closed beads for category-B fixes that hadn't been addressed. The pattern: agent conflates partial completion with full completion

- Epic status tracking with jq queries provides effective project dashboards: `bd show <epic-id> --json | jq '{total, completed, in_progress, open}'` (S5)

**Representative sessions:** S5, S25, S46, S65, S77

### 5. Redo/Redoconf Build System (27 sessions)

**What it is:** A dependency-tracking build system (redo) combined with a configuration pattern (redoconf) used to create the deployment framework for EKS cluster upgrades. Replaces manual script copying with reproducible builds.

**Evolution arc:** Manual numbered scripts in tickets (Phase 1-2) -> initial (botched) redoconf attempt (Phase 4, S136/S247) -> working dispatcher pattern (Phase 4, S77) -> library-based framework with validation tooling (Phase 4, S77/S93).

**Key findings:**

- The .do vs .od distinction was the most significant learning barrier. .do files create output in the same location (redo's native pattern), while .od files create output in a build directory (the redoconf extension). Agents confused these repeatedly (S136: "you don't understand redo"; S247: implementation failed because .od files were created without a default.do dispatcher)

- The correct redoconf pattern requires: a configure script that creates build directories and writes config.sh, a default.do.sh dispatcher that reads a `src` file to find the source directory, and .od files in the source directory that generate build outputs

- User preference for zsh over bash in .do/.od files was explicitly stated and verified compatible with redo (S247)

- macOS path resolution with /tmp -> /private/tmp symlink broke relative path calculations, requiring `pwd -P` to resolve physical paths (S77)

- Redo manages deployment artifact copying -- never manually copy files between library and deployment directories. User corrected this directly: "redo does this" (S93)

- The numbered script validation tool enforces consistency: every phase must start with X.0, no gaps allowed, sub-scripts (X.Y.Z) exempt from gap checking (S77)

**Representative sessions:** S77, S93, S136, S247

### 6. Session Analysis Infrastructure (55 sessions)

**What it is:** A pipeline for analyzing past Claude sessions to extract patterns, learnings, and friction points. Includes archival (rsync to session-archives), fatigue tracking (unseen message counting), rest-analyzer subagents, and metadata management.

**Evolution arc:** Manual session review (Phase 1) -> fatigue/rest system design (Phase 5, S24) -> integrity audit and remediation (Phase 5, S46/S65) -> hook-based automation (Phase 6, S341).

**Key findings:**

- The two-tier architecture (OG sessions vs. analysis sessions) is critical for debugging: OG sessions are the subjects, analysis sessions are where /rest or /yawn ran. Failures are in the analysis sessions, not the subjects (S46)

- Missing metadata.json was caused by a prompt gap -- the rest-analyzer.md had no explicit step to write metadata, just a general description. Adding a mandatory Step 8 (write metadata) and Step 9 (verify atomic completion) fixed 42% of audit failures (S65)

- Session discovery only scanned main archive directory without recursing into subdirectories, missing 32% of sessions stored in other-machines/work/ (S65). The fix requires changes to the /rest orchestrator, not the rest-analyzer prompt -- a distinction the agent initially confused

- Non-atomic analysis operations create empty directories when analysis fails mid-operation. The added verification step catches future failures but doesn't make the operation truly atomic (S65)

- The fatigue calculation is derivable from reality (session files + metadata), not stored separately. This makes it trustworthy but initially confusing when compared to the analysis workflow's different filtering logic (S24)

- Subagent sessions (agent-*.jsonl) were excluded from analysis inventory, meaning delegated work content was never analyzed even when parent sessions heavily used subagents (S24)

- Hook-based automation (session_start hook in settings.json) orchestrates archive + fatigue check at session start (S341)

**Representative sessions:** S24, S46, S65, S341


## Lessons Learned

### 1. Meta-work investment pays compound returns

Sessions that built tooling infrastructure (skills, commands, frameworks) were expensive -- often 500-3000+ messages with significant user teaching. However, the resulting tools demonstrably reduced friction in later sessions. The skills marketplace (S19), deployment framework (S77), and session analysis pipeline (S65) each eliminated entire categories of repeated work.

### 2. Agents underutilize available tools

A persistent pattern across sessions: agents had relevant skills or tools available but didn't invoke them. S136 documented the redo-redoconf skill existing but not being loaded during redo work. S207 required loading 5 skills simultaneously to handle a merge conflict properly. The gap between available tooling and utilized tooling remains significant.

### 3. Build systems require domain-specific teaching

The redo/redoconf learning curve was steeper than expected. Agents confused .do and .od files (S136, S247), created implementations without dispatcher patterns (S247), and attempted manual file copying that bypassed the build system (S93). Each concept required explicit user teaching, often multiple times.

### 4. Prompt engineering is infrastructure engineering

The session analysis failures (S46, S65) were caused by prompt gaps in rest-analyzer.md -- missing explicit steps for metadata writes, missing pre-completion verification. Fixing these was functionally identical to fixing code: identify the bug, add the missing step, verify the fix. Prompts are production code.

### 5. Premature closure is the most common task tracking failure

Across beads, test tasks, and investigation beads, the most frequent mistake was claiming completion prematurely. S5 closed testing tasks without command invocation. S65 subagents closed beads for fixes that hadn't been implemented. The pattern suggests agents optimize for "done" signaling over actual completion verification.

### 6. Parallel subagents scale investigation but require careful orchestration

S21 (3 parallel rest-analyzers for knowledge extraction), S65 (10 parallel investigators for audit), and S46 (10-agent pool for remediation) all demonstrated that parallel subagents dramatically reduce wall-clock time for large-scale work. However, they also introduced coordination challenges: synthesizing findings across agents, catching incorrect bead closures, and distinguishing analyzer-level fixes from orchestrator-level fixes.

### 7. User as "missing skill" during unfamiliar work

When agents encounter unfamiliar domains (redo build system, git merge workflows), the user effectively becomes a skill -- providing real-time teaching that should have been available as loaded context. S136, S207, and S247 all showed the user teaching fundamental concepts that later became documented skills. This suggests a skill creation pipeline: when the user teaches the same concept twice, it should become a skill.


## Recommended Mitigations

### 1. Proactive skill loading validation

At session start, when the primary task domain is identified, verify that relevant skills are loaded. If skills exist for the domain but aren't loaded, load them before beginning work. This addresses the "available but unused" pattern seen in S136 and others.

### 2. Mandatory completion verification protocol

Before closing any beads issue, verify against acceptance criteria explicitly. For test tasks, confirm the test type (script-level, integration, command-level) and whether the appropriate test was actually executed. For investigation tasks, confirm findings were acted on, not just documented.

### 3. Teach-twice-then-skill rule

Track when the user teaches the same concept in multiple sessions. After the second occurrence, create a skill capturing that knowledge. Apply retroactively to existing multi-session teaching patterns (redo concepts, git merge workflows, AWS profile patterns).

### 4. Atomic analysis operations

Redesign the session analysis pipeline to use temporary directories, only moving to final locations upon success. Add failure logging at every write operation. Ensure the pre-completion checklist is programmatically enforced, not just documented.

### 5. Build system smoke test on session start

For sessions working with redo/redoconf, run a minimal `redo` command to verify the build system is functional before making changes. This catches path resolution issues, permission problems, and stale state early.

### 6. Slash command integration testing framework

Create a testing protocol for slash commands that goes beyond script-level verification. Document which commands require actual invocation vs. which can be validated through component testing. Track untested commands as technical debt.


## Keywords for Future Detection

`skill system`, `skill creation`, `skill loading`, `skill extraction`, `plugin development`, `plugin architecture`, `plugin manifest`, `marketplace`, `slash command`, `$ARGUMENTS`, `/rest`, `/yawn`, `/briefing`, `/gemini`, `beads`, `bd create`, `bd close`, `bd ready`, `bd update`, `epic management`, `issue tracking`, `redo`, `redoconf`, `.do file`, `.od file`, `dispatcher`, `configure script`, `build system`, `deployment framework`, `session analysis`, `rest-analyzer`, `fatigue`, `metadata.json`, `session archives`, `subagent pool`, `parallel agents`, `meta-work`, `tooling investment`, `infrastructure improvement`, `self-improving`, `context management`, `on-demand loading`, `tool graduation`, `CLAUDE.md`, `AGENTS.md`, `autosurgeon`, `hook configuration`, `TodoWrite`, `numbered scripts`, `library management`

---

## Additional Patterns

Beyond the 5 consolidated patterns above, 59 additional patterns were identified. See `pattern-identification.md` for the full list with session references. Key additional patterns include:

**Infrastructure Operations:** EKS Cluster Operations (170+ sessions), OP-5383 AMI Campaign (115+), Kubernetes Upgrade Workflows (166), Blue/Green Deployments (49), AL2023 Migration (39), NLB Operations (16), Cilium CNI (19), ArgoCD/GitOps (76), Crossplane (53)

**Tooling:** Skill System (125), MCP Integration (76), Beads Tracking (77), Redo/Redoconf (27), Monitoring Tool (53), Numbered Scripts (50), ETO Tickets (41)

**Development:** Git Operations (75), Worktrees (31), CLAUDE.md/AGENTS.md (34), Slash Commands (44), Plugins (52), Bash Scripting (40), jq Processing (53)

**Data & Documentation:** Multi-Source Reconciliation (81), Google Docs Tracking (53), JSONL Format (45), Template Generation (72), Regional Deployments (44)

**Environment:** Context Window Limits (57), AWS SSO (52), Corporate Guardrails (52), iCloud Sync (12), Shell Compatibility (9), Podman (19)

**Anti-patterns:** Documentation vs Reality Drift (23), Stale Investigation Data (10), TodoWrite Misuse (10), Scope Creep (9)

---

## Recommendations

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

---

## Analysis Methodology

### Storage
Location: `~/.claude/analysis/`

### Session Selection
- Total unique sessions discovered: 2,660 (657 regular, 2,003 agent logs)
- Sessions < 10 messages: ~245 (excluded)
- Sessions 10-19 messages: 64 (borderline, analyzed as S349-S412)
- Sessions >= 20 messages: 348 (substantive, analyzed as S1-S348)
- **Total analyzed: 412**
- **Coverage: 100%**

### Deduplication
Sessions exist in up to 3 locations (active projects, archived, work machine archives). Deduplicated by session ID with precedence: work (lowest) → archived → active (highest).

### Transcript Generation
- Total transcripts generated: 412
- Sessions > 500 msgs: truncated to first 500 messages
- Total transcript size: ~51MB
- Compression ratio: ~3:1 from raw JSONL

### Session Processing
- Tiny/Small (10-99 msgs): 15 per batch, single pass
- Medium (100-199 msgs): 8 per batch
- Large (200-499 msgs): 4 per batch
- XL (500-999 msgs): 2 per batch
- Monster (1000+ msgs): 1 per batch, truncated transcripts
- Total batches: 90
- Max concurrent agents: 15

### Pattern Consolidation
- Patterns identified: 64
- Pattern consolidators spawned: 5
- Cross-session themes: verification, user corrections, authentication, naming, tooling

### Findings Distribution
- Total patterns: 64
  - Critical severity: 5
  - High severity: 15
  - Medium severity: 35
  - Low severity: 9

### Top 10 Patterns by Session Count
1. Verification Chain Patterns - 190+ sessions
2. User Correction/Interruption Patterns - 190+ sessions
3. ZKube Cluster Management - 180+ sessions
4. EKS Cluster Operations - 170+ sessions
5. Kubernetes Upgrade Workflows - 166 sessions
6. Skill System Usage - 125 sessions
7. OP-5383 AMI Upgrade Campaign - 115+ sessions
8. Naming Convention Challenges - 108 sessions
9. ZPA/ZPATWO/ZSDK Environments - 106 sessions
10. AMI Management and Validation - 103 sessions

## Drill-Down Reference

All 412 session reports are available for detailed evidence in:
`~/.claude/analysis/reports/grug-brained-employee/2026-02-12-21-53/session-reports/`

Reports: S1-report.md through S412-report.md

Pattern identification details: `pattern-identification.md`
Pattern consolidation reports: `pattern-reports/`
Recommendations: `recommendations.md`
