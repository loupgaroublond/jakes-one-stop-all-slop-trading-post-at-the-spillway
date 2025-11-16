---
description: Analyze and optimize Claude configuration files for clarity and effectiveness
---

Review Claude configuration files and suggest improvements:

**Check these locations:**
- `~/.claude/CLAUDE.md` - User-level memory
- `~/.claude/commands/*.md` - Custom commands
- `~/.claude/agents/*.md` - Custom agents
- `<project>/.claude/` - Project configs (if exists)
- `<project>/AGENTS.md` or `CLAUDE.md` - Project memory

**Look for:**
- Vague or unclear instructions
- Duplicate/redundant configurations
- Missing tool restrictions
- Outdated patterns
- Configuration bloat

**Suggest improvements:**
- Make instructions more specific and actionable
- Consolidate duplicate logic
- Add missing tool restrictions for security
- Remove obsolete configurations
- Reorganize for clarity

Present findings as prioritized list: HIGH/MEDIUM/LOW impact changes.
