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
