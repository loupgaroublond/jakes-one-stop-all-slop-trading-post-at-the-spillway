# Rest Plugin Setup

Installation and configuration guide for the Claude Rest System plugin.


## Quick Install (Marketplace)

```bash
# Add the marketplace (if not already added)
/plugin marketplace add loupgaroublond/jakes-one-stop-all-slop-trading-post-at-the-spillway

# Install the plugin
/plugin install claude-rest-system@all-slop-marketplace
```

The plugin automatically registers:
- SessionStart hook (silently archives sessions)
- Slash commands: `/yawn`, `/rest`, `/drilldown`, `/rewind`, `/peers`
- Subagents: `rest-analyzer`, `recommendations-assembler`, `rewind-agent`, `test-analyzer`
- Skills: `session-analysis`


## Post-Install Configuration

### Required: Create Data Directories

On first install, the plugin will prompt you to set up directories. Ask Claude:

> "Set up the Claude Rest System for me"

Or manually create:

```bash
mkdir -p ~/.claude/analysis/reports
mkdir -p ~/.claude/analysis/sessions
mkdir -p ~/.claude/session-archives
```


### Optional: Multi-Machine Sync

Create `~/.claude/sync.conf` to sync sessions across machines:

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

Run `/yawn` to check the fatigue level:

```
/yawn
```

You should see a fatigue report showing unseen sessions by project.


## Updating the Plugin

```bash
/plugin marketplace update all-slop-marketplace
/plugin uninstall claude-rest-system@all-slop-marketplace
/plugin install claude-rest-system@all-slop-marketplace
```


## Available Commands

| Command | Description |
|---------|-------------|
| `/yawn` | Check fatigue level - how many sessions need review |
| `/rest` | Analyze unseen sessions and produce rest report |
| `/drilldown` | Drill into specific findings for detailed evidence |
| `/rewind` | Search current session for events lost to context compaction |
| `/peers` | Discover and configure peer projects from other machines |
