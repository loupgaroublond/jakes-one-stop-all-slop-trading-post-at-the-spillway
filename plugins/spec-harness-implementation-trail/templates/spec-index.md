# 000 — Formal Specification Index

**Status:** draft
**Last Updated:** (fill in)

## Purpose

Traceability matrix mapping every PRD section to its spec module(s). Every requirement in the PRD must be covered by at least one spec module.

This file is the entry point for `/shit:audit-spec` and `/shit:spec-status`. Keep the tables below current as you add modules and requirements.

## PRD Coverage Matrix

Map each PRD section to the spec module(s) that cover it. Sections that are context-only (no testable requirements) can be marked with `—` in the Spec Module column.

| PRD Section | Title | Doc # | Spec Module(s) | Status |
|-------------|-------|-------|----------------|--------|
| _Add rows as you write your PRD._ | | | | |

## Coverage Summary

- **Total PRD sections:** _(fill in)_
- **Covered by spec:** _(fill in)_
- **Context-only (no spec needed):** _(fill in)_
- **Gaps:** _(list uncovered sections)_

## Module Status Overview

Every spec module gets one row. The `Prefix` column is the requirement ID prefix used in that module (e.g., `REQ-AUTH`). The counts are scanned from the module files by `/shit:spec-status`.

| Doc # | Module | Prefix | Status | Active | Dropped | Total |
|-------|--------|--------|--------|-------:|--------:|------:|
| 001 | 001-introduction.md | — | — | — | — | — |
| _Add rows as you create modules._ | | | | | | |

## Conventions

Spec modules follow a three-digit prefix pattern: `NNN-<name>.md`. The index file is always `000-index.md`, and the introduction file is always `001-introduction.md`. Domain modules start at `002` and go up.

Requirements within a module use the format `REQ-PREFIX-NNN`, where `PREFIX` is the module's prefix (three or more uppercase letters) and `NNN` is a three-digit number unique within the module.

Example requirement header:

```markdown
### REQ-AUTH-001: User Login Flow

**Priority:** must-have
**Status:** specified
**Source:** PRD §4.2 (Authentication)

**Properties:**
- User provides credentials via the login form
- Successful authentication returns a session token
- Failed authentication returns an error without revealing user existence

**Testable Assertion:**
> A valid credential pair produces a session token. An invalid credential pair produces an error with code `AUTH_FAILED` and no information about whether the username exists.
```

## Dropped Sections

When a requirement or section is dropped from the active spec, wrap its heading and body in `~~strikethrough~~`. The compile step in `/shit:spec-reader` strips these from the compiled output but leaves them in the source file for historical reference.

Example:

```markdown
~~### REQ-AUTH-099: Legacy OAuth Fallback~~

~~**Status:** dropped (2026-01-15) — superseded by REQ-AUTH-105~~

~~**Original properties:**~~
~~- Accept OAuth tokens from the legacy provider~~
```
