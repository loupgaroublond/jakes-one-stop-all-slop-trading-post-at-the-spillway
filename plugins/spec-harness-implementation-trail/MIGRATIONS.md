# SHIT Schema Migrations

This plugin tracks each project's `specs/` layout as a schema version, recorded in `specs/.shit.toml`. When the plugin's conventions change in a way that would break old projects, a new migration file is added under `migrations/`. Run `/shit:migrate` to advance a project to the latest version.

## How it works

- **Active version** lives in `specs/.shit.toml` under `[schema] version = N`.
- **Latest version** is the integer in `migrations/LATEST` (this plugin's source of truth).
- **Each command** runs `scripts/schema-check.sh` automatically (via the `!` injection in its prompt) and reacts to `STATUS=OK|MISMATCH|LEGACY|UNINITIALIZED`.
- **`/shit:migrate`** reads pending migrations between active and latest, plans the work (rollup vs step-by-step), and walks the user through it.

## Migrations

| ID | Target | Plugin | Summary |
|----|--------|--------|---------|
| [001](migrations/001-introduce-schema-tracking.md) | v1 | 0.2.0 | Bootstrap `specs/.shit.toml` for legacy projects. |
| [002](migrations/002-prd-serial-naming.md) | v2 | 0.2.0 | PRD files: `prd_YYYY-MM-DD.md` → `NNN-slug.md`. |

Each migration file declares: source version, target version, change description, detection, migration steps, verification, rollback notes.

## Versioning rules

- Versions are sequential integers starting at 1.
- A new migration always increases the integer by exactly 1; no skipping.
- Migrations are forward-only. Rollback is via VCS (`git restore` / `git revert`).
- The migration filename's `NNN` prefix matches the **target** version it produces.

## Adding a new migration

1. Create `migrations/NNN-{slug}.md` describing the change. Use migration 001 or 002 as a template.
2. Bump `migrations/LATEST` to `NNN`.
3. Update the schema-check preamble in every `commands/*.md` to reference the new latest version (grep for the previous integer).
4. Bump the plugin version in `plugin.json` and `.claude-plugin/marketplace.json`.
5. Add a `SLOP_REPORT.md` entry mentioning the new schema version and `/shit:migrate`.
