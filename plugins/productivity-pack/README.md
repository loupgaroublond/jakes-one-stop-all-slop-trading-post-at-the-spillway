# 🍅 Productivity Pack

### *"You'll Be SO Productive, You'll Forget To Eat!"*

---

## Listen Up, Productivity Seekers!

You know what grinds my gears? People who say they don't have time! Well GUESS WHAT, friend — I got your solution right here! This bad boy's got FOUR count 'em FOUR productivity commands that'll turn you from a procrastinator into an ORGANIZED MACHINE!


## What's In The Box?!

### `/pomodoro [duration] [task]`

Start a Pomodoro timer session! It's that Italian tomato technique thing! You know, work for 25 minutes, take a break, repeat until you're PRODUCTIVE AS HECK!

**What it does:**
1. Calculates your session times!
2. Tells you when to start and stop!
3. Reminds you to take breaks!
4. Keeps you FOCUSED!

**Examples:**
```
/pomodoro
/pomodoro 50m Deep work on refactoring
/pomodoro 25m Review pull requests
```

(Note: Claude Code can't run background timers, so you gotta set your own timer. But HEY, at least it does the math for you!)


### `/note [content]`

Quick notes! BAM! Timestamped! Organized! It's like having a personal assistant, except it's a markdown file and it doesn't judge you!

**Automatically categorizes your notes:**
- Tasks → `notes/tasks.md`
- Research questions → `notes/research.md`
- References and URLs → `notes/references.md`
- Everything else → `notes/daily.md`

**Examples:**
```
/note TODO: Review pull request #123
/note How does the authentication flow work?
/note https://docs.example.com/api - useful reference
/note Great meeting with design team!
```


### `/daily-standup`

Generate your daily standup from git commits and notes! It's like having a PERSONAL BIOGRAPHER, except for work stuff!

**Checks your:**
- Git commits from the last 24 hours
- Recent notes and tasks
- Open pull requests (if you got the gh CLI)

Then formats it all nice and pretty so you can copy-paste it into Slack and look like you TOTALLY have your act together!

**Example:**
```
/daily-standup
```

BOOM! Instant standup! Your manager will be SO impressed!


### `/time-log [duration] [project] [description]`

Track your time! Prove to your boss you actually work! Or discover you spent 3 hours "debugging" when you were actually reading documentation! (We've all been there!)

**Examples:**
```
/time-log 2h backend Fixed authentication bug
/time-log 45m frontend Implemented dashboard widget
/time-log 1.5h meeting Sprint planning
```

Supports flexible time formats: "2h", "1.5h", "45m", "90m" — we're not picky!


## Installation

From Jake's Trading Post:
```
/plugin install productivity-pack@all-slop-marketplace
```

Or if you cloned it locally:
```
/plugin install ./plugins/productivity-pack
```


## Features That'll Blow Your Mind

- 🍅 **Pomodoro support** — Stay focused, take breaks!
- 📝 **Automatic note categorization** — It's SMART!
- 📊 **Git-based standup generation** — Looks like magic!
- ⏰ **Time tracking** — Finally know where your day went!
- 📈 **Monthly summaries** — Track your progress!


## Pro Tips From Jake

1. **Combine the powers!** Use `/note` during `/pomodoro` sessions to capture those brilliant ideas before they escape!

2. **Review regularly!** Check your notes weekly. Or whenever you remember they exist!

3. **Track consistently!** Log time right after you do stuff, while you still remember what you did!

4. **Automate standups!** Run `/daily-standup` every morning and feel like a PRODUCTIVITY GOD!


## Frequently Asked Questions

**Q: Will this make me productive?**
A: It gives you the TOOLS for productivity! Using them is on you!

**Q: Can I customize the note categories?**
A: Fork it and make your own! That's the beauty of open source!

**Q: Does the Pomodoro timer actually run?**
A: It gives you the times, YOU set the timer. We've been over this!

**Q: Why should I trust Jake with my productivity?**
A: I've been standing out here at the spillway selling productivity tools for... *checks notes* ...a significant amount of time! I'm BASICALLY an expert!


## License

MIT — FREE AS A BIRD! A very productive, organized bird!

---

*Brought to you by Jake's One-Stop All-Slop Trading Post at the Spillway*

*"Productivity has never been this... productive!"*
