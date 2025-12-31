---
description: Check Claude's fatigue level - how many sessions need review
---

Run the fatigue check script to see how many unseen sessions have accumulated.

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/fatigue_check.sh
```

Format the output as a table for better readability. The script provides:
- Main Sessions: unseen count, message count, size
- Subagents: unseen count, message count, size
- Combined Total
- Per-project breakdown with "Last Analyzed" timestamp (shown as `[last: Xd ago]` or `[last: never]`)

IMPORTANT: The "Last Analyzed" column is required - it shows when each project was last reviewed via /rest.

Present the fatigue report in table format:

```
## Fatigue Report

| Category | Sessions | Messages | Size |
|----------|----------|----------|------|
| Main Sessions | X | Y | ZMB |
| Subagents | X | Y | ZMB |
| **Combined** | X | Y | ZMB |

### By Project

| Project | Sessions | Msgs | Subagents | Sub Msgs | Size | Last Analyzed |
|---------|----------|------|-----------|----------|------|---------------|
| project-a | X | Y | A | B | ZMB | 2d ago |
| project-b | X | Y | A | B | ZMB | never |
```

If no unseen sessions exist, simply report: "No unseen sessions - fatigue level: 0"
