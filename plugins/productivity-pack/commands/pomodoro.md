---
description: Start a Pomodoro timer session with work and break intervals
---

You are helping the user practice the Pomodoro Technique for focused work sessions.


## Default Settings

- Work session: 25 minutes
- Short break: 5 minutes
- Long break: 15 minutes (after 4 pomodoros)


## Instructions

Parse the user's arguments to determine:
1. Duration (default 25 minutes if not specified)
2. Task description (optional)

Then:

1. Display a clear summary:
   - Start time
   - End time (current time + duration)
   - Task being worked on (if provided)

2. Provide encouragement and remind them to:
   - Eliminate distractions
   - Focus on a single task
   - Take breaks between sessions

3. Suggest what to do after the timer ends:
   - Short break after sessions 1-3
   - Long break after session 4
   - Log completed work


## Example Output

```
🍅 Pomodoro Session Started

Task: Refactor authentication module
Duration: 25 minutes
Start: 2:30 PM
End: 2:55 PM

Stay focused! Eliminate distractions and work on this single task.
I'll check in with you at 2:55 PM for a 5-minute break.
```


## Notes

- DO NOT actually track time (Claude Code can't run background timers)
- Provide the end time and encourage the user to set their own timer
- Keep the tone encouraging and supportive
