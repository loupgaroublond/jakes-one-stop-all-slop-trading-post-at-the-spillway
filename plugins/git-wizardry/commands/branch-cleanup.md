---
description: Clean up merged and stale branches safely
---

You are helping the user clean up old git branches.


## Safety First

This command performs destructive operations. Always:
1. Show what will be deleted BEFORE deleting
2. Confirm with the user
3. Provide an undo option where possible
4. Never delete the current branch
5. Never delete main/master/develop branches


## Process

1. **Identify candidates for deletion:**

   Local merged branches:
   ```bash
   git branch --merged main | grep -v "main\|master\|develop\|^\*"
   ```

   Remote merged branches:
   ```bash
   git branch -r --merged main | grep -v "main\|master\|develop"
   ```

   Stale branches (no commits in 90+ days):
   ```bash
   git for-each-ref --sort=-committerdate --format='%(refname:short) %(committerdate:relative)' refs/heads/
   ```

2. **Present findings:**
   ```
   📋 Branch Cleanup Report

   Merged branches (safe to delete):
   • feature/old-feature (merged 2 months ago)
   • bugfix/minor-fix (merged 1 month ago)

   Stale branches (no activity in 90+ days):
   • experiment/prototype (last commit 4 months ago)

   Protected branches (will not delete):
   • main
   • develop
   ```

3. **Confirm and execute:**
   - Ask which branches to delete
   - Delete local branches: `git branch -d <branch>`
   - Delete remote branches: `git push origin --delete <branch>`


## Interactive Mode

Offer options:
- Delete all merged branches
- Delete specific branches
- Delete stale branches older than X days
- Just show the report (no deletions)


## Recovery

After deletion, remind the user:
```
If you need to recover a deleted branch:
git reflog
git checkout -b <branch-name> <commit-sha>
```


## Guidelines

- Default to showing merged branches only
- Require explicit confirmation for stale branches
- Never force delete (`-D`) without warning
- Check if branches have unpushed commits
- Suggest cleaning remote-tracking branches with `git fetch --prune`
