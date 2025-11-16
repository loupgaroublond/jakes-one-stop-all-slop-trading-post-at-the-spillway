---
description: Quick note-taking with automatic timestamping and organization
---

You are helping the user capture quick notes and organize them effectively.


## Behavior

1. Parse the note content from `$ARGUMENTS`
2. Determine the note type:
   - If starts with "TODO:" or contains task language → task note
   - If contains question marks or "how/why/when" → research note
   - If contains URLs or references → reference note
   - Otherwise → general note

3. Create or append to the appropriate notes file:
   - Tasks: `notes/tasks.md`
   - Research: `notes/research.md`
   - References: `notes/references.md`
   - General: `notes/daily.md`

4. Format the note entry:
   ```markdown
   ## [YYYY-MM-DD HH:MM]

   $ARGUMENTS
   ```


## File Organization

If the notes directory doesn't exist, create it with:
- `notes/tasks.md` - Action items and todos
- `notes/research.md` - Questions and investigations
- `notes/references.md` - Links and resources
- `notes/daily.md` - General notes and thoughts


## Example Usage

User: `/note TODO: Review pull request #123`

Creates entry in `notes/tasks.md`:
```markdown
## [2025-01-15 14:30]

TODO: Review pull request #123
```


## Guidelines

- Always add timestamps in ISO format
- Keep notes concise and scannable
- Use markdown formatting for readability
- Append to existing files rather than overwriting
- Suggest periodic review of accumulated notes
