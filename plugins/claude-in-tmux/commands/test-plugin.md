---
description: Spawn a controlled, isolated claude session in tmux to test a plugin
allowed-tools: Bash(tmux:*), Bash(claude:*), Bash(mkdir:*), Bash(rm:*), Bash(ln:*), Bash(touch:*), Bash(find:*), Bash(cat:*), Bash(test:*), Bash(printf:*), Bash(grep:*), Bash(sleep:*)
argument-hint: <plugin-root-path> [<initial-slash-command>]
---

# Test Plugin

Use the **claude-in-tmux** skill to drive a fresh, isolated `claude` CLI session against the plugin path provided in `$ARGUMENTS`, without contaminating the user's `~/.claude/` state.

## Behavior

1. Parse `$ARGUMENTS` as `<plugin-root-path> [<initial-slash-command>]`. If empty, ask the user for the plugin path.
2. Verify `plugin.json` exists at the given root. If not, abort with a clear error.
3. Verify `ANTHROPIC_API_KEY` is set in the parent environment. If not, abort and tell the user it is required (the isolation recipe uses `--bare`, which has no other auth path).
4. Create `/tmp/cit-<timestamp>-<pid>/` as the test temp dir. Inside it: `fixture/` (the test cwd), `wrapper/` (symlink controlling the slash-command prefix), `home/` (HOME override), `settings.json` (minimal), `.pre-ts` (contamination snapshot timestamp).
5. Install a `trap cleanup EXIT INT TERM` **before** creating any state. The trap kills the tmux session, `rm -rf`'s the temp dir, and runs the post-cleanup contamination check (`find ~/.claude -newer .pre-ts -not -path '*/projects/*'`).
6. Launch the child claude with the isolation recipe from §3e of the skill: `--bare --plugin-dir <wrapper> --settings <minimal> --setting-sources '' --strict-mcp-config --add-dir <fixture> --add-dir <plugin> --permission-mode acceptEdits --effort medium`.
7. Handle the folder-trust prompt automatically (always send `Enter` for option 1).
8. If an initial slash command was supplied, send it. Otherwise, prompt the user for what to send next.
9. After each command sent, capture the pane (`tmux capture-pane -p; echo END`) and report what the agent rendered. Watch the `↓ N tokens` counter — if it freezes for 60 s, treat as a stall and offer to retry at lower effort or kill the session.
10. On exit (success or error), confirm cleanup ran and the contamination check found nothing.

## Constraints (do not violate)

- **No `claude plugin disable/enable`.** The dev plugin must load via `--plugin-dir` plus the symlink-wrapper trick — see skill §5.
- **No writes to `~/.claude/`.** Verify with the post-cleanup `find` check.
- **Default to `--effort medium`.** xhigh on Opus 4.7 reliably stalls (skill §6).
- **Default to `--permission-mode acceptEdits`** unless the user explicitly wants `default` to test the prompt UX.
- **Width matters.** Always `tmux new-session -x 220 -y 60`.

## Reference

Read `skills/claude-in-tmux/SKILL.md` end to end before driving the session. The end-to-end script in §12 is a working starting point — adapt it with the user's plugin path and initial command.

If the user has not specified a plugin path and `$ARGUMENTS` is empty, ask before proceeding.
