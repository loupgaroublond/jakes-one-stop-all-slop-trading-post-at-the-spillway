# Migration 002 — PRD Serial Naming

**Source version:** 1
**Target version:** 2
**Plugin version introduced:** 0.2.0

## Change

PRD files in `specs/1-prd/` change from date-versioned naming (`prd_YYYY-MM-DD.md`) to serial-with-slug naming (`NNN-slug.md`), matching the convention already used by spec modules in `specs/2-spec/`.

**Why:** The dated filenames conflated identity with versioning. VCS already tracks versions. The new model treats each PRD as a distinct document — a project may have one PRD (`000-{project}.md`) or many (`000-core.md`, `001-billing.md`, etc.).

## Detection

Migration is needed when:

```bash
test -d specs/1-prd && ls specs/1-prd/prd_*.md >/dev/null 2>&1
```

(Any file matching `prd_*.md` indicates the legacy layout.)

## Migration steps

The agent guides the user through this; do not run blindly.

1. **List existing PRDs:**
   ```bash
   ls -1 specs/1-prd/prd_*.md | sort
   ```
   These are dated snapshots of (typically) the same PRD over time.

2. **Identify the most recent dated file** — the last entry in the sorted list. This becomes the seed for the new PRD.

3. **Derive the project slug** from `basename "$PWD"`. Show it to the user; allow override. Common case: project named `foo` → slug `foo` → file `000-foo.md`.

4. **Rename the most recent PRD:**
   ```bash
   git mv specs/1-prd/prd_<latest-date>.md specs/1-prd/000-<slug>.md
   ```

5. **Remove the older dated PRDs** (their content lives in VCS history):
   ```bash
   git rm specs/1-prd/prd_<earlier-date>.md
   # ...repeat for each older file
   ```

   If the user wants to preserve any older PRD as a separate document, rename it instead: `git mv specs/1-prd/prd_<date>.md specs/1-prd/00N-<other-slug>.md`.

6. **Update cross-references.** Search for explicit references to the old filenames:
   ```bash
   grep -r 'prd_' specs/ || true
   ```
   Update any that name the dated file directly.

7. **Bump the schema marker:**
   ```bash
   sed -i.bak 's/^version = 1$/version = 2/' specs/.shit.toml && rm specs/.shit.toml.bak
   ```

8. **Stage everything:** `git add -A specs/`. Let the user commit.

## Verification

```bash
ls specs/1-prd/prd_*.md 2>/dev/null && echo "FAIL: legacy files remain" || echo "OK: legacy files gone"
ls specs/1-prd/[0-9][0-9][0-9]-*.md 2>/dev/null | head -1 || echo "FAIL: no serial PRD"
grep -q '^version = 2$' specs/.shit.toml && echo "OK: version bumped" || echo "FAIL: version not bumped"
```

## Rollback

This migration deletes files (relying on VCS history). Rollback is via `git restore` / `git revert` on the commit that included the migration. Do not attempt to script reverse migration.
