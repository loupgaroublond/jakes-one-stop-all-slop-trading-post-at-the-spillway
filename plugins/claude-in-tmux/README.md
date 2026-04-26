# claude-in-tmux

A Claude Code plugin that teaches a parent Claude session how to spawn, drive, and observe a child `claude` CLI session running inside a tmux pane.

## What it gives you

- **`skills/claude-in-tmux/SKILL.md`** — the canonical reference for launching an isolated child claude session, sending slash commands and prompts to it, reading the pane back, handling permission prompts, detecting stalls, and tearing down without leaking state into `~/.claude/`.
- **`commands/test-plugin.md`** — `/claude-in-tmux:test-plugin <plugin-root> [<initial-slash-command>]` — a thin slash command that bootstraps an isolated test session against a plugin under development.

## When to use it

Reach for this when the parent agent needs to:

- Integration-test a Claude Code plugin or slash command end-to-end.
- Reproduce a permission-prompt flow exactly as a real user would see it.
- Drive an automated end-to-end exercise of a claude CLI workflow.
- Observe what claude actually renders on screen (mode lines, status indicators, prompts) rather than guessing.

If you only need to run claude non-interactively, `claude --print` is simpler. This plugin exists for the cases where you need an interactive session under tmux remote control.

## Installation

```sh
claude --plugin-dir ~/.claude/plugins/dev/claude-in-tmux
```

Or symlink/copy it into a marketplace directory.

## Design notes

The skill is the deliverable. The slash command is dispatch; the skill carries the knowledge — the gotchas, the isolation recipe, the diagnostic technique, the example. Read `SKILL.md` end to end before driving a session.
