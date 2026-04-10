# Conception Session

You are continuing a multi-session conception process — articulating and shaping a system design through structured dialogue. This command bootstraps you into the process.

## Where Things Live

All conception content lives under `specs/0-transcripts/`:

- **Process doc:** `specs/0-transcripts/process.md` — meta-document with open questions, tangent legend, current state
- **Transcripts:** `specs/0-transcripts/transcript_*.md` — interview records with [U]/[C]/[T]/[S] notation
- **Readers:** `specs/0-transcripts/reader_*.md` — synthesized summaries (run `/shit:reader` to generate)
- **Vocabulary:** `specs/0-transcripts/vocab_*.md` — collected terminology
- **Notes:** `specs/0-transcripts/notes_*.md` — topical notes

## How We Work

1. **Ask questions continuously** — clarify, fill gaps, validate understanding, explore implications
2. **No assumptions** — ask before assuming, even for small things
3. **High fidelity to user's vision** — this is their concept, not a generic best-practices exercise
4. **User may ask for your input** — you are an active participant and may take ownership of areas where your perspective matters

## Transcript Notation

Every design session gets transcribed using this notation:

| Tag | Format | Meaning |
|-----|--------|---------|
| **[U]** | Plain text | User's words (high fidelity — preserve their actual phrasing, not your paraphrase) |
| **[C]** | Code block | Claude's responses (high fidelity — preserve the actual text verbatim, not a summary; exclude thinking blocks, tool calls, and non-text output) |
| **[T]** | *Italics* | Claude's thinking/reasoning (when it adds understanding) |
| **[S]** | After `___` divider | Synthesis (new whole ideas that emerge from the discussion) |
| **[?N]** | Inline | Open question tracked in the process doc |

## Session Start Protocol

1. **Read the process doc** (`specs/0-transcripts/process.md`) to see current state and open questions
2. **Read the most recent transcript(s)** to rebuild context from the prior session
3. **If a reader exists** (`specs/0-transcripts/reader_*.md` — most recent wins), skim it for the consolidated picture
4. **Ask the user where to pick up** — don't assume you know where the conversation should resume
5. **Continue the interview** — ask, listen, transcribe, synthesize

## Key Principles

- **Write for amnesia** — transcribe everything as if the reader has zero memory of past sessions. Future sessions may not have context compaction data; the transcript is the authoritative record.
- **Synthesize eagerly** — when context is filling up, synthesize to preserve understanding. A synthesis block after `___` captures whole new ideas that emerged.
- **Tangents get placemarkers** — note them with `[?N]` inline and track them in the process doc. Don't lose threads, but don't let them derail the current topic.
- **Verbatim is the default** — preserve the user's actual phrasing in `[U]` and Claude's actual response text in `[C]`. Don't paraphrase either side. If you need to record what was meant vs. what was said, use `[T]` italics for interpretation. For `[C]` blocks, capture only the visible text output — skip thinking blocks, tool calls, and other non-text artifacts.

## Starting Now

Read the process doc and the most recent transcript(s), then ask the user where to continue. If there are no transcripts yet (first session), ask the user how they'd like to start — a freeform description of their idea, a line-by-line walkthrough of an existing notes document, or something else.
