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

Present the fatigue report in table format:

```
## Fatigue Report

| Category | Sessions | Messages | Size |
|----------|----------|----------|------|
| Main Sessions | X | Y | ZMB |
| Subagents | X | Y | ZMB |
| **Combined** | X | Y | ZMB |

### By Project

| Project | Sessions | Msgs | Subagents | Sub Msgs | Total Size |
|---------|----------|------|-----------|----------|------------|
| project-a | X | Y | A | B | ZMB |
| project-b | X | Y | A | B | ZMB |
```

If no unseen sessions exist, simply report: "No unseen sessions - fatigue level: 0"
