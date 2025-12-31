---
description: Discover and configure peer projects from other machines
---

# Project Groups Configuration

Help the user configure project groups to unify sessions from multiple locations under a single project name.

## Concept

The same conceptual "project" can exist in multiple physical locations:
- Local directories (e.g., `~/Documents`, `/iCloud/Projects`)
- Other machines (synced via `~/.claude/session-archives/other-machines/`)

**Project groups** map a human-friendly project name to all physical locations, enabling:
- Unified fatigue reporting (`/yawn`)
- Cross-machine session analysis (`/rest`)
- Session deduplication by UUID

## Config Location

**Global config**: `~/.claude/project-peers.json`

## Schema

```json
{
  "grug-brained-employee": {
    "local": [
      {"path": "-Users-yankee-Library-Mobile-Documents-com-apple-CloudDocs-Projects-grug-brained-employee", "name": "/iCloud/Projects"},
      {"path": "-Users-yankee-Documents-grug-brained-employee", "name": "~/Documents"}
    ],
    "work": [
      {"path": "-Users-ynemoy-Documents-grug-brained-employee", "name": "/Work Laptop/Documents"}
    ]
  },
  "spillway": {
    "local": [
      {"path": "-Users-yankee-Documents-Projects-jakes-one-stop-all-slop-trading-post-at-the-spillway", "name": "~/Documents/Projects"}
    ]
  }
}
```

- **Top-level key**: Human-friendly project name (shown in fatigue report header)
- **Second level**: Machine name ("local" for this machine, others from other-machines/)
- **Values**: Array of location objects:
  - `path`: Encoded session-archive path (uses `-` as separator)
  - `name`: Display name shown in fatigue report (e.g., `~/Documents`, `/iCloud/Projects`, `/Work Laptop/Documents`)

## Workflow

### 1. Scan Available Paths

List all session paths found locally and on other machines:

```bash
# Local projects
ls ~/.claude/projects/

# Local archives
ls ~/.claude/session-archives/ | grep -v other-machines

# Other machines
ls ~/.claude/session-archives/other-machines/*/
```

### 2. Show Current Config

Read and display existing configuration:

```bash
cat ~/.claude/project-peers.json 2>/dev/null || echo "{}"
```

### 3. Identify Ungrouped Paths

Compare discovered paths against configuration. For each ungrouped path:
- Extract the project name from the path (last meaningful component)
- Suggest grouping with paths that have matching project names
- Suggest appropriate display names based on path structure

### 4. Suggest Groups

Present findings to the user:

```
## Ungrouped Paths

### Local
- -Users-yankee-Documents-Projects-new-project
  Suggested: project="new-project", name="~/Documents/Projects"

### work (other machine)
- -Users-ynemoy-Documents-grug-brained-employee
  Suggested: add to "grug-brained-employee", name="/Work/Documents"

## Suggested Groups

"grug-brained-employee" could include:
  - local: /iCloud/Projects (existing)
  - work: /Work Laptop/Documents (new - same project name)

Add work path to "grug-brained-employee" group? [Y/n]
```

### 5. Update Config

When the user confirms, update `~/.claude/project-peers.json` with the new location object.

### 6. Confirm

Show the updated configuration and explain:
- `/yawn` will now group sessions under the project name
- `/rest` will analyze sessions from all locations in the group
- Sessions are deduplicated by UUID (most current copy wins)

## Display Name Conventions

Use path-style names that indicate where the project lives:
- `~/Documents` - Home Documents folder
- `~/Documents/Projects` - Projects subfolder
- `/iCloud/Projects` - iCloud Drive Projects folder
- `~/.claude` - Claude config directory
- `/Work Laptop/Documents` - Other machine's Documents

## Behavior Notes

- **Ungrouped local paths**: Automatically included in `/yawn` with auto-generated names
- **Ungrouped other-machines paths**: Excluded until explicitly added to a group
- **Precedence**: local > archived > peer (for deduplication)

## User Instructions

$ARGUMENTS
