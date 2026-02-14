# Session S2: Beads Installation and Onboarding

**Messages:** 429

**Source:** Session from grug-brained-employee project

**Date:** 2025-10-20 (based on file timestamps in transcript)


## Summary

This session documents the complete installation and configuration of Beads (Steve Yegge's issue tracking system) into the grug-brained-employee project. The session began with research to understand Beads, progressed through Homebrew installation, and culminated in a sophisticated onboarding process that established clear boundaries between descriptive and prescriptive content.

The session is particularly notable for demonstrating a "leave no trace" philosophy - keeping all Claude-specific configuration in `~/.claude/` rather than the project itself. This led to an extensive ideation phase where the agent and user collaboratively defined principles for separating task tracking (Beads) from documentation (Markdown), ultimately enriching the project's organizational philosophy with the descriptive vs prescriptive content pattern.


## Findings

### T1: Beads Installation and Formula Discovery Process

**Keywords:** homebrew, installation, web-search, tap, formula-discovery

**Description:**

The agent executed a multi-step web search strategy to find Beads installation instructions:

1. Initial confusion between three different "Beads" projects (steveyegge/beads issue tracker, magicmouse/beads-examples language, orsjb/beads audio library)
2. Progressive refinement of search queries to find Homebrew tap location
3. Discovery that `brew tap steveyegge/beads` + `brew install bd` is the correct installation path
4. Learning that the formula compiles from source with CGO enabled

**Key insight:** When the GitHub WebFetch tool failed with OAuth error, the agent adapted by using WebSearch with increasingly specific queries. This demonstrates resilience in tool failure scenarios.

**Corrections made:**
- First tried `bd --version` (failed), then corrected to `bd version`
- Initial plan assumed Beads was already installed, had to revise when realizing it was a fresh install


### T2: Leave No Trace Configuration Pattern

**Keywords:** user-level-config, project-separation, claude-agnostic, configuration-philosophy

**Description:**

The user requested all Beads configuration go in `~/.claude/CLAUDE.md` rather than the project, enforcing a "leave no trace" principle. This led to:

1. Adding comprehensive Beads documentation to user-level `~/.claude/CLAUDE.md` instead of project-level `AGENTS.md`
2. Preserving the project's AI-agnostic status (no Claude-specific traces)
3. Establishing pattern: project can reference "issue tracker" generically while user-level config specifies Beads

**Multi-step process walked through:**
1. Run `bd onboard` to get standard instructions (3 steps)
2. Adapt instructions to put content in `~/.claude/CLAUDE.md` instead of project
3. Verify Beads works with `bd ready --json` (showed 10 existing issues)

**Error corrected:** Agent initially tried to add content to project but user clarified it should go in `~/.claude/` exclusively.


### T3: Descriptive vs Prescriptive Content Philosophy

**Keywords:** content-separation, markdown-vs-beads, task-tracking-philosophy, architecture-vs-tasks

**Description:**

The /ideate session established a fundamental organizing principle:

**Prescriptive content (goes in Beads):**
- Task steps and instructions
- Acceptance criteria
- Work in progress comments
- Bug reproduction steps
- Implementation tasks
- Testing checklists

**Descriptive content (stays in Markdown):**
- Architecture documents
- Design rationale
- API documentation
- Onboarding guides
- Historical context
- Research findings
- Meeting notes (retrospective)
- Glossaries

**Edge case resolution:** Migration guides and troubleshooting docs are descriptive (evergreen reference), but become prescriptive when someone says "let's execute these steps" - then steps go into Beads for tracking.

**Pattern evolved:** Documents like PIPELINE_REVAMP_PLAN.md should be split - descriptive parts stay in Markdown doc, prescriptive implementation tasks become Beads epic with subtasks.


### T4: Beads Field Discovery and Rich Content Patterns

**Keywords:** bd-command-help, field-capabilities, acceptance-criteria, design-notes, comments

**Description:**

Agent explored `bd` command capabilities to understand how to store comprehensive task content:

**Available fields discovered:**
- `--description` - Full issue body (multi-line)
- `--design` - Design notes and technical approach
- `--acceptance` - Acceptance criteria for completion
- `--notes` - Progress updates (via `bd update`)
- `--labels` - Tags for categorization
- `--external-ref` - Links to Jira, GitHub issues, etc.
- `--deps` - Dependencies (discovered-from, blocks, parent-child, etc.)

**Comment system discovered:**
```bash
bd comments add <id> "Progress note"
bd comments add <id> -f notes.txt
bd comments <id> --json
```

**Key insight:** Comments provide granular progress tracking without cluttering issue fields. This enables pattern: use `--notes` for summary updates when changing status/priority, use comments for detailed iteration notes.

**Epic and subtask management pattern:**
- Create epic with `--type epic`
- Create subtasks with `--deps parent-child:<epic-id>`
- Track completion with `bd epic status --json`
- Close eligible epics with `bd epic close-eligible`


### T5: Project Status Reporting Pattern via Beads

**Keywords:** epic-tracking, status-reporting, jq-filtering, completion-dashboard

**Description:**

The session established patterns for tracking project status using Beads epics as organizational units:

```bash
# Get epic with all children
bd show <epic-id> --json

# Custom dashboard with jq
bd show <epic-id> --json | jq '{
  epic: .title,
  status: .status,
  total_tasks: (.dependents | length),
  completed: ([.dependents[] | select(.status == "closed")] | length),
  open_tasks: [.dependents[] | select(.status == "open") | {id, title, priority}]
}'
```

**Insight:** Epic dependencies provide natural project grouping without needing project-specific labels. Domain labels (kubernetes, aws, gemini) are more flexible for cross-cutting queries.

**Pattern documented:** Use epics for project tracking, not labels. Labels are for categorization across projects.


## Session Characteristics

**Complexity:** High - Multi-phase session spanning research, installation, onboarding, and philosophy development

**Themes:** Tool installation, configuration management, organizational philosophy, content classification

**Corrections:** 3-4 minor corrections (command flags, installation assumptions, configuration location)

**Tool diversity:** WebSearch, Bash, Edit, Read, TodoWrite, ExitPlanMode

**User interaction style:** Highly collaborative, with /ideate mode enabling deep thinking and clarification loops


## Potential Pattern Connections

1. **Tool Failure Resilience:** Connect to patterns in other sessions where WebFetch fails and agent adapts with alternative approaches

2. **User-level vs Project-level Configuration:** This "leave no trace" pattern may appear in other sessions - worth tracking as a recurring preference

3. **Content Organization Philosophy:** The descriptive/prescriptive distinction could be a reusable pattern for other projects facing documentation vs task tracking confusion

4. **Progressive Field Discovery:** Pattern of using `--help` to discover capabilities and enriching instructions iteratively appears in other tool onboarding sessions

5. **Ideate Mode for Boundary Definition:** Using /ideate to work through ambiguous organizational questions - look for similar clarification patterns in other sessions
