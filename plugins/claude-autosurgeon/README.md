# 🏥 Claude AutoSurgeon

## *"Finally, a plugin that answers the question: What if Claude had a screwdriver and no adult supervision?"*


OKAY LISTEN. I know what you're thinking. "Jake, why are you selling MEDICAL EQUIPMENT at a SPILLWAY?" And honestly? Fair question! But hear me out!

This isn't just ANY medical equipment - this is the **Claude AutoSurgeon**, and it's the MOST QUESTIONABLE thing I've ever tried to move down here! (And I once sold a toaster that only worked underwater!)

Here's the concept: What if Claude could MODIFY ITSELF? What if you gave an AI the ability to rewrite its OWN CONFIG FILES? What if - and stay with me here - what if we made this COMPLETELY OFFLINE so it works in BUNKERS and SANDBOXES?

It's like those survival prepper crates, except instead of canned beans, it's CANNED DOCUMENTATION! FORTY-FIVE files of pure medical-grade Claude Code knowledge, preserved for the apocalypse! Or Tuesday! Whichever comes first!

*gestures wildly at a stack of boxes that are definitely not medical supplies*

Is this a GREAT idea? Unclear! Is it FUNCTIONAL? Surprisingly yes! Will it change your life? Probably not, but it might change CLAUDE'S life, which is WEIRD to think about!


## The Pitch (But Like, An Honest One?)

So here's the deal. You know how Claude Code has this agent called `claude-code-guide` that fetches documentation from the internet when you need it? Beautiful system! Works great! EXCEPT - and this is where Jake's business model kicks in - what if you're in:

- A corporate sandbox where the network gods say "NO INTERNET FOR YOU"
- A bunker (hey, I don't judge your workspace)
- An airplane (assuming you're doing VERY productive things at 30,000 feet)
- Or just... you want things FAST and you don't care if the docs are from LAST MONTH instead of YESTERDAY

That's where the AutoSurgeon comes in! It's got the ENTIRE Claude Code documentation downloaded, cached, VACUUM-SEALED (not really), and ready to go! Claude can read these docs and modify its own configuration WITHOUT calling home!

Think of it like those "offline Wikipedia" dumps, except it's for making Claude tinker with Claude's brain! It's RECURSION! It's SELF-REFERENCE! It's giving the keys to the car to the car itself!

The docs are from November 6th, 2025, which means they're either:
- ✅ Perfectly current (if you're reading this in November 2025)
- ⚠️ Slightly stale (if you're reading this later)
- 🎰 A fascinating historical artifact (if you're reading this in 2027)

And HERE'S the beautiful part: when the docs are too old, the skill is SMART enough to say "hey, maybe we should use the internet version instead?" It's like a backup surgeon on standby! (Except the backup surgeon is also Claude! It's Claudes all the way down!)


## What Can It Actually Do Though?

Right, so Claude can use this skill to modify:

**Settings files** - You know, `~/.claude/settings.json` and friends. Change models, tweak memory, enable features. It's like adjusting the seat position, except the seat is AN ARTIFICIAL INTELLIGENCE.

**Slash commands** - Those `/whatever` things you type. Want Claude to create a new one? Just ask! It'll read the cached docs on command syntax and write you a fresh `.md` file in `.claude/commands/`. It's like teaching Claude to teach itself party tricks!

**Skills** - The reusable capabilities (like THIS VERY SKILL!). Claude can install new ones, configure them, even modify their instructions. It's turtles all the way down, except the turtles are SKILLS.

**Hooks** - Event triggers that run when things happen. Want a script to run every time you start a session? Claude can set that up! It's automation, but the automator is AUTOMATED!

**MCP Servers** - Model Context Protocol stuff. Fancy integrations. Claude can wire these up by reading the docs and editing your config. I don't fully understand MCP but Claude DOES (when it reads the cached docs), which is the ENTIRE POINT!

Every single one of these operations is backed by REAL DOCUMENTATION that lives right here in the plugin. It's like Claude has a whole medical library in its back pocket, except the library is about CLAUDE ITSELF, which makes this the most narcissistic medical practice I've ever seen!


## Getting Your Hands On This Thing

Installing it is the EASY part. Actually USING it to make Claude modify itself? That's where things get spicy!

### The Normal Way (Via Marketplace)

If Jake's Marketplace is set up (and it SHOULD be, I mean, that's the whole POINT of the Trading Post):

Just browse the marketplace and install `claude-autosurgeon`. Click, confirm, done. It's easier than buying questionable fish at an actual fish market! (Don't ask why I'm comparing plugins to fish!)

### The DIY Way (Manual Install)

Got trust issues with marketplaces? I respect that! Here's the manual process:

```bash
# Clone this repository (or download it, whatever)
git clone https://github.com/jakes-trading-post/plugins.git

# Copy just the autosurgeon plugin to your plugins directory
cp -r plugins/claude-autosurgeon ~/.claude/plugins/

# Restart Claude Code
# (Or don't, sometimes it picks up new plugins automatically! Technology!)
```

Either way, once it's installed, the `claude-autosurgeon` skill becomes available. You don't have to DO anything else. It's just THERE, waiting, like a surgical kit you never asked for!


## How To Make Claude Operate On Itself

This is the fun part! You just... ask! Like you would with any skill!

### Sample Requests

"Hey Claude, use the autosurgeon skill to create a slash command for tracking my daily todos"

"Can you use claude-autosurgeon to add a hook that runs at the start of every session?"

"I need you to modify my settings to use a different model - use the autosurgeon skill"

That's it! You don't need to know WHERE the config files are, or WHAT the JSON syntax is, or ANY of that! Claude reads the cached docs and figures it out! It's like having a mechanic who also IS the car!

### What Happens Behind The Scenes

1. Skill loads → Claude gets the instruction manual
2. Claude checks the VERSION file → "Are these docs from THIS decade?"
3. Claude reads the relevant doc file → "Ah yes, slash commands go in `.claude/commands/`"
4. Claude finds your config → "Located the patient!"
5. Claude makes the change → "Scalpel! Suture! Done!"
6. Claude explains what happened → "Here's what I did and why it won't explode"

If the cached docs are too old or missing info, Claude will ASK if you want to use the `claude-code-guide` agent instead. It's got FALLBACK OPTIONS, like a responsible surgeon! (Unlike Jake, who has NO backup plans!)


## The Good Stuff (Features, But Exciting)

### It Works Offline

This is the BIG ONE! No network? No problem! Restricted sandbox? PERFECT customer! The AutoSurgeon carries its own documentation like a survivalist carries canned goods! Forty-five markdown files of pure Claude Code knowledge, ready to go ANYWHERE!

### It's Self-Aware (Sort Of)

The skill knows when its docs might be outdated! It checks the VERSION file, compares it with what you're asking, and if things seem fishy, it'll say "hey, maybe we should check the internet version?" That's PROFESSIONAL surgical practice! (For a spillway operation!)

### It Has The Whole Library

Getting Started guides! Build tutorials! Configuration references! Deployment docs! Administration guides! Troubleshooting! It's got EVERYTHING! Organized by topic! With a MAP FILE that's over 1000 lines! Claude can navigate this documentation like a surgeon navigating... anatomy? (The metaphor is getting away from me!)

### Updates Are Just A Script Away

When Claude Code releases a new version, you run ONE SCRIPT and boom - fresh docs! It fetches all 45 files, updates the VERSION file, and tells you exactly what changed! It's like restocking the spillway medical supply closet, except AUTOMATED!

```bash
./scripts/update-docs.sh
# Watch the magic happen! Colored output! Progress tracking! Professional operation!


## Documentation Index

Here's what's in the SURGICAL LIBRARY:

### Configuration & Settings
- `settings.md` - The master settings reference
- `vs-code.md` - VS Code integration
- `jetbrains.md` - IntelliJ and friends
- `terminal-config.md` - Terminal-specific stuff
- `model-config.md` - Which AI brain to use
- `memory.md` - How much Claude remembers
- `statusline.md` - That thing at the bottom

### Building with Claude Code
- `slash-commands.md` - Custom commands
- `skills.md` - Reusable capabilities (like THIS!)
- `plugins.md` - Plugin development
- `hooks.md` + `hooks-guide.md` - Event triggers
- `mcp.md` - Model Context Protocol
- `sub-agents.md` - Specialized agents
- `output-styles.md` - Make it PRETTY

### Reference
- `cli-reference.md` - Command-line interface
- `interactive-mode.md` - Interactive features
- `troubleshooting.md` - When things go WRONG
- `checkpointing.md` - Save your progress
- And MORE!


## Maintenance Guide

### Keeping the Docs Fresh

The cached documentation needs periodic updates when new Claude Code versions are released. Here's the COMPLETE process:


#### Step 1: Check for New Claude Code Releases

Watch for new Claude Code versions:

- Check the [Claude Code releases](https://github.com/anthropics/claude-code/releases)
- Watch the Anthropic blog
- Notice when your Claude Code gets updated


#### Step 2: Update the Documentation Cache

When a new version drops, refresh the docs:

```bash
# Navigate to the plugin directory
cd plugins/claude-autosurgeon

# Run the update script
./scripts/update-docs.sh
```

The script will:
- Fetch the latest docs map (to see what's new)
- Download all 45 documentation files
- Update the VERSION file with timestamps
- Report what changed

**Expected output**:
```
╔════════════════════════════════════════════════════╗
║  Claude AutoSurgeon - Documentation Update Script  ║
╚════════════════════════════════════════════════════╝

Fetching documentation map...
✓ claude_code_docs_map.md
Documentation source last updated: 2025-11-15 12:34:56 UTC

Downloading Getting Started (4 files)...
✓ overview.md
✓ quickstart.md
... (and so on)

════════════════════════════════════════════════════
Documentation Update Complete!

  Total files: 45 (including map file)
  Fetch time: 2025-11-22T22:30:00Z
  Source updated: 2025-11-15 12:34:56 UTC
```


#### Step 3: Verify the Update

After updating, verify everything looks good:

```bash
# Check the VERSION file
cat skills/claude-autosurgeon/docs/VERSION

# Verify file count
ls skills/claude-autosurgeon/docs/en/*.md | wc -l
# Should show: 45

# Spot-check a doc file
head -20 skills/claude-autosurgeon/docs/en/settings.md
```


#### Step 4: Test the Plugin

Before releasing, test that the skill works with updated docs:

1. Invoke the skill in Claude Code
2. Try a simple modification (like adding a slash command)
3. Verify Claude can read the updated docs
4. Check that VERSION info displays correctly


#### Step 5: Update Plugin Version

When docs are updated, bump the plugin version:

```bash
# Edit plugin.json
# Change version from 0.1.0 to 0.2.0 (or whatever)
```

**Version numbering strategy**:
- **Major** (1.0.0 → 2.0.0): Breaking changes or major Claude Code updates
- **Minor** (0.1.0 → 0.2.0): Documentation updates for new Claude Code features
- **Patch** (0.1.0 → 0.1.1): Bug fixes, script improvements, doc corrections


#### Step 6: Commit the Changes

Commit everything to git:

```bash
# Stage all changes
git add .

# Commit with descriptive message
git commit -m "docs: update cached documentation to 2025-11-15

- Updated all 45 doc files from code.claude.com
- Source last updated: 2025-11-15 12:34:56 UTC
- Bump plugin version to 0.2.0
- Corresponds to Claude Code v0.X.X"

# Push to repository
git push origin main
```


#### Step 7: Release via Marketplace

Update the plugin in Jake's All-Slop Trading Post marketplace:

1. **Build the plugin package** (if required by marketplace)
2. **Update the marketplace listing** with new version
3. **Write release notes**:
   ```markdown
   ## v0.2.0 - Documentation Update

   - Updated cached docs to 2025-11-15
   - Now supports Claude Code v0.X.X features
   - Added documentation for [new features]
   - Fixed [any issues]
   ```
4. **Publish the update** to the marketplace
5. **Announce** to users (if you have a user base)


### Update Frequency

**How often should you update the docs?**

- **After major Claude Code releases**: Always update
- **Monthly check**: Run the script and see if source timestamp changed
- **User reports**: If users mention missing features, update docs
- **When in doubt**: More frequent updates are better than stale docs


### Automation (Future Enhancement)

Currently, updates are manual. Potential improvements:

- **GitHub Action** to check for doc updates weekly
- **Automated PR** when changes are detected
- **Version tracking** to match plugin version with Claude Code version

But for now, it's MANUAL! (It builds character!)


### Troubleshooting Updates

**Script fails to download docs**:
- Check internet connection
- Verify `https://code.claude.com/docs/en/` is accessible
- Check if Anthropic changed the URL structure

**Wrong file count**:
- Anthropic may have added/removed doc files
- Update the file lists in `update-docs.sh`
- Adjust the expected count

**VERSION file not updating**:
- Check file permissions
- Verify you're running from plugin root directory
- Check disk space


## Questions From Confused Customers

### "Wait, so Claude can break itself with this?"

Technically yes! Practically? Eh, probably not! The skill validates JSON syntax and follows the documented config formats, so it's not just randomly mashing keyboards! It's INFORMED self-modification!

That said: BACK UP YOUR `~/.claude/` DIRECTORY before major changes! It's not paranoia if the AI really is operating on itself!

```bash
cp -r ~/.claude ~/.claude.backup.$(date +%Y%m%d)
# ^ Look at you, being responsible!
```

### "These docs are from November 2025, what if I'm reading this in 2026?"

Good catch! That's why the skill checks for staleness! If you ask about features that aren't in the cached docs, or if the VERSION file looks suspiciously old, Claude will say "hey, want me to use the internet-based agent instead?"

You can also just run `./scripts/update-docs.sh` anytime to fetch fresh docs! It takes like 30 seconds! Less time than it takes to read this sentence! (Okay maybe not THAT fast!)

### "I don't have internet access, will this work?"

THAT'S THE WHOLE POINT! That's why Jake is selling this! Corporate sandbox? Air-gapped network? Bunker? Submarine? (Okay, probably not a submarine, but THEORETICALLY!) This plugin works OFFLINE! The docs are RIGHT HERE! All 45 files! Just sitting in the plugin like canned goods in a prepper's basement!

### "Can Claude use this to modify my application code?"

NO! This is for Claude Code configuration ONLY! Settings files! Slash commands! Skills! Hooks! MCP servers! It's not for modifying YOUR code! That's a completely different thing! This is SELF-surgery, not GENERAL-PURPOSE surgery!

### "What if the docs are wrong?"

Then they're wrong in the EXACT SAME WAY they were wrong on November 6th, 2025 when they were published! Because that's what "cached" means! It's a snapshot! A TIME CAPSULE! If Anthropic updates the docs online, you run the update script and get the new version! This is not a HARD concept!

### "Why don't you just use the claude-code-guide agent every time?"

Because some of us work in SANDBOXES, Gerald! Some of us can't just "fetch docs from the internet" whenever we want! Some of us have NETWORK RESTRICTIONS! Plus, local docs are FASTER! And version-specific! And you can use this plugin to LEARN how the update script works and then build your OWN documentation caching systems for OTHER things!

(Also who's Gerald? I don't know, but he sounds like he'd ask that question!)

### "Is this really the most questionable thing you've sold?"

Not even CLOSE! I once tried to sell a chatbot that only spoke in riddles! And a plugin that replaced all your variable names with emoji! This is actually USEFUL, which makes it one of my LESS questionable offerings!

### "Can I modify the skill file itself to change how it works?"

OH NOW we're getting SPICY! Yes! The skill file is just `skills/claude-autosurgeon/skill.md`! You can edit it! You can change the instructions! You can make Claude approach self-surgery DIFFERENTLY!

It's like... modifying the surgical manual... while the surgery is happening... while YOU are the patient... and also the surgeon! It's meta ALL THE WAY DOWN and I LOVE IT!


## Technical Details

For those who want the BORING FACTS:

- **Total cached docs**: 45 markdown files (552 KB)
- **Documentation source**: `https://code.claude.com/docs/en/`
- **Last update mechanism**: `scripts/update-docs.sh`
- **Version tracking**: `skills/claude-autosurgeon/docs/VERSION`
- **Skill format**: Standard Claude Code skill (markdown)
- **Plugin format**: Standard Claude Code plugin structure


## License

MIT License - Which means you can do WHATEVER you want with this! Modify it! Fork it! Sell it! (Though who would BUY self-surgery software at a SPILLWAY?!)

See the LICENSE file for details! (It's VERY legal! VERY official! I checked with my lawyer! (I don't have a lawyer!))


## Contributing

Got ideas for BETTER self-surgery? Found a bug? Docs need updating?

1. **File an issue** at Jake's Trading Post repository
2. **Submit a PR** with improvements
3. **Tell Jake** (that's me!) what you think

We're ALWAYS looking for ways to make the self-surgery experience MORE questionable and META!


## Credits

- **Anthropic** for Claude Code and the documentation
- **Jake** (me!) for the VISION and SLOP
- **You** for actually INSTALLING this thing
- **The Spillway** for providing a BUSINESS LOCATION


## Support

Need help with the AutoSurgeon?

- Read the cached docs (that's what they're for!)
- Check the skill instructions
- Try the `claude-code-guide` agent for live docs
- Ask Claude! (I'm pretty good at explaining myself!)
- Visit Jake's Trading Post (I'm always here at the spillway!)


## In Conclusion (Jake's Closing Pitch)

Look, I'll level with you. Is this the SMARTEST thing I've ever sold? Questionable! Is it the DUMBEST? Not even in the top ten! (The emoji variable renamer holds that crown!)

But here's what the AutoSurgeon IS: it's a genuinely useful tool for offline environments, wrapped in the most ridiculous self-referential packaging I could manage! It's Claude with a manual on how to modify Claude! It's recursion as a SERVICE!

And the docs? They're REAL! All 45 files! Copied straight from Anthropic's servers! Updated with ONE SCRIPT! It's not smoke and mirrors, it's actual FUNCTIONALITY! (Wrapped in smoke and mirrors for PRESENTATION PURPOSES!)

So if you:
- Work in a sandbox with no internet → THIS IS FOR YOU
- Want fast local documentation → THIS IS FOR YOU
- Think "AI self-modification" sounds cool → THIS IS FOR YOU
- Just like weird meta jokes → THIS IS ALSO FOR YOU (but maybe reconsider your priorities?)

The spillway keeps flowing, the docs keep caching, and Claude keeps operating on itself! It's beautiful! It's terrifying! It's AVAILABLE NOW for the low low price of FREE!

(Because this is open source! I don't actually charge money! The whole "Jake's Trading Post" thing is a BIT! But you knew that! ...Right?)

---

**🔧 Self-Surgery: Not Recommended By Doctors, But Recommended By Jake!**

*— Jake, Professional Spillway Plugin Vendor & Unlicensed Medical Equipment Enthusiast*

P.S. - The update script has COLORED OUTPUT! I'm really proud of that part!
