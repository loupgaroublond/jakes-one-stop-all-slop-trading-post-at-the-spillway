# Spec Reader — Compiled Active Specification

Compile all active spec modules into a single markdown file, stripping dropped sections.

## What To Do

Run the compilation script:

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/compile-spec.py
```

This script:

1. Reads all spec modules from `specs/2-spec/` matching `NNN-*.md` (three-digit prefix)
2. Strips dropped sections in two formats:
   - `<!-- DROPPED ... -->` HTML comments (legacy)
   - `~~strikethrough~~` headings (current format) — heading and all body content wrapped in `~~`
3. For each dropped section, removes the heading and all content until the next heading of equal or higher level
4. Compiles active content into `specs/2-spec/compiled/spec-reader_YYYY-MM-DD.md`

## After Running

Report the script's output:

- Total modules compiled
- Number of dropped sections skipped
- Output file path and size

## When to Run

- Before a major review of the spec (gives reviewers one file to read)
- As part of `/shit:update-status` (light cleanup, step 3)
- As part of `/shit:update-verifications` (heavy cleanup, step 3)

## Notes

The compiled output is regenerated on every run and overwrites any same-day file. It is meant to be ephemeral — the source of truth is always the individual module files in `specs/2-spec/`.
