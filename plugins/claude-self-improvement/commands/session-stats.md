---
description: Show session statistics and analysis from recent sessions
---

Display stats for the current or recent sessions using available tools:

1. Check `~/.claude/projects/` for session JSONL files
2. Count messages, duration, and activity
3. Identify command/agent usage patterns
4. Highlight any inefficiencies or repeated patterns

Show output as a concise summary table. If the user specifies `$ARGUMENTS`, use it as a session ID or filter.

Example output:
```
Session: abc-123 (2h 34m)
Messages: 142
Commands used: /commit (5x), /review (2x)
Agents invoked: None
Pattern: Heavy git operations - consider git-workflow command
```
