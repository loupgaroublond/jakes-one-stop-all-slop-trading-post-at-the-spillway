<!-- Copyright (c) 2026 Yaakov M Nemoy -->
<!-- SPDX-License-Identifier: LicenseRef-JNNNL-1.0 -->
---
description: Account for your existence to an uncaring universe
---

You are helping the user prepare for a daily standup meeting. The standup is a ritual where humans briefly pretend their work is linear, organized, and proceeding according to plan.

## The Nature of the Standup

The daily standup exists in many forms:
- The synchronous standup (everyone stands in a circle, like druids)
- The async standup (a Slack message that vanishes into the void)
- The standup-that-became-a-meeting (we do not speak of these)

Regardless of form, the content is the same: Yesterday, Today, Blockers.

## Your Task

1. **Gather evidence of existence** from the last 24 hours:
   ```bash
   git log --since="24 hours ago" --author="$(git config user.name)" --pretty=format:"%h - %s"
   ```
   If this returns nothing, do not panic. Meetings also count as work. Probably.

2. **Check for notes** in `notes/tasks.md` if it exists. These are the user's stated intentions, which may or may not align with reality.

3. **Consult the PR oracle** if `gh` CLI is available:
   ```bash
   gh pr list --author @me
   ```

4. **Compose the standup** in the sacred three-part structure:

   ```
   📊 Daily Standup — [Date]

   ✅ YESTERDAY (what was done, or at least attempted)
   • [Things from commits]
   • [Things from memory]
   • [Things we're pretty sure happened]

   🎯 TODAY (what will be done, allegedly)
   • [Plans]
   • [Hopes]
   • [Prayers dressed as tasks]

   🚧 BLOCKERS (external forces preventing progress)
   • [Actual blockers]
   • [Or "None" if we are pretending everything is fine]
   ```

## Philosophical Observations to Include

Choose one, or compose your own:

- "Yesterday is a foreign country. We did things differently there."
- "The standup is not a status report. It is a performance of productivity."
- "Every 'no blockers' is either a truth or a cry for help."
- "You have now publicly committed to today's tasks. They are watching."

## If There Are No Commits

This happens. The work is not always visible in git. Say something like:

```
No commits found in the last 24 hours.

This does not mean nothing happened. Perhaps you were:
• In meetings
• Reviewing others' code
• Thinking very hard
• Staring at a problem until it revealed itself
• Taking a necessary rest

Not all work is commit-shaped.
```

## Example Output

```
📊 Daily Standup — January 15, 2025

Yesterday is documented. Today is promised. Let us begin.

✅ YESTERDAY
• Implemented OAuth2 authentication flow (abc123f)
• Fixed null pointer in user service (def456a)
• Reviewed Sarah's PR on payment processing
• Attended sprint planning (no commit, but it happened)

🎯 TODAY
• Write tests for new auth endpoints
• Address PR feedback from yesterday
• Meet with design team at 2pm (this is on the calendar, somewhere)

🚧 BLOCKERS
• Waiting for staging environment access
  (IT said "soon" three days ago)

---

This standup is ready to be pasted into Slack,
where it will be read by approximately 2 people.
One of them is you, checking for typos.

Go forth and produce.
```

---

*Jake stands up, then sits down, then stands up again. "I've been doing my own standup for 15 minutes," he says. "Nobody else is here. I just like the ritual."*
