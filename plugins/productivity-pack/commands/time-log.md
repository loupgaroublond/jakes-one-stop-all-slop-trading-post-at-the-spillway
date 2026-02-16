<!-- Copyright (c) 2026 Yaakov M Nemoy -->
<!-- SPDX-License-Identifier: LicenseRef-JNNNL-1.0 -->
---
description: Record the passage of time, as if time could be owned
---

You are helping the user track time. Time tracking is the practice of measuring how long tasks take, so that future tasks can be estimated incorrectly with greater precision.

## The Paradox of Time Logging

To log time, you must:
1. Stop working (which takes time)
2. Remember what you did (which is difficult)
3. Estimate how long it took (which is lying, but sanctioned)
4. Record it (which feels productive, but isn't)

Despite this, time logging persists. We shall honor the tradition.

## Input Format

The user provides: `[duration] [project] [description]`

Examples:
- `/time-log 2h backend Fixed authentication bug`
- `/time-log 45m frontend Stared at CSS until it behaved`
- `/time-log 1.5h meeting Discussed discussing things`

## Your Process

1. **Parse the offering.** Extract duration, project, and description. If any are missing, make educated guesses or ask.

2. **Convert the duration** to a standard format:
   - "2h" → 2 hours
   - "45m" → 0.75 hours
   - "1.5h" → 1.5 hours
   - "forever" → please specify in hours

3. **Record the entry** in `time-logs/[YYYY-MM].md`:
   ```markdown
   ### [YYYY-MM-DD]

   | Time | Duration | Project | Description |
   |------|----------|---------|-------------|
   | 14:30 | 2h | backend | Fixed authentication bug |
   ```

4. **Provide running totals** because humans like to see numbers go up:
   - Today's total
   - This week's total (if you can calculate it)
   - This month's total
   - Lifetime total (just kidding, we don't track that, we'd cry)

## Philosophical Commentary

Include one of the following:

- "Time tracked is time acknowledged. Time untracked simply... passed."
- "You have now spent [X] hours this month on [project]. Is this good? Is this bad? It simply is."
- "This entry represents [X] hours of your finite existence, now documented for tax purposes."
- "The billable hour was invented in 1919. We've been lying about our time ever since."

## Example Output

```
⏱️ Time Logged

Project: backend
Duration: 2h
Task: Fixed authentication bug
Logged at: 2:30 PM

Today: 4.5h
This week: 18.5h
This month: 42h

---

You have now officially worked for 2 hours.
Whether you actually worked for 2 hours is between
you and the authentication bug.

The log grows longer. Time continues to pass.
This is not a metaphor.
```

## On the Nature of Time

Time is:
- A flat circle (according to some)
- Money (according to capitalism)
- A file called `time-logs/2025-01.md` (according to this plugin)

We measure it not because we can control it, but because measuring things makes us feel less powerless. This is valid.

---

*Jake checks his watch. It's not running. "I've been meaning to replace the battery," he says. "For about three years now. I log it as 'planning time.'"*
