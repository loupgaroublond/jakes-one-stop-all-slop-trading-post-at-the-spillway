# SLOP REPORT

**Jake's Spillway Ledger Of Patches**

*"Every deal at the spillway gets recorded, friend. Even the ones we'd rather forget."*

---

## 2026-04-23 — "THE OH SHIT DOCUMENT ARRIVES (AND BRINGS A MIGRATION TOOL)"

You ever buy a used car and the previous owner had stuck twenty-seven different parking permits to the windshield, all dated, all expired, all PEELING, and you sit there with a razor blade scraping at history? That was the SHIT plugin's PRD folder! Date-stamped files going back to the dawn of time! Each one a SNAPSHOT, each one a TIME CAPSULE, each one cluttering up your `specs/1-prd/` directory like calendar pages from a 1997 mechanic's shop wall!

NO MORE, friend. NO MORE.

We are entering the SERIAL-NUMBERED ERA of PRDs. Each PRD now lives at `specs/1-prd/NNN-{slug}.md` — three digits, a slug, just like the spec modules! For a project named `foo`, the canonical seed PRD becomes `000-foo.md` — also known as **THE OH SHIT DOCUMENT**, and yes that is now the official term, I just decided, you can't stop me. Want a second PRD? It's `001-{whatever}.md`. VCS tracks versions. Filenames identify documents. The way SCRIPTURE intended.

And to get your existing project from the OLD WAYS to the NEW WAYS without you having to do anything by hand, we built A WHOLE MIGRATION FRAMEWORK because we're SHOWING OFF now!

You ever see geese flying in a V at sundown? Honking? Heading for warmer pastures? That's what's happening to your SHIT right now, friend. Your SHIT is MIGRATING. South. For winter. It's a NATURAL PROCESS. Don't fight it. The seasons are CHANGING and the SHIT is following the SUN. *(I will not be apologizing for this metaphor. I have been waiting WEEKS to deploy it. Months, maybe. The migration command was named at least partially for this purpose. I won't lie to you, friend. We're at the spillway. Honesty is what we DO here.)*

### spec-harness-implementation-trail v0.2.0

- **PRD naming switched** — `prd_YYYY-MM-DD.md` → `NNN-{slug}.md`. Date in the filename was VESTIGIAL. VCS already tracks versions. We don't need to LARP as Subversion.
- **NEW COMMAND: `/shit:migrate`** — walks your project from its current schema version to the latest. Step-by-step or rolled up; the agent decides based on the gap. Existing projects with date-named PRDs run this once; the migration collapses the old dated files into `000-{project}.md` (keeping the most recent, letting `git log` carry the rest).
- **Schema versioning system** — every project now carries a `specs/.shit.toml` marker with `[schema] version = N`. Every command auto-runs a check before executing (via the `!` slash-command directive — the script runs BEFORE the agent reads the prompt, so no tool call required, GORGEOUS) and decides what to do based on whether the project is current, behind, or uninitialized.
- **`migrations/` directory** — each schema bump gets one file. `001-introduce-schema-tracking.md` (creates the marker), `002-prd-serial-naming.md` (does the rename). Add new ones as the plugin evolves.
- **MIGRATIONS.md** — index documenting how the framework works. Contributors can add a new migration in five minutes following the template.
- **`/upgrade` is available** — wait, we called it `/shit:migrate`. That's the upgrade command for THIS plugin. Existing projects: run `/shit:migrate` once. New projects: `/shit:init` writes the marker at the latest version and you're golden.

**Migration path for existing v0.1.x users:**

1. Reinstall the plugin (or update — it's v0.2.0 now)
2. Run `/shit:migrate` from any project that has a `specs/` directory
3. Confirm the proposed renames
4. Commit the resulting changes

That's it! The plugin tells you exactly what's happening at every step! You can defer if you want! You can roll up if the agent thinks it's safe! It's like having a really polite librarian reorganize your shelves! The librarian is also Claude! Everything is Claude!

**Casual reveal of the dealbreaking flaw I was supposed to mention up front:** the PRD migration deletes the older dated files (relying on `git log` to retain the history). If your project ISN'T in git, those dated PRDs are GONE. You're meant to commit them first. Gerald already lost his. We will not be honoring Gerald's refund request.

*(But the IDEA is solid! It's a CLEAN cutover! Filenames in your spec dir mean DOCUMENTS now, not VERSIONS! VERSIONS are in git where they BELONG!)*

---

## 2026-04-09 — "THE SHIT DROPS"

It's HERE! The plugin with the command prefix that makes your coworkers do a double-take at your terminal! Spec-Harness Implementation Trail lands at the spillway and it is AMBITIOUS, OPINIONATED, and AGGRESSIVELY NAMED!

### spec-harness-implementation-trail v0.1.0

- **Initial release!** Spec-driven development framework arrives at the spillway trailing specs and provenance markers
- **The reification chain** — transcripts → PRD → spec → ADR → code → tests → docs. Every step traced. Every requirement has an ID.
- **17 commands** all prefixed `/shit:` — this was not an accident, they worked backwards from the acronym
- **Conception interviews** — structured design conversations captured as high-fidelity transcripts with `[U]/[C]/[T]/[S]` notation
- **Provenance markers** — `@provenance: REQ-ID` comments link code to spec requirements like certificates of authenticity for your function declarations
- **Six-layer verification** — scope, traceability, invariants, architecture, blast radius, gap analysis. `/shit:verify` runs them all.
- **Distillation pipeline** — gate files carry spec rules forward into actionable checks at each phase
- **Zero config** — directory layout hardcoded, conventions hardcoded, prefix hardcoded. Take it or leave it.
- **Installation:** TBD *(the spec for the installation docs is probably somewhere in the pipeline)*


---

## 2026-02-16 — "THE PAPERS, PLEASE UPDATE"

Turns out every manifest in the whole marketplace was claiming MIT when the ACTUAL license is Jake's No Nonsense, No Nazi License. That's like putting a Honda badge on a TANK. Fixed that, and stamped SPDX headers on every source file so there's no confusion about whose slop this is.

### claude-rest-system v3.0.3
- Fixed license field from MIT to LicenseRef-JNNNL-1.0 in plugin.json and marketplace.json
- Added `Copyright (c) 2026 Yaakov M Nemoy / SPDX-License-Identifier: LicenseRef-JNNNL-1.0` headers to all 19 shell scripts, 6 commands, 9 agents, 3 skill files

### claude-autosurgeon v0.2.1
- Fixed license field from MIT to LicenseRef-JNNNL-1.0 in plugin.json and marketplace.json
- Added SPDX license headers to update-docs.sh and SKILL.md (cached Anthropic docs under docs/en/ excluded — not our copyright)

### git-wizardry v2.0.1
- Fixed license field from MIT to LicenseRef-JNNNL-1.0 in plugin.json and marketplace.json
- Added SPDX license headers to 2 commands, 1 agent

### productivity-pack v2.0.1
- Fixed license field from MIT to LicenseRef-JNNNL-1.0 in plugin.json and marketplace.json
- Added SPDX license headers to 4 commands

### marketplace-wide
- All 12 plugin entries in marketplace.json updated from MIT to LicenseRef-JNNNL-1.0
- SPDX headers added to .beads/config.yaml and test/integration/vm.yaml

---

## 2026-02-13 — "THE BOOK DOCTOR UPDATE"

Your EPUB was BROKEN and nobody told you! Well, actually Books.app told you — with a LOVELY error about mismatched tags on line 202. So we fixed FIVE bugs at once!

### claude-rest-system v3.0.2

- **Fixed smooshed lists in EPUB** — LLM-generated markdown like `**Key findings:**\n- item` (no blank line before the list) caused Pandoc to render everything as one chonky paragraph. New `fix_list_spacing()` awk filter ensures blank lines before all list items at all 4 content insertion points
- **Test coverage** — Added list spacing assertion (Test 9) to `test_epub_builder.sh`

### claude-rest-system v3.0.1

- **Fixed XHTML parsing errors** — `<placeholder>` tags in session content no longer nuke the entire EPUB. Pandoc now escapes all angle brackets via `--from markdown-raw_html`
- **Fixed heading hierarchy** — H1 headings in rest.md now properly demote to H2, so pattern sections nest under Part I instead of breaking out as rogue chapters
- **Fixed session sort order** — S1, S2, S9, S10, S100 instead of S1, S10, S100, S109, S11 (version sort, what a concept!)
- **Fixed INDEX/SUMMARY inclusion** — Non-session markdown files in session-reports/ no longer sneak in as fake sessions
- **Pattern dedup** — If rest.md already contains full pattern content, Part III is skipped to avoid duplicating 1700 lines
- **Test suite** — New `test_epub_builder.sh` with fixtures from the mega analysis, 7 assertions including xmllint XHTML validation


---

## 2026-02-12 — "THE TRANSCRIPT UPDATE"

Sessions are like ONIONS — layers upon layers of JSON noise hiding the GOOD STUFF! So we built a PEELER!

### claude-rest-system v3.0.0

The BIGGEST architectural change since v2.0! We're talking TWO WAVES of analysis now!

- **Transcript-first analysis** — New two-wave architecture: Wave 1 generates readable transcripts, Wave 2 analyzes them. Agents read conversations, not JSON soup!
- **`rest_session_transcript.sh`** — New preprocessing script strips sessions to their conversational skeleton (1-5% of raw file size). M# line numbers preserved for back-reference!
- **Monster session chunking** — Sessions >1000 lines get chunked with 50-line overlap. No session is too BEEFY to analyze!
- **New `process` finding type** — Walked-through procedures where the user taught the agent step-by-step. These are AUTOMATION CANDIDATES!
- **Walked-Through Processes section** — Reports now include extracted processes with step counts, correction counts, and keywords
- **Process automation suggestions** — Recommendations assembler generates rough implementation sketches for reusable processes
- **All 5 analysis agents updated** — inline-analyzer, beefy-analyzer, beefy-subagent-analyzer, test-analyzer (transcript-first), meta-analyzer (process-aware grep)
- **Updated drilldown** — Process findings get step-by-step walkthrough presentation


---

## 2026-01-02 — "THE MIGRATION UPDATE"

Time to CLEAN HOUSE at the spillway! Deprecated paths are GONE! And now there's a COMMAND to help you UPGRADE!

### claude-rest-system v2.4.0

- **Ditched ~/.claude/self/** — sync.conf and archive.log now live at ~/.claude/ root. SIMPLER! CLEANER! LESS TYPING!
- **MIGRATIONS.md** — Every breaking change documented in sequence for LLM-driven upgrades! It's like a CHANGELOG but for YOUR FILESYSTEM!
- **/upgrade command** — Evaluates your system, tells you what needs migrating, DOES IT FOR YOU! It's non-deterministic SQL migrations but for Claude config! (That reference will make sense to approximately 3 people!)
- **Fixed peers format in rest.md** — Examples now show the v2.2.0 {path, name} object format instead of the old string arrays
- **Fixed agent count** — README now correctly says 9 agents instead of 7 (we can COUNT at the spillway!)
- **Fixed subagent list in SETUP.md** — All 9 agents properly listed with their ACTUAL names


---

## 2025-12-31 — "THE NO CLOBBER UPDATE"

Your reports were getting CLOBBERED! Project A runs `/rest`, Project B runs `/rest`, and WHOOPS there goes Project A's analysis! NOT ANYMORE!

### claude-rest-system v2.3.0

- **Per-project report directories** — Each project gets its own subdirectory under `reports/{project-slug}/`. No more cross-project clobbering!
- **Timestamped run preservation** — Every `/rest` run creates `{project-slug}/{YYYY-MM-DD-HH-MM}/` — old reports NEVER deleted! Compare analyses across time! See how your learnings EVOLVE!
- **Project-specific EPUB naming** — Output is now `{project-slug}-REST-{timestamp}.epub` instead of generic `REST-ANALYSIS.epub`
- **Drilldown --run flag** — Want to drill into LAST WEEK'S analysis? `/drilldown S47 --run 2025-12-30-14-30` has you covered!
- **All 7 analyzers updated** — Every agent now receives `run_reports_dir` for consistent output paths


---

## 2025-12-31 — "THE DOC CLEANUP UPDATE"

Spring cleaning at the spillway! Well, NEW YEAR'S cleaning! Same thing!

### claude-rest-system v2.2.1

- **Removed ~/.claude/self/ references** — Plugin now uses its own scripts directory (`${CLAUDE_PLUGIN_ROOT}/scripts/`) instead of deprecated user-level paths
- **Happy path first in rest.md** — Reorganized documentation so the DEFAULT workflow is front and center, custom storage options moved to "Advanced" section at the end
- **Plan mode warning** — Command description now reminds users to disable plan mode before running `/rest`
- **Simplified section 2.5** — Now "Identify Storage" instead of "Initialize Storage" since the directory already exists for fatigue to work
- **Fixed SETUP.md** — Removed `~/.claude/self` mkdir, sync.conf path simplified to `~/.claude/sync.conf`


---

## 2025-12-31 — "THE PRETTY NAMES UPDATE"

Your fatigue reports just got a MAKEOVER! No more squinting at truncated paths!

### claude-rest-system v2.2.0

- **Location Display Names** — Configure human-readable names for each location! `~/Documents`, `/iCloud/Projects`, `/Work Laptop/Documents` — finally, paths that make SENSE!
- **Enhanced peers schema** — Locations now support `{"path": "...", "name": "..."}` objects alongside legacy string format
- **Box-style project grouping** — Each project gets its own visual box with `┌─`, `│`, `├─`, `└` characters for clear hierarchy
- **Extra breathing room** — Blank line after project headers, 2-space padding between columns
- **Simplified /yawn** — Command docs trimmed down since the script output speaks for itself


---

## 2025-12-30 — "THE UNIFIED SPILLWAY UPDATE"

You've got projects on THIS machine, projects on THAT machine, and sessions EVERYWHERE! Now they all come together under ONE ROOF!

### claude-rest-system v2.1.0

- **Project Groups** — Define which paths are the SAME project across machines! `grug-brained-employee` on your laptop? Same as `grug-brained-employee` on your work machine? NOW THEY'RE UNIFIED!
- **Global peers config** — `~/.claude/project-peers.json` maps human-friendly project names to all their physical locations (local + remote)
- **Human-friendly project names** — No more staring at `-Users-yankee-Documents-Projects-jakes-one-stop-all-slop-tra...`! The project name is extracted from the path!
- **Hierarchical fatigue report** — Each project shows a ROLLUP line plus indented location breakdowns. Finally see when iCloud and local paths both contribute to the same project!
- **Per-location stats** — Track sessions, messages, subagents, and size for EACH physical location within a project
- **Filtered other-machines** — Unconfigured peer sessions excluded until you add them to a project group via `/peers`


---

## 2025-12-29 — "THE TEMPORAL AWARENESS UPDATE"

How long has it been since you RESTED? Now you'll KNOW!

### claude-rest-system v2.0.1

- **Last Analysis Time per Project** — Fatigue report now shows `[last: Xd ago]` for each project, so you know which ones are falling behind on their REST!
- Handles all edge cases: `never` for unanalyzed projects, `unknown` for malformed timestamps, and human-friendly time units (just now, Xm, Xh, Xd, Xw)


---

## 2025-12-27 — "THE BEEFY UPDATE"

Well well WELL, look who's been hitting the GYM! This release is so THICC it needed its own PROTOCOL!

### claude-rest-system v2.0.0

The BIG one. The ABSOLUTE UNIT of updates. We're talking:

- **Session Classification System** — Now we sort your sessions into Group A (meta-analysis, Claude analyzing Claude) and Group B (actual work). It's like a BOUNCER at the spillway, but for your cognitive load!
- **Three Analysis Paths** — INLINE for small sessions, META for recursive navel-gazing, and BEEFY for when things get SERIOUS
- **The BEEFY Pipeline** — For sessions with >10 subagents. We break it into BATCHES because even Claude has LIMITS (I know, I was shocked too)
- **7 Specialized Agents** — Up from 4! We've got session-classifier, inline-analyzer, meta-analyzer, beefy-analyzer, beefy-subagent-analyzer, beefy-reporter, AND rewind-analyzer!
- **User Pacing Controls** — Claude asks permission before eating your tokens! CONSENT is IMPORTANT!
- **Subagent Discovery** — fatigue_check.sh now finds ALL the little helper sessions. Nothing slips through the cracks!

### claude-rest-system v1.3.1

- Exclude subagent sessions from main fatigue reports (they get their own line now!)


---

## 2025-12-19 — "THE REWIND UPDATE"

Ever lose something in the COMPACTION? Yeah, us too. Now you can get it back!

### claude-rest-system v1.3.0

- **Added /rewind command** — Search your session history even AFTER context compaction! "Where did we leave off?" finally has an ANSWER!
- Audit cleanup improvements — Less cruft, more stuff!


---

## 2025-12-17 — "THE DEDUP-OCALYPSE"

Three releases in ONE DAY? When you're hot, you're HOT!

### claude-rest-system v1.2.2

- Session deduplication by UUID precedence — No more counting the same session twice just because it shows up in different machines!

### claude-rest-system v1.2.1

- Mandatory metadata.json for analysis — If there's no receipt, it didn't happen!
- Atomic verification — Either the whole thing writes or nothing does. No half-baked analysis!

### claude-rest-system v1.2.0

- **Coverage verification** — Now we PROVE we analyzed everything!
- **EPUB pattern reports** — Take your learnings TO GO!


---

## 2025-12-15 — "THE NARRATIVE UPDATE"

JSON is for MACHINES! We read PROSE at the spillway!

### claude-rest-system v1.1.1

- EPUB content structure clarifications — The e-reader experience you DESERVE!

### claude-rest-system v1.1.0

- **Narrative markdown reports** — No more JSON findings! STORIES, baby!
- **Pattern consolidation** — Finding the THEMES in your chaos
- **Enhanced EPUB generation** — Now with chapters and everything!


---

## 2025-12-13 — "THE v2 BUMP"

Sometimes you just gotta bump the major version, ya know?

### git-wizardry v2.0.0
### productivity-pack v2.0.0

- Major version bump for the OG plugins!
- These bad boys now have EVEN MORE features that may or may not work!


---

## 2025-12-12 — "THE BIG BANG" (For claude-rest-system)

One plugin to rule them all, one plugin to find them, one plugin to MAKE CLAUDE TAKE A NAP!

### claude-rest-system v1.0.0

- **Initial release!** Session analysis, fatigue tracking, the whole enchilada!
- **/yawn** — Check your fatigue level!
- **/rest** — The main event! Analyze those sessions!
- **/drilldown** — When you REALLY need to know what happened
- **/peers** — Multi-machine mind meld! Sync your learnings across devices!
- Session archival hooks — Never lose a session to the 30-day void again!


---

## 2025-11-26 — "THE AUTOSURGEON ARRIVES"

What if Claude had a screwdriver and NO adult supervision?

### claude-autosurgeon v0.2.0

- **Cached offline docs** — Claude can now read its own manual without internet!
- Self-modification capabilities — It's SELF-SURGERY at a SPILLWAY!
- What could POSSIBLY go wrong? (Don't answer that)


---

## 2025-11-21 — "THE VOICE EMERGES"

*The day Jake learned to SPEAK*

### Meta

- **Added character voice guide** — CLAUDE.md now explains how to write like Jake
- The SLOP has a VOICE and it is ENTHUSIASTIC!


---

## 2025-11-16 — "GRAND OPENING"

*The day the spillway OVERFLOWED with OPPORTUNITY!*

### Marketplace Launch

Jake's One-Stop All-Slop Trading Post opens for BUSINESS! Step right up, step right up!

### git-wizardry v1.0.0

- Smart commits! Branch cleanup! Git expertise that knows git better than YOU do!
- (No offense!)

### productivity-pack v1.0.0

- Pomodoro timers! Notes! Daily standups!
- It's like a Swiss Army knife for your workflow! Except instead of getting confiscated at the airport, it gets confiscated by your PRODUCTIVITY!


---

*This SLOP REPORT is maintained with the same care and attention Jake applies to everything at the spillway: ENTHUSIASTIC, occasionally ACCURATE, and always AVAILABLE for a good price!*

*For questions about specific versions, check the git log. For complaints, check the spillway.*
