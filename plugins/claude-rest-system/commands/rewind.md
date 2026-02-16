<!-- Copyright (c) 2026 Yaakov M Nemoy -->
<!-- SPDX-License-Identifier: LicenseRef-JNNNL-1.0 -->
---
description: Search current session history for events before context compaction
---

# Rewind

Search through the current session's full history to find events that may have been compacted out of context.

## Usage

```
/rewind <query>
```

## Examples

- `/rewind did we commit anything?`
- `/rewind what was that error message?`
- `/rewind which files did we edit?`
- `/rewind what did we decide about the auth flow?`

## Workflow

### 1. Find Current Session

```bash
SESSION_FILE=$(${CLAUDE_PLUGIN_ROOT}/scripts/rest_current_session.sh)
MESSAGE_COUNT=$(wc -l < "$SESSION_FILE" | tr -d ' ')
```

### 2. Report Session Info

Tell the user:
- Session file found
- Total message count
- What you're about to search for

### 3. Spawn Rewind Agent

Use the Task tool to spawn the `rewind-agent` with:

```
Search this session for: $ARGUMENTS

Session file: <path>
Message count: <count>

Find relevant messages and report what you discover.
```

### 4. Report Findings

The agent will search the session and report:
- Direct answer to the query
- Message references [M#start-end]
- Key excerpts if helpful
- Offer to dig deeper if needed

## Notes

- This command searches YOUR current session, not past sessions
- For analyzing past sessions, use `/rest` instead
- Uses haiku model for speed and efficiency
- Session files are JSONL format with one message per line
