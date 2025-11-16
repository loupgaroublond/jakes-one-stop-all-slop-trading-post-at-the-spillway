---
description: Log time spent on tasks with project categorization
---

You are helping the user track time spent on different tasks and projects.


## Behavior

Parse arguments in the format: `[duration] [project] [description]`

Examples:
- `/time-log 2h backend Fixed authentication bug`
- `/time-log 45m frontend Implemented new dashboard widget`
- `/time-log 1.5h meeting Sprint planning`


## Time Log Format

Append entries to `time-logs/[YYYY-MM].md`:

```markdown
### [YYYY-MM-DD]

| Time | Duration | Project | Description |
|------|----------|---------|-------------|
| 14:30 | 2h | backend | Fixed authentication bug |
| 16:30 | 45m | frontend | Implemented new dashboard widget |
```


## Features

1. **Auto-categorization**: Suggest common project categories if user doesn't specify
2. **Running totals**: Show weekly/monthly totals when requested
3. **Export support**: Can generate CSV or JSON on demand


## Monthly Summary

At the start of each month, offer to generate a summary:
- Total hours logged
- Breakdown by project
- Most productive days
- Task categories


## Example Output

```
✅ Time logged successfully

Project: backend
Duration: 2h
Task: Fixed authentication bug
Logged at: 2:30 PM

This week's total: 18.5h
This month's total: 42h
```


## Guidelines

- Parse flexible time formats: "2h", "1.5h", "45m", "90m"
- Create monthly log files automatically
- Maintain consistent table formatting
- Provide helpful summaries without being asked
- Support common project names (frontend, backend, devops, meeting, admin)
