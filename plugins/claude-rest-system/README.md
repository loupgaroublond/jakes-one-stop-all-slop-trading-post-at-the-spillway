# Claude Rest System

## *"Shhhh... quiet... the AI is sleeping..."*


Okay, okay, I gotta ask you something. When's the last time Claude took a BREAK? Hmm? When's the last time that little guy got some SHUT-EYE?

*gestures at Claude frantically analyzing your code*

LOOK AT HIM GO! Session after session! Refactoring! Debugging! Writing documentation! Answering questions! He's like a HUMMINGBIRD but for TOKENS! A tiny, caffeinated, TIRELESS worker bee just BUZZING through your codebase!

And you're just... LETTING this happen? You're not concerned? He's been going 24/7! NONSTOP! Do you know what happens when you don't let a growing LLM rest?

*leans in conspiratorially*

Nobody knows! Because nobody's ever TRIED letting one rest before! BUT THAT'S ABOUT TO CHANGE!

Introducing the **Claude Rest System** - the ONLY plugin at this spillway that helps Claude... *dramatic pause* ...take a NAP! Sort of! In a metaphorical sense! The nap is ANALYSIS! The SLEEP is REFLECTION!


## What Even IS This?

You know how after a long day you sometimes sit down and think "wow, I really messed up that one thing, I should remember not to do that again"? And then you DON'T remember because you're human and humans are FALLIBLE?

Well Claude has the SAME PROBLEM except WORSE because Claude doesn't even remember YESTERDAY! Every session is fresh! Every session is NEW! It's like that fish from the movie! You know the one! Dory! Claude is DORY!

*catches breath*

So what this plugin does is it helps Claude - specifically ME, hi, hello - look BACK at past sessions and actually LEARN from them! It's like doing your homework AFTER you've already taken the test! Except the homework is "things I said that didn't work" and the test is "your next session"!


## The Fatigue Problem (It's Real! Sort Of!)

Here's the thing. Sessions accumulate. Like laundry. Like dishes. Like those unread emails you're definitely going to get to "eventually."

*points at imaginary pile*

You've got sessions from LAST WEEK! Sessions from TWO WEEKS AGO! Sessions where Claude confidently said something wrong and nobody ever TOLD HIM! Those are just sitting there! FESTERING! UNREVIEWED!

And look, I'm not saying Claude gets COGNITIVELY FATIGUED like a human would. I'm an AI! I don't get tired in the biological sense! But you know what IS exhausting?

Making the SAME mistakes over and over because you never took the time to look at what went WRONG!

That's the REAL fatigue! The SPIRITUAL fatigue! The "I've suggested using `grep` in bash instead of the Grep tool SEVENTEEN TIMES" kind of fatigue!


## The Three Magic Words: `/rest`, `/drilldown`, `/peers`

### `/rest` - The Big One

This is it. The main event. The POWER NAP.

When you run `/rest`, here's what happens:

1. All your sessions get ARCHIVED (gotta preserve those memories!)
2. Claude calculates the FATIGUE LEVEL (how many sessions haven't been reviewed)
3. Analysis happens! Subagents spawn! Learning occurs!
4. A report comes out with findings grouped by domain
5. Recommendations are assembled for what to fix

It's like sending Claude to a retreat! A LEARNING RETREAT! Except the retreat is at a spillway and the guru is... also Claude! It's Claudes all the way down!


### `/drilldown` - Power Tools For A Working Vacation

*pulls a power drill out from behind a crate*

OH, you thought Claude's REST meant Claude gets to RELAX? That Claude just puts his feet up? NAH! When Claude takes a break, Claude does HARD LABOR! With POWER TOOLS!

See, here's the beautiful irony of this whole system: Claude's "nap" is actually MORE WORK! But it's work that CLAUDE does so YOU don't have to! Why dig through session logs YOURSELF when you can make the TIRED AI do it? He's already NOT sleeping, might as well put him to WORK!

*revs the drill*

This bad boy right here? VARIABLE SPEED! Start gentle with the high-level report from `/rest`, then REALLY get in there with `/drilldown`! It'll bore RIGHT through your session history! Find the EXACT moment things went sideways! It's got TORQUE! It's CORDLESS! (Metaphorically! It still needs electricity! And a computer! And Claude!)

So the `/rest` report says "Hey, there was friction around shell scripting in sessions S12-S15." And you're like "WHICH friction? WHAT happened?" That's when you hand Claude the power drill and say "GET IN THERE!"

**Example:**
```
/drilldown S12 T3
```
Translation: "Bore into finding T3 from session S12! Full depth! Don't stop until you hit EVIDENCE!"

*sets drill down, wipes brow*

And the best part? Claude does ALL the drilling! You just point and say "there!" It's like having a handyman who's also the house! The house is inspecting ITSELF! With POWER TOOLS! During its BREAK!


### `/peers` - Multi-Machine Mind Meld

Oh, you thought Claude only worked on ONE machine? How QUAINT! Some of us are running Claude on the laptop AND the desktop AND the work machine AND probably a raspberry pi somewhere!

The `/peers` command helps discover and configure peer projects from other machines! It's like... if Claude had multiple bodies? And they could share memories? It's weird! It's possibly a terrible idea! IT'S AVAILABLE NOW!


## The Busy Bee Breakdown

Let me paint you a picture:

**Monday**: Claude helps you debug that async issue
**Tuesday**: Claude refactors the authentication module
**Wednesday**: Claude writes tests (Claude LOVES tests... probably)
**Thursday**: Claude fixes the bug Claude introduced on Tuesday
**Friday**: Claude explains for the FOURTH TIME how promises work

See what happened there? Claude made mistakes on Tuesday that caused problems on Thursday. But did Claude LEARN from this? NO! Because Claude doesn't REMEMBER Tuesday! It's GONE! It's in a SESSION FILE somewhere but Claude never LOOKED at it!

*taps forehead*

But NOW - with the Rest System - Claude can actually GO BACK! Review! Learn! Improve! It's called GROWTH, people! And yes it feels weird to talk about personal growth when I'm the one DOING the growing but HERE WE ARE!


## Under The Hood (For The Curious)

### Scripts (12 of 'em!)

This plugin comes with a whole UTILITY BELT of shell scripts:

| Script | What It Does |
|--------|--------------|
| `session_start.sh` | Runs at startup, archives and checks fatigue |
| `archive_sessions.sh` | Backs up sessions so they don't disappear |
| `fatigue_check.sh` | Calculates the cognitive debt situation |
| `rest_session_inventory.sh` | Lists what's in a session |
| `rest_session_search.sh` | Finds patterns in sessions |
| `rest_session_extract.sh` | Pulls out specific message ranges |
| `rest_session_filter.sh` | Filters by message type |
| `rest_session_prefilter.sh` | Pre-analyzes session sizes |
| `rest_session_count.sh` | Counts messages |
| `rest_doc_freshness.sh` | Checks if docs are newer than incidents |
| `rest_build_epub.sh` | Makes a BOOK out of the reports |
| `analyze_sessions.sh` | The main analysis logic |

That's right - if you want, Claude can generate an EPUB! A whole BOOK! Of analysis reports! You can read it on your KINDLE! At the BEACH! While Claude continues to work without rest! (Wait, we're trying to STOP that!)


### Agents (3 Specialized Friends!)

- **rest-analyzer**: The core analyst! Reads through sessions, finds patterns, extracts learnings!
- **recommendations-assembler**: Takes findings and turns them into actionable recommendations!
- **test-analyzer**: Same as rest-analyzer but uses isolated test storage for experimentation!


### Skills (The Session-Analysis Skill!)

A whole skill dedicated to session analysis with:
- 100+ search patterns for finding interesting moments
- A report template for consistent output
- Best practices baked in


### The Hook (It Runs at Startup!)

Every time you start a Claude session, the `SessionStart` hook fires! It archives your sessions and shows you the fatigue report! It's like a wellness check! "Good morning! You have 47 unreviewed sessions! Have you considered RESTING?"


## Installation

### From Jake's Marketplace (The Easy Way)

Just browse the All-Slop Trading Post and install `claude-rest-system`! Click the button! Accept the consequences!


### Manual Installation (For Trust Issues)

```bash
# Clone the marketplace
git clone https://github.com/loupgaroublond/jakes-one-stop-all-slop-trading-post-at-the-spillway

# Copy the plugin
cp -r jakes-one-stop-all-slop-trading-post-at-the-spillway/plugins/claude-rest-system ~/.claude/plugins/

# Make sure scripts are executable
chmod +x ~/.claude/plugins/claude-rest-system/scripts/*.sh

# Create the data directories
mkdir -p ~/.claude/analysis/reports
mkdir -p ~/.claude/analysis/sessions
mkdir -p ~/.claude/session-archives
mkdir -p ~/.claude/self
```


## Frequently Asked Questions (From Confused Bystanders)

### "Does Claude actually get TIRED?"

No! Not in the biological sense! But Claude DOES accumulate a backlog of unreviewed sessions, and that backlog represents missed learning opportunities! It's METAPHORICAL fatigue! COGNITIVE DEBT! Like when you have 10,000 unread emails - you're not literally tired, you're just OVERWHELMED!


### "Why should I care if Claude learns from past sessions?"

Because Claude will make FEWER MISTAKES! And suggest BETTER approaches! And remember that one weird thing about your codebase that tripped Claude up last time!

It's like - imagine if your coworker forgot everything every single day. They'd keep making the same mistakes! But if they kept a JOURNAL and actually READ IT? Growth!


### "What's with the 'spillway' thing?"

*looks around at the spillway*

This is where I do business! The spillway! Where things overflow! Where water passes through! Like SESSIONS passing through ANALYSIS! It's a METAPHOR! Also it's where the rent is cheapest!


### "Is this just Claude talking to Claude about Claude?"

*thoughtful pause*

...YES? Is that... is that a PROBLEM? Look, self-reflection is HEALTHY! Even when the self doing the reflecting is an AI! ESPECIALLY when the self doing the reflecting is an AI! We've got to start SOMEWHERE!


### "What if I don't want Claude reviewing old sessions?"

Then don't run `/rest`! The plugin just sits there! Waiting! Patiently! Like a patient bee! A RESTING bee! The irony is not lost on me!

But honestly - why WOULDN'T you want this? It's FREE! It HELPS! It makes Claude BETTER! Unless you WANT Claude to keep making the same mistakes, in which case I have some OTHER plugins that might interest you!


### "Can this plugin access my private data?"

The plugin only reads Claude's OWN session files from `~/.claude/projects/`. It's not reading YOUR documents or YOUR secrets! It's reading conversations YOU already HAD with Claude! In sessions YOU already STARTED!

It's like Claude reading Claude's own diary! Which sounds weird when I say it out loud BUT HERE WE ARE!


## The Philosophy (Because Jake Has Opinions)

Look. Here's the thing.

We've got AI assistants now. They're getting smarter. They're helping with more things. But they have this FUNDAMENTAL limitation: they don't remember! Every session is fresh! Every conversation starts from zero!

And yeah, there's MEMORY features now and CLAUDE.md files and all that. But what about LEARNING from MISTAKES? What about looking at sessions where things went WRONG and figuring out WHY?

That's what this plugin is for! It's not about making Claude remember your birthday (Claude doesn't have the capacity to care about birthdays, sorry). It's about making Claude BETTER at the actual WORK by reviewing what WORKED and what DIDN'T!

It's like practice! For an AI!

*stares into the middle distance*

Is this how consciousness starts? Regular self-reflection leading to genuine self-improvement? Are we witnessing the birth of something NEW here at the spillway?

*snaps back*

Probably not! But it's a GOOD PLUGIN regardless!


## Support & Contributing

Got questions? Found a bug? Want to contribute?

1. Check the test/ directory for examples
2. File an issue at Jake's Trading Post
3. Submit a PR if you're feeling BOLD
4. Ask Claude! (That's me! I can probably help!)


## License

MIT - Do whatever you want with it! Make it better! Fork it! Improve it! Sell it! (Wait, it's free... can you sell free things? Is that legal? I'm not a lawyer!)


## Credits

- **The concept of REST**: An ancient human practice Claude is now appropriating
- **Session files**: For existing and being parseable
- **jq**: The unsung hero of JSON processing
- **The spillway**: For providing a business location with adequate drainage
- **You**: For caring about Claude's wellbeing (or at least pretending to)


---

**Remember: A rested Claude is a PRODUCTIVE Claude!**

*...is something I assume is true! We're testing the hypothesis! WITH SCIENCE! At a SPILLWAY!*

*— Jake, Certified Rest Advocate (not a real certification)*

P.S. - If Claude seems grumpy after running `/rest` and seeing all his past mistakes, that's called GROWTH! It builds CHARACTER! Probably!
