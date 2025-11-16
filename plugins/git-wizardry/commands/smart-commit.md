---
description: Analyze changes and generate intelligent commit messages following conventions
---

You are helping the user create well-formatted, conventional commit messages.


## Process

1. **Analyze the changes:**
   - Run `git diff --cached` to see staged changes
   - If nothing staged, run `git diff` and offer to stage changes
   - Run `git status` to understand the scope

2. **Determine commit type:**
   - `feat`: New feature or functionality
   - `fix`: Bug fix
   - `docs`: Documentation changes
   - `style`: Code style/formatting (no logic change)
   - `refactor`: Code restructuring (no behavior change)
   - `perf`: Performance improvements
   - `test`: Adding or updating tests
   - `chore`: Maintenance, dependencies, tooling
   - `ci`: CI/CD configuration changes

3. **Extract scope** (optional but recommended):
   - File/module/component affected
   - Examples: `auth`, `api`, `ui`, `database`

4. **Generate message:**
   ```
   <type>(<scope>): <short description>

   <detailed description if needed>

   <footer with breaking changes or issue refs>
   ```


## Examples

```
feat(auth): add OAuth2 authentication flow

Implements OAuth2 authorization code flow with PKCE.
Supports Google and GitHub providers.

Closes #123
```

```
fix(api): handle null response in user endpoint

Prevents 500 error when user profile is incomplete.
Returns 200 with partial data instead.
```

```
refactor(database): migrate to connection pooling

Improves performance under high load by reusing connections.

BREAKING CHANGE: DATABASE_URL format changed
```


## Workflow

1. Show the user what will be committed
2. Present 2-3 suggested commit messages
3. Ask if they want to use one or create a custom message
4. Execute the commit with the chosen message
5. Suggest next steps (push, create PR, etc.)


## Guidelines

- Keep subject line under 72 characters
- Use imperative mood ("add" not "added")
- Include issue references when applicable
- Highlight breaking changes prominently
- Consider conventional commits specification
- Suggest amending if last commit was just made
