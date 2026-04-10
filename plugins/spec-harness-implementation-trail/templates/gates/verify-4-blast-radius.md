# Verification Layer 4: Blast Radius

The blast radius layer asks: *what else does this change affect?* It identifies the dependents of changed code and verifies that those dependents still work.

Layer 4 runs against the **merged patch** — all work item diffs combined into a single change for the pipeline. This is critical: blast radius is exactly the kind of analysis that needs to see all the work items together, because two work items might independently look fine and still combine into a breaking change for some downstream consumer.

## Purpose

Layers 1–3 check the change in isolation. Blast radius checks the change in context. A change to a class might be flawless in itself, but if 30 other files use that class, all 30 are now affected. The verifier needs to identify those 30 and confirm none are broken.

This is a check that nothing visibly downstream is broken — compilation passes, tests pass, dependents still work. It is not a code review of the dependents, and it cannot tell you whether the change is *appropriate* for the dependents (only whether it's tolerated by them). See `verify-2-invariants.md` for the longer note on what gates can and cannot replace.

## Inputs

- The merged patch (all work item diffs combined) representing the entire pipeline's change
- The full codebase (to find dependents)
- Test results from running the affected modules

## Checks

1. **Identify changed surface** — for each modified file, list the symbols whose signature, behavior, or contract changed (not internal refactors that don't escape the file). This is the "blast surface."

2. **Find dependents** — for each item on the blast surface, find every file that references it. The "blast radius" is the set of all dependents.

3. **For each dependent file:**
   - Does it still compile / parse / type-check?
   - Do its tests still pass?
   - Did the change break any invariant the dependent relies on?

4. **For each affected module:**
   - Run that module's tests
   - Confirm the affected module's spec requirements still hold (delegate to layer 2 if needed for specific requirements)

5. **Indirect dependencies** — if a change affects a foundational module, the blast radius can be large. The verifier should make a judgment call about depth: typically two levels of dependency is enough, but cite the choice in the report.

## Output

A blast radius report:

```
## Blast Radius

### Blast Surface
- `Auth.login(credentials, sessionStore)` — added third parameter
- `Auth.logout()` — return type changed from void to Promise<void>

### Direct Dependents (12 files)
- ✓ `src/api/auth-handler.ts` — updated to pass new parameter, tests pass
- ✓ `src/cli/login-command.ts` — updated, tests pass
- ✗ `src/web/login-form.tsx` — NOT updated, calls Auth.login with 2 args. Build broken.
- ...

### Indirect Dependents (1 module)
- ✓ session module — depends on Auth, tests pass

### Module-level Test Results
- ✓ src/auth — 47/47 pass
- ✓ src/api — 89/89 pass
- ✗ src/web — 12/14 pass, 2 fail (login-form.tsx)
```

## Failure Mode

Any broken dependent is a hard failure. The fix is in this pipeline — broken dependents do not get pushed to a follow-up.

The blast surface declaration is itself a check: if the verifier cannot enumerate the blast surface, the change is too poorly understood to advance.

## Distilled Checks

_This section is managed by `/shit:distill`._

<!-- BEGIN DISTILLED -->
<!-- (no distilled checks yet) -->
<!-- END DISTILLED -->
