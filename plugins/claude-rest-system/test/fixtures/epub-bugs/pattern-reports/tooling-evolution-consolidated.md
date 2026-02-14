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
