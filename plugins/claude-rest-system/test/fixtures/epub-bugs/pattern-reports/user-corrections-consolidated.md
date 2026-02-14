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
