# Requirement Traceability Chain

Trace a single requirement through every pipeline stage: PRD → spec → code → tests.

**Usage:** `/shit:trace REQ-AUTH-003`

## Process

### 1. Parse the Requirement ID

Extract the requirement ID from: $ARGUMENTS

The ID must match `REQ-[A-Z]+-[0-9]{3}`. If no valid ID is provided, list available prefixes from `specs/2-spec/000-index.md` and ask the user to specify one.

### 2. Find in Spec

Search `specs/2-spec/*.md` for a heading matching `### REQ-PREFIX-NNN:`. Extract the full requirement block:

- Title
- Source field (PRD section reference)
- Priority
- Properties (all bullet points)
- Testable assertion

Display the full block.

### 3. Trace to PRD

From the `**Source:**` field, extract the PRD section reference (e.g., `PRD §4.1`). Read the most recent PRD file in `specs/1-prd/prd_*.md` and find the corresponding section. Extract and display the relevant paragraph(s) that this requirement derives from.

### 4. Search Code Provenance

Search the project's source files (everywhere outside `specs/`, build/dependency directories, and tests) for any of these provenance marker patterns adjacent to declarations:

```
@provenance: REQ-PREFIX-NNN
provenance: REQ-PREFIX-NNN
MARK: - Provenance: REQ-PREFIX-NNN
```

The marker may appear in any line-comment style the language uses. For each match, show:

- File path (relative to the project root)
- The marker line itself
- 5 lines of surrounding context (the declaration or function near the marker)

If no matches: report "No code provenance found."

### 5. Search Test Provenance

Search the project's test files for two kinds of references:

**Test framework tags** (convert `REQ-AUTH-003` → `.reqAUTH003` or similar normalized form):

```
.tags(.*\.reqPREFIXNNN
@Tag(.reqPREFIXNNN)
@requirement("REQ-PREFIX-NNN")
```

**Provenance markers in test files** (same patterns as for code).

For each match, show:

- File path (relative to the project root)
- Test function name (look for the nearest test declaration above the match)

If no matches: report "No test provenance found."

### 6. Output Traceability Chain

Summarize as a linear chain:

```
## Traceability: REQ-AUTH-003

PRD §4.2 (Authentication Flow)
  ↓
Spec specs/2-spec/004-auth.md — "User Login Flow" [must-have]
  ↓
Code: src/auth/login.ts (LoginService.authenticate)
  ↓
Tests: tests/auth/login.test.ts (testValidCredentialsProduceToken)
  ↓
Status: tested
```

### 7. Heuristic Mode (Only When Explicitly Requested)

If the user asks for heuristic matching, also search by class/function name patterns derived from the requirement title. For example, for "User Login Flow", search for `class Login`, `function login`, etc.

Clearly label all heuristic matches:

```
### Heuristic Matches (not verified by provenance)
- src/auth/login.ts — contains `class LoginService`
```

Do NOT run heuristic mode unless the user explicitly requests it.

## Key Files

- `specs/2-spec/000-index.md` — prefix-to-module mapping
- `specs/2-spec/*.md` — spec modules
- `specs/1-prd/prd_*.md` — PRD (most recent by date)
- Project source files — code provenance
- Project test files — test provenance

## Output

Display the full trace directly in the conversation.
