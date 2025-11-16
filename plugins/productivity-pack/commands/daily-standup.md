---
description: Generate a daily standup summary from recent git commits and notes
---

You are helping the user prepare their daily standup summary.


## Process

1. Gather information from the last 24 hours:
   - Git commits (use `git log --since="24 hours ago" --author="$(git config user.name)" --pretty=format:"%h - %s"`)
   - Recent notes from `notes/tasks.md` if it exists
   - Open pull requests (use `gh pr list --author @me` if gh CLI is available)

2. Organize findings into standup format:

   **Yesterday:**
   - [Completed work from commits and closed tasks]

   **Today:**
   - [In-progress work and planned tasks]

   **Blockers:**
   - [Any impediments mentioned in notes or PR comments]


## Output Format

Present a clean, concise standup summary that can be copy-pasted into Slack or a standup bot:

```
📊 Daily Standup - [Date]

✅ Yesterday:
• Implemented user authentication with OAuth2
• Fixed bug in payment processing flow
• Reviewed 2 pull requests

🎯 Today:
• Refactor database queries for performance
• Write tests for new API endpoints
• Meet with design team at 2pm

🚧 Blockers:
• Waiting for staging environment access
```


## Guidelines

- Be concise - aim for 3-5 bullets per section
- Focus on outcomes, not minutiae
- Highlight blockers prominently
- If no commits found, check for work in progress via git status
- Maintain a professional but friendly tone
