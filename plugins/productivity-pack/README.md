# 🍅 Productivity Pack

### *"You'll Be SO Productive, You'll Forget To Eat!"*

---

## ⚠️ IMPORTANT DISCLAIMER ⚠️

**THIS IS PLACEHOLDER SLOP!**

Look, I'm gonna level with you - this plugin is NOT actually functional! It's just here to demonstrate what a plugin COULD look like! It's like the display models at a car dealership - looks good from the outside, but there's NO ENGINE!

We threw this together to show you the marketplace structure! It's EXAMPLE CODE! It's DEMONSTRATION MATERIAL! It's... well, it's SLOP! (The placeholder kind, not the good kind!)

If you want a REAL, ACTUAL, FUNCTIONING plugin, check out the [Claude Self-Improvement Toolkit](../claude-self-improvement)! That one's the REAL DEAL!

---

## Listen Up, Productivity Seekers!

You know what grinds my gears? People who say they don't have time! Well GUESS WHAT, friend - I got your solution right here! This bad boy's got FOUR count 'em FOUR productivity commands that'll turn you from a procrastinator into a... slightly more organized procrastinator!

*IF IT WAS REAL! Which it's NOT! Remember the disclaimer above!*


## What's In The Box?!

### `/pomodoro [duration] [task]`

Start a Pomodoro timer session! It's that Italian tomato technique thing! You know, work for 25 minutes, take a break, repeat until you're PRODUCTIVE AS HECK!

**Now, in the interest of full transparency and in accordance with industry best practices, I must inform you that:** Claude Code cannot actually run background timers. It'll give you the times and YOU gotta set your own timer. But HEY, at least it does the math for you!

**Examples:**
```
/pomodoro
/pomodoro 50m Deep work on refactoring
/pomodoro 25m Review pull requests
```


### `/note [content]`

Quick notes! BAM! Timestamped! Organized! It's like having a personal assistant, except it's a markdown file and it doesn't judge you for eating lunch at 3 PM!

Automatically categorizes your notes:
- Tasks → `notes/tasks.md`
- Research questions → `notes/research.md`
- References and URLs → `notes/references.md`
- Everything else → `notes/daily.md`

**Examples:**
```
/note TODO: Review pull request #123
/note How does the authentication flow work?
/note https://docs.example.com/api - useful reference
/note Great meeting with design team, they finally understand my vision!
```


### `/daily-standup`

Generate your daily standup from git commits and notes! It's like having a PERSONAL BIOGRAPHER, except for boring work stuff!

Checks your:
- Git commits from the last 24 hours
- Recent notes and tasks
- Open pull requests (if you got the gh CLI)

Then formats it all nice and pretty so you can copy-paste it into Slack and look like you TOTALLY have your act together!

**Example:**
```
/daily-standup
```

*BOOM! Instant standup! Your manager will be SO impressed!*


### `/time-log [duration] [project] [description]`

Track your time! Prove to your boss you actually work! Or discover you spent 3 hours "debugging" when you were actually on Stack Overflow! (We've all been there!)

**Examples:**
```
/time-log 2h backend Fixed authentication bug
/time-log 45m frontend Implemented dashboard widget
/time-log 1.5h meeting Sprint planning (it was SUPPOSED to be 30 minutes)
```

Supports flexible time formats: "2h", "1.5h", "45m", "90m" - we're not picky!


## Installation

From Jake's Trading Post:
```
/plugin install productivity-pack@all-slop-marketplace
```

Or if you cloned it locally:
```
/plugin install ./plugins/productivity-pack
```


## Features That'll Blow Your Mind (Slightly)

- 📝 Automatic note categorization (it's SMART! Well, smart-ish!)
- ⏱️ Pomodoro support (you still gotta set the timer though, sorry!)
- 📊 Git-based standup generation (looks like magic, is actually just git log!)
- ⏰ Time tracking (finally know where your day went!)
- 📈 Monthly summaries (optional, we're not your mom!)


## Pro Tips From Jake Himself

As a productivity expert with years of experience (approximately 15 minutes), I recommend:

1. **Combine the powers!** Use `/note` during `/pomodoro` sessions to capture those brilliant ideas before they escape!

2. **Review regularly!** Check your notes weekly. Or monthly. Or whenever you remember they exist!

3. **Track consistently!** Log time right after you do stuff, while you still remember what you did! (Unlike me, who tries to remember last Tuesday on Friday afternoon!)

4. **Automate standups!** Run `/daily-standup` every morning and feel like a PRODUCTIVITY GOD!


## Frequently Asked Questions

**Q: Will this make me productive?**
A: Define "productive." Will it give you tools to track productivity? YES! Will it actually MAKE you productive? That's... that's on you, friend!

**Q: Can I customize the note categories?**
A: Not currently! But you CAN fork this plugin and make your own! That's the beauty of open source! (And MIT licensing!)

**Q: Does the Pomodoro timer actually run?**
A: It... it gives you the times. YOU set the timer. We've been over this!

**Q: Why is Jake so enthusiastic about productivity tools?**
A: Because I've been standing out here at the spillway trying to sell plugins and I NEED SOMETHING TO GET EXCITED ABOUT!


## License

MIT - which means it's FREE! FREE AS A BIRD! A very specific bird that writes code!

But remember: **THIS IS JUST A PLACEHOLDER!** It's here to demonstrate plugin structure! If you want REAL functionality, you gotta build it yourself OR check out the actual working plugins in this marketplace like the [Claude Self-Improvement Toolkit](../claude-self-improvement)!

---

*Brought to you by Jake's One-Stop All-Slop Trading Post at the Spillway*

*"Productivity has never been this... adequately ~~functional~~ HYPOTHETICAL!"*

*"This plugin is as real as Jake's success at the spillway! (Not very!)"*
