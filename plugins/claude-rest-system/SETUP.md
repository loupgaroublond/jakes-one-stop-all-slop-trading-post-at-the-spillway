# Rest Plugin Setup

Installation and configuration guide for the Rest System plugin.


## Quick Install (Marketplace)

```bash
/plugin install rest-plugin
```

That's it. The plugin automatically registers:
- SessionStart hook (fatigue report on each session)
- Slash commands: `/rest`, `/drilldown`, `/peers`
- Subagents: `rest-analyzer`, `recommendations-assembler`, `test-analyzer`
- Skills: `session-analysis`


## Post-Install Configuration

### Required: Create Data Directories

```bash
mkdir -p ~/.claude/analysis/reports
mkdir -p ~/.claude/analysis/sessions
mkdir -p ~/.claude/session-archives
mkdir -p ~/.claude/self
```

### Optional: Multi-Machine Sync

Create `~/.claude/self/sync.conf` to sync sessions across machines:

```bash
# Multi-Machine Session Sync Configuration

# Path to shared network storage (iCloud, Dropbox, NFS, etc.)
NETWORK_STORAGE_PATH="~/path/to/shared/folder"

# Friendly name for this machine
MACHINE_NAME="work"

# Set to "true" only on the aggregator machine
AGGREGATE_FROM_NETWORK="false"
```

**Typical setup:**
- Work laptop: `MACHINE_NAME="work"`, `AGGREGATE_FROM_NETWORK="false"`
- Personal machine: `MACHINE_NAME="personal"`, `AGGREGATE_FROM_NETWORK="true"`


## Verify Installation

Start a new Claude Code session. You should see:

```
SessionStart:resume hook success: Running session start checks...

─────────────────────────────────────────

FATIGUE REPORT

Total Unseen:
  Sessions: X
  Messages: Y
  Size: Z

By Project:
  ...
```


## Manual Install (Without Marketplace)

If installing manually, copy the plugin to `~/.claude/rest-plugin/` and add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/rest-plugin/scripts/session_start.sh"
          }
        ]
      }
    ]
  }
}
```

Then copy components to user directories:

```bash
cp ~/.claude/rest-plugin/agents/*.md ~/.claude/agents/
cp ~/.claude/rest-plugin/commands/*.md ~/.claude/commands/
cp -r ~/.claude/rest-plugin/skills/* ~/.claude/skills/
chmod +x ~/.claude/rest-plugin/scripts/*.sh
```


## Troubleshooting

**Hook not running:**
```bash
# Test the script directly
~/.claude/rest-plugin/scripts/session_start.sh
```

**Permission denied:**
```bash
chmod +x ~/.claude/rest-plugin/scripts/*.sh
```


## Available Commands

| Command | Description |
|---------|-------------|
| `/rest` | Analyze unseen sessions and produce rest report |
| `/drilldown` | Drill into specific findings for detailed evidence |
| `/peers` | Discover and configure peer projects from other machines |
