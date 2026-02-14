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
