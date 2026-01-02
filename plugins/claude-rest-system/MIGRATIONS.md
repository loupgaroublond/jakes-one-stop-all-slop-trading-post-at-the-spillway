# Claude Rest System Migrations

Sequential list of breaking changes requiring user action. The `/upgrade` command reads this document to evaluate migration status and guide users through updates.

Each migration includes:
- **Change**: What changed
- **Detection**: How to check migration status
- **Migration**: Steps to migrate
- **Verification**: How to confirm success

---

## Migration 001: Peers Format (v2.2.0)

**Change:** `~/.claude/project-peers.json` format changed from string arrays to object arrays with `{path, name}` structure.

**Detection:**
```bash
# Check if file exists
test -f ~/.claude/project-peers.json

# Check format - if any entries are strings (not objects), needs migration
jq -e 'to_entries[].value | to_entries[].value[] | select(type == "string")' ~/.claude/project-peers.json 2>/dev/null
# Exit 0 = NEEDS_MIGRATION (found string entries)
# Exit 1+ = MIGRATED or NOT_APPLICABLE
```

**Status determination:**
- `NOT_APPLICABLE`: File doesn't exist (user doesn't use peers feature)
- `NEEDS_MIGRATION`: File exists with string-format entries
- `MIGRATED`: File exists with object-format entries only

**Migration:**
1. Read current file
2. Transform string entries to object format:
   - `"encoded-path"` → `{"path": "encoded-path", "name": ""}`
3. User should add display names for prettier `/yawn` output

**Example before:**
```json
{
  "my-project": {
    "local": ["-Users-me-Documents-my-project"],
    "work": ["-Users-me-Work-my-project"]
  }
}
```

**Example after:**
```json
{
  "my-project": {
    "local": [
      {"path": "-Users-me-Documents-my-project", "name": "~/Documents"}
    ],
    "work": [
      {"path": "-Users-me-Work-my-project", "name": "/Work/Documents"}
    ]
  }
}
```

**Verification:**
```bash
# Should return exit code 1+ (no string entries found)
jq -e 'to_entries[].value | to_entries[].value[] | select(type == "string")' ~/.claude/project-peers.json 2>/dev/null
echo "Exit code: $?"  # Should be non-zero
```

---

## Migration 002: sync.conf Location (v2.4.0)

**Change:** `sync.conf` moved from `~/.claude/self/sync.conf` to `~/.claude/sync.conf`.

**Detection:**
```bash
# Check old location
OLD_EXISTS=$(test -f ~/.claude/self/sync.conf && echo "true" || echo "false")

# Check new location
NEW_EXISTS=$(test -f ~/.claude/sync.conf && echo "true" || echo "false")
```

**Status determination:**
- `NOT_APPLICABLE`: Neither exists (user doesn't use multi-machine sync)
- `NEEDS_MIGRATION`: Old exists, new doesn't
- `MIGRATED`: New exists (regardless of old)
- `CONFLICT`: Both exist with different content

**Migration:**
```bash
mv ~/.claude/self/sync.conf ~/.claude/sync.conf
```

**Verification:**
```bash
test -f ~/.claude/sync.conf && echo "OK" || echo "FAILED"
test ! -f ~/.claude/self/sync.conf && echo "OLD REMOVED" || echo "OLD STILL EXISTS"
```

---

## Migration 003: archive.log Location (v2.4.0)

**Change:** `archive.log` moved from `~/.claude/self/archive.log` to `~/.claude/archive.log`.

**Detection:**
```bash
OLD_EXISTS=$(test -f ~/.claude/self/archive.log && echo "true" || echo "false")
NEW_EXISTS=$(test -f ~/.claude/archive.log && echo "true" || echo "false")
```

**Status determination:**
- `NOT_APPLICABLE`: Neither exists (plugin never ran archiving)
- `NEEDS_MIGRATION`: Old exists, new doesn't
- `MIGRATED`: New exists (old may or may not exist - log can accumulate)
- `OK_TO_MERGE`: Both exist (can concatenate)

**Migration:**
```bash
# If both exist, concatenate; otherwise just move
if [[ -f ~/.claude/archive.log ]] && [[ -f ~/.claude/self/archive.log ]]; then
    cat ~/.claude/self/archive.log >> ~/.claude/archive.log
    rm ~/.claude/self/archive.log
elif [[ -f ~/.claude/self/archive.log ]]; then
    mv ~/.claude/self/archive.log ~/.claude/archive.log
fi
```

**Verification:**
```bash
test ! -f ~/.claude/self/archive.log && echo "OK" || echo "OLD STILL EXISTS"
```

---

## Migration 004: Remove ~/.claude/self/ Directory (v2.4.0)

**Change:** `~/.claude/self/` directory deprecated and should be removed.

**Detection:**
```bash
# Check if directory exists
DIR_EXISTS=$(test -d ~/.claude/self && echo "true" || echo "false")

# Check if directory is empty
if [[ -d ~/.claude/self ]]; then
    DIR_EMPTY=$(test -z "$(ls -A ~/.claude/self 2>/dev/null)" && echo "true" || echo "false")
else
    DIR_EMPTY="n/a"
fi
```

**Status determination:**
- `NOT_APPLICABLE`: Directory doesn't exist
- `NEEDS_MIGRATION`: Directory exists and is empty
- `BLOCKED`: Directory exists but not empty (run migrations 002, 003 first)
- `MIGRATED`: Directory doesn't exist

**Migration:**
```bash
# Only remove if empty
if [[ -d ~/.claude/self ]] && [[ -z "$(ls -A ~/.claude/self 2>/dev/null)" ]]; then
    rmdir ~/.claude/self
    echo "Removed empty ~/.claude/self directory"
else
    echo "WARNING: ~/.claude/self not empty. Contents:"
    ls -la ~/.claude/self/
    echo "Remove these files manually or migrate them first."
fi
```

**Verification:**
```bash
test ! -d ~/.claude/self && echo "OK" || echo "STILL EXISTS"
```

---

## Migration Sequence

Migrations must be applied in order due to dependencies:

1. **001 (Peers Format)** - Independent, can run anytime
2. **002 (sync.conf)** - Must run before 004
3. **003 (archive.log)** - Must run before 004
4. **004 (Remove self/)** - Depends on 002, 003

The `/upgrade` command handles this sequencing automatically.

---

## Adding New Migrations

When adding breaking changes to the plugin:

1. Add new migration section with next sequential number
2. Include all required sections (Change, Detection, Status, Migration, Verification)
3. Update "Migration Sequence" if there are dependencies
4. Bump plugin version in plugin.json and marketplace.json
5. Add SLOP_REPORT.md entry
