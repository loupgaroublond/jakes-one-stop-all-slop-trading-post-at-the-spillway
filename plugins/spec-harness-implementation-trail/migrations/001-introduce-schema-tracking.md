# Migration 001 — Introduce Schema Tracking

**Source version:** legacy (no marker)
**Target version:** 1
**Plugin version introduced:** 0.2.0

## Change

Adds a per-project schema marker file at `specs/.shit.toml`. Projects that adopted SHIT before this change have a `specs/` directory but no marker file; this migration writes the marker so future migrations have a known starting point.

Schema **v1** describes the layout that existed before any migrations: dated PRD filenames (`prd_YYYY-MM-DD.md`) and the original spec/transcript conventions. Nothing under `specs/` changes during this migration except the addition of `.shit.toml`.

## Detection

Migration is needed when:

```bash
test -d specs && ! test -f specs/.shit.toml
```

(Equivalent to `STATUS=LEGACY` from `scripts/schema-check.sh`.)

## Migration steps

Atomic and reversible — just writes one file.

1. Confirm `specs/` exists (otherwise the user should run `/shit:init` instead).
2. Confirm `specs/.shit.toml` does not exist (no overwrite).
3. Write the marker:
   ```toml
   [schema]
   version = 1
   ```
4. Stage the file: `git add specs/.shit.toml` (do not commit; let the user batch with their own commit, or with the next migration).

## Verification

```bash
test -f specs/.shit.toml && grep -q '^version = 1$' specs/.shit.toml
```

Expected: exit 0.

## Rollback

```bash
rm specs/.shit.toml
```

(Project returns to legacy / unmarked state.)
