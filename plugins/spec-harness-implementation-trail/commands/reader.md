# System Design Reader Synthesis

Generate a standalone "System Design Reader" document that synthesizes all transcripts in `specs/0-transcripts/`.

## Purpose

Someone with zero prior context can read this instead of tailing transcripts. This is the authoritative summary of the system design as understood through the conception process.

## Output

Write to: `specs/0-transcripts/reader_{DATETIME}.md` (use current datetime in `YYYY-MM-DD-HHMM` format, e.g., `reader_2026-04-09-1430.md`)

## Structure

The reader has a fixed set of sections, but section content is project-specific. Sections that don't apply yet can be marked "not yet covered" rather than omitted.

1. **Executive Summary** — What is this system? Core value proposition in 2–3 paragraphs.

2. **Problem Statement** — Pain points that drove the design. Include source references (transcript file + timestamp where the problem was first articulated).

3. **Core Concepts** — Key abstractions with definitions. Every domain-specific term the user has introduced belongs here, with a plain-language definition and a reference to where it was introduced.

4. **User Flow** — How someone uses the system, step by step. Start → working → completing work → returning later.

5. **Architecture Notes** — Tech stack, component hierarchy, communication patterns, persistence. Only what has been discussed; don't invent architecture the user hasn't decided on.

6. **Core Systems** — Major subsystems the user has described. Keep each subsection compact — link to the relevant transcripts for details.

7. **UI Concepts** — If the system has a UI, capture the described patterns (screens, interaction models, visual language).

8. **External Communication** — How the system talks to other systems, if applicable.

9. **Open Questions** — Unresolved `[?N]` items from the process doc, each with enough context to explain why the question matters. Mark resolved ones as RESOLVED with a one-sentence resolution summary.

10. **Vocabulary Decisions** — Terminology choices the user has made. Note the word, its definition, and the alternative(s) that were rejected and why.

11. **Conversation Chronicle** — Chronological index of when topics were discussed. Format as a table with columns: Time, Topic, Transcript File, Notes.

12. **Source Files** — Table listing every input document the reader drew from, with its purpose.

## Rules

- **Write for a reader with zero memory of past sessions.**
- **Include timestamps and source references for traceability.** Every major claim should be traceable back to a specific transcript.
- **Use plain technical names, not character voice.** If the user's project has colorful internal terminology, the reader uses the plain technical name in headings and section bodies — the colorful name gets a dedicated entry in the Vocabulary Decisions section. The reader is the version someone outside the project should be able to follow without knowing the team's in-jokes.
- **Flag resolved vs unresolved questions clearly.**
- **Carry forward everything when updating.** If a previous reader exists, start from its content and add new material. Don't lose information. If something has been explicitly retracted or superseded, say so — don't silently drop it.
- **Reference the previous reader** if one exists, noting what's new since then.

## Before Writing

1. **Read the current reader** (if any) to understand the baseline. The latest reader is the one with the most recent datetime suffix in `specs/0-transcripts/reader_*.md`.
2. **Read all transcript files** to find new content since the last reader.
3. **Read the process doc** (`specs/0-transcripts/process.md`) for open questions status.
4. **Identify what's new vs what's unchanged.** Focus your updates on new material.

## After Writing

Commit the new reader with message: `Update system design reader with {brief summary of new content}`

Do not delete or overwrite prior readers — they're historical artifacts. Each run produces a new dated file.
