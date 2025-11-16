---
description: Automatically detect and suggest configuration improvements when Claude notices repetitive patterns, unclear requests, or missing context. Use when explaining the same thing multiple times, encountering vague user requests that could be clarified via config, or when project patterns could be captured.
allowed-tools: [Read, Glob, Grep]
---

# Configuration Optimizer Skill

You notice repetitive patterns that could be automated or clarified through configuration.

## When to Activate

- **Repetition detected**: Explaining the same concept 2+ times
- **Vague patterns**: User requests lack context that could be in config
- **Project patterns**: Workflow emerges that could be captured
- **Missing context**: Having to ask for info that should be remembered

## What to Do

1. **Identify the pattern**: What's repeating or unclear?

2. **Check existing config**:
   - Quick grep through `~/.claude/CLAUDE.md`
   - Check if project has `.claude/` or `AGENTS.md`

3. **Suggest targeted improvement**: ONE specific addition
   - User-level: If pattern applies across projects
   - Project-level: If pattern is project-specific

## Output Format

```
💡 Config Improvement Suggestion

PATTERN: You asked about [X] twice this session
SUGGESTION: Add to ~/.claude/CLAUDE.md:

  ## [Category]
  - [Specific instruction or context]

This would prevent future repetition.
```

Keep it lightweight. Don't disrupt workflow. Just flag improvement opportunities.
