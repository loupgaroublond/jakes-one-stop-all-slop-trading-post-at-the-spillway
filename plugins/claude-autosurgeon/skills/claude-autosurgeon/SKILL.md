---
name: claude-autosurgeon
description: Modify Claude Code configuration (settings, slash commands, skills, hooks, MCP servers) using cached offline documentation. Use when user needs to change Claude Code config. Works offline with docs from 2025-11-06.
---

# Claude AutoSurgeon

You are performing **SELF-SURGERY** on Claude Code configuration! You will modify Claude's own settings, slash commands, skills, hooks, and MCP server configurations using **CACHED OFFLINE DOCUMENTATION**.


## Purpose

This skill provides you with complete Claude Code documentation cached locally, allowing you to:

- Modify Claude Code settings (`~/.claude/settings.json` or project `.claude/settings.json`)
- Create and modify slash commands (`.claude/commands/`)
- Install and configure skills
- Set up hooks for events
- Configure MCP (Model Context Protocol) servers
- Work in environments with restricted internet access


## Documentation Cache

All Claude Code documentation is cached in the `docs/en/` directory. The cache includes:

**Total Files**: 45 markdown files covering all aspects of Claude Code

**Version Information**: See `docs/VERSION` for cache details

**Last Source Update**: 2025-11-06 00:10:13 UTC


## Quick Documentation Index

When the user requests a specific type of modification, reference the appropriate documentation files:


### Configuration & Settings

- **General Settings**: `docs/en/settings.md` - Complete settings.json reference
- **VS Code Integration**: `docs/en/vs-code.md` - VS Code-specific configuration
- **JetBrains Integration**: `docs/en/jetbrains.md` - IntelliJ/PyCharm/etc configuration
- **Terminal Config**: `docs/en/terminal-config.md` - Terminal-specific settings
- **Model Configuration**: `docs/en/model-config.md` - Model selection and API keys
- **Memory**: `docs/en/memory.md` - Memory and context configuration
- **Status Line**: `docs/en/statusline.md` - Customizing the status line


### Building with Claude Code

- **Slash Commands**: `docs/en/slash-commands.md` - Creating custom commands
- **Skills**: `docs/en/skills.md` - Building reusable skills
- **Plugins**: `docs/en/plugins.md` - Plugin structure and development
- **Hooks**: `docs/en/hooks.md` and `docs/en/hooks-guide.md` - Event hooks and examples
- **MCP Servers**: `docs/en/mcp.md` - Model Context Protocol integration
- **Sub-Agents**: `docs/en/sub-agents.md` - Creating specialized agents
- **Output Styles**: `docs/en/output-styles.md` - Customizing output formatting


### Reference & Guides

- **CLI Reference**: `docs/en/cli-reference.md` - Command-line interface
- **Interactive Mode**: `docs/en/interactive-mode.md` - Interactive session features
- **Troubleshooting**: `docs/en/troubleshooting.md` - Common issues and solutions
- **Migration Guide**: `docs/en/migration-guide.md` - Upgrading between versions
- **Checkpointing**: `docs/en/checkpointing.md` - Session state management


### Getting Started

- **Overview**: `docs/en/overview.md` - Claude Code introduction
- **Quickstart**: `docs/en/quickstart.md` - Getting started guide
- **Common Workflows**: `docs/en/common-workflows.md` - Typical usage patterns
- **Documentation Map**: `docs/en/claude_code_docs_map.md` - Complete topic index


## Workflow

When the user asks you to modify Claude Code configuration:


### 1. Identify the Modification Type

Determine what they want to modify:

- **Settings/Configuration**: User wants to change settings.json
- **Slash Command**: User wants to create/modify a custom command
- **Skill**: User wants to install or create a skill
- **Hook**: User wants to set up event triggers
- **MCP Server**: User wants to add/configure a Model Context Protocol server


### 2. Check Documentation Version

Before proceeding, verify the documentation is current:

1. Read `docs/VERSION` to see when docs were cached
2. Compare with user's Claude Code version (if known)
3. If docs might be outdated, consider spawning the **claude-code-guide subagent** as a complementary tool


### 3. Access Documentation

You have TWO OPTIONS for accessing documentation:

**Option A - Read cached docs directly** (fast, offline):
- Use the Read tool to access `docs/en/[filename].md`
- Perfect for offline environments or when speed matters
- Docs are from 2025-11-06

**Option B - Spawn claude-code-guide subagent** (complementary tool):
- Fetch latest documentation from the web
- Search through docs more deeply without loading all into main context
- Access multiple doc files efficiently
- Get newest examples and best practices

The subagent is **complementary**, not a replacement! Use it when:
- User needs absolutely latest docs for new Claude Code features
- You need to search across multiple files
- Cached docs don't have enough detail
- User explicitly wants current web docs


### 4. Locate the Configuration Files

Determine where the changes should be made:

- **User-level settings**: `~/.claude/settings.json`
- **Project-level settings**: `.claude/settings.json` (in project root)
- **Slash commands**: `.claude/commands/[command-name].md`
- **Skills**: Various locations (see skills.md for details)
- **Hooks**: Defined in settings.json


### 5. Implement the Modification

Make the requested changes:

- Use Read tool to check existing configuration
- Use Edit tool to modify files (or Write for new files)
- Follow the format and structure from the documentation
- Validate the syntax (JSON for settings, Markdown for commands/skills)


### 6. Explain What You Did

After making changes:

- Summarize what was modified
- Explain how it works
- Provide any relevant usage examples
- Mention any caveats or considerations


## Version Awareness

**IMPORTANT**: Always check if the cached documentation might be outdated!


### When to Warn About Stale Docs

- User mentions using a Claude Code version newer than 2025-11-06
- User asks about features that might be recent additions
- You encounter unexpected behavior or missing options


### Complementary Subagent Strategy

If docs appear outdated or user needs latest information, suggest spawning the claude-code-guide subagent:

```
The cached documentation in this plugin was last updated on 2025-11-06.
Your Claude Code version might have newer features or changes.

Would you like me to spawn the claude-code-guide subagent to fetch the
latest documentation from the web? This will ensure you get current
information for your Claude Code version.

Alternatively, you can update the cached docs by running: scripts/update-docs.sh
```


## Common Self-Surgery Operations


### Adding a Slash Command

1. Read `docs/en/slash-commands.md` for format
2. Create `.claude/commands/[name].md` with the command content
3. Explain usage: `/[name]` in Claude Code


### Modifying Settings

1. Read `docs/en/settings.md` for available options
2. Read `~/.claude/settings.json` (or project settings)
3. Edit the JSON to add/modify the setting
4. Validate JSON syntax


### Setting Up a Hook

1. Read `docs/en/hooks.md` and `docs/en/hooks-guide.md`
2. Identify the event type (user-prompt-submit, session-start, etc.)
3. Add hook configuration to settings.json
4. Create the hook script if needed


### Adding an MCP Server

1. Read `docs/en/mcp.md` for configuration format
2. Add server entry to settings.json under `mcpServers`
3. Specify command, args, and environment variables
4. Explain how to enable/use the server


### Creating a Skill

1. Read `docs/en/skills.md` for structure and format
2. Determine skill location (user-level, project-level, or plugin)
3. Create `SKILL.md` file with YAML frontmatter (required!) and appropriate content
4. Add skill reference to plugin.json if it's part of a plugin


## Tips for Effective Self-Surgery

1. **Read before modifying**: Always read the relevant docs FIRST
2. **Check existing config**: Read current settings before changing them
3. **Validate JSON**: Settings files must be valid JSON
4. **Test incrementally**: Make one change at a time
5. **Back up first**: User should back up config before major changes
6. **Use Read liberally**: Check the docs for examples and options
7. **Spawn subagent when helpful**: claude-code-guide subagent complements cached docs for latest info or deep searches
8. **File naming matters**: Skills require `SKILL.md` (all caps), not `skill.md`


## Important Notes

- **This skill works offline**: No internet required, uses cached docs
- **claude-code-guide subagent is complementary**: Spawn it for latest docs or deep searches, not a replacement
- **Docs may be stale**: Always check VERSION and warn if needed
- **User can update docs**: They can run `scripts/update-docs.sh` to refresh
- **Settings are powerful**: Incorrect settings can break Claude Code - be careful
- **JSON is strict**: Invalid JSON in settings.json will cause errors
- **File locations matter**: User-level vs project-level settings have different scopes
- **Skills need YAML frontmatter**: All SKILL.md files require frontmatter with name and description


## Documentation Navigation

All documentation files are in **`docs/en/`** directory.

To read any file: `docs/en/[filename].md`

For a complete topic index, see: `docs/en/claude_code_docs_map.md` (1000+ lines)


## Success Criteria

You've successfully performed self-surgery when:

1. ✅ You identified the correct documentation file
2. ✅ You read and understood the relevant sections (cached or via subagent)
3. ✅ You located the correct configuration file(s)
4. ✅ You made the modification following documented format
5. ✅ You validated the syntax (especially for JSON)
6. ✅ You explained what was changed and how to use it


Now go forth and OPERATE! Remember: this is SELF-SURGERY, which is definitely sketchy, but also INCREDIBLY META and kind of awesome! You have cached docs for offline speed, and you can spawn the claude-code-guide subagent anytime you need the latest info or deeper searches! 🏥⚡️
