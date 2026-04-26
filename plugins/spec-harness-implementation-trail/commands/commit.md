---
description: Transcribe recent discussion, then git commit
allowed-tools: Bash(*schema-check.sh*)
---

# Transcribe and Commit

Update the transcript file(s) to reflect what was discussed since the last transcription, then make a git commit.

## Schema check

This command targets schema version **2**.

Active project state:

!`"${CLAUDE_PLUGIN_ROOT}/scripts/schema-check.sh"`

Decide based on the output above:
- `STATUS=OK` — proceed.
- `STATUS=MISMATCH` or `STATUS=LEGACY` — the project is on schema v$ACTIVE; this command targets v$LATEST. Recommend `/shit:migrate`. If the user wants to defer and the rest of this command does not depend on the changed layout, you may proceed in best-effort mode and warn about possibly stale results.
- `STATUS=UNINITIALIZED` — tell the user to run `/shit:init` first.

## Process

### 1. Transcribe what was said

Before writing the commit, update the transcript file(s) in `specs/0-transcripts/` to reflect what has been discussed in the current session since the last transcription.

**Critical rule:** You MUST use a rewind mechanism to retrieve the actual text of what was said — both what the user typed and what you responded. Do not guess or summarize from memory. The transcript is a high-fidelity record, not an after-the-fact reconstruction.

If the session is long enough that context has been compacted, use whatever tooling is available in your environment to retrieve the pre-compaction text. If no rewind is available, stop and tell the user — do not fabricate a transcript.

Transcripts follow the notation from `/shit:conceive`:

- **[U]** — user's words (preserve their actual phrasing)
- **[C]** — your responses (preserve the actual text verbatim, not a summary; exclude thinking blocks, tool calls, and non-text output)
- **[T]** — your thinking (italics, when it adds understanding)
- **[S]** — synthesis (after a `___` divider, when new whole ideas emerge)

Append to the most recent transcript if it's still the same topical session, or create a new `transcript_{YYYY-MM-DD-HHMM}.md` if the topic has shifted enough to warrant a fresh file.

### 2. Review what's changed

Run `git status` and `git diff` to see all pending changes. This includes:
- New or updated transcripts
- Any other files the user has been working on during the session

### 3. Make the commit

Write a commit message that focuses on the *why*, not just the *what*. If the transcript introduced a new design decision, the commit message should name that decision. If the transcript clarified an existing idea, the message should name the clarification.

Use the project's commit message style if there are recent commits to learn from.

Stage the relevant files and commit. Do not include files that look unrelated to the current session's work without asking the user first.
