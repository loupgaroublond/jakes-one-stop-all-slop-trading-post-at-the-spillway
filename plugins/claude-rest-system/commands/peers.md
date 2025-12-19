---
description: Discover and configure peer projects from other machines
---

# Peer Project Discovery

Help the user discover and configure peer projects from other machines for cross-machine rest analysis.

## Workflow

### 1. Identify Current Project

Determine the current project path (the Claude project path format, e.g., `-Users-{username}-...-project-name`).

### 2. Scan Other Machines

List all projects found in `~/.claude/session-archives/other-machines/`:

```bash
ls ~/.claude/session-archives/other-machines/*/
```

For each machine, list the project paths available.

### 3. Suggest Likely Matches

Compare project names (the last component of the path) to find likely matches:
- Exact name match → **Strong match**
- Similar name (substring, case-insensitive) → **Possible match**
- Different name → Listed but not highlighted

Present findings to the user:

```
## Projects on other machines

### work (strong matches)
- `-Users-workuser-projects-totally-not-skynet` ← likely same as current project

### work (other projects)
- `-Users-workuser-projects-shitty-day-job-at-the-spillway`
- `-Users-workuser-projects-side-hustle`
- `-Users-workuser-documents-secret-plans`

Current project: `-Users-{username}-...-totally-not-skynet`
```

### 4. Configure Peers

Ask the user which projects to add as peers. When they confirm, update `.claude/project-peers.json` in the current project directory:

```json
{
  "work": "-Users-workuser-projects-totally-not-skynet"
}
```

If the file doesn't exist, create it. If it exists, merge the new peers.

### 5. Confirm

Show the updated peer configuration and explain that `/rest` will now include sessions from peer projects.

## Notes

- The `.claude/project-peers.json` file lives in the **project directory**, not `~/.claude`
- Multiple machines can be configured as peers
- Peer paths are the remote project paths as they appear in `other-machines/{machine}/`
