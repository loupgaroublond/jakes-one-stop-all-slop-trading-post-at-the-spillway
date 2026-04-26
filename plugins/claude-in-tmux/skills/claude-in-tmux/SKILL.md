---
name: claude-in-tmux
description: Use when driving an interactive claude CLI session inside tmux to test plugins or slash commands. Encodes setup, control, observation, and cleanup patterns plus all the discovered gotchas.
---

# claude-in-tmux

A recipe for the parent claude session to spawn a child claude CLI inside a tmux pane, send slash commands and prompts to it, read the rendered output back, react to permission prompts, detect stalls, and tear everything down without leaking state into the user's `~/.claude/`.

The technique is finicky. Every gotcha below is something a previous implementer got wrong before getting right. Read the whole document before you write the first `tmux send-keys`.

---

## 1. When to use this skill

Reach for this when the parent agent needs to run a *real* interactive claude session under remote control. Triggering scenarios:

- Integration-testing a Claude Code plugin or slash command end-to-end against a real claude CLI.
- Reproducing a permission-prompt flow exactly as the user would see it.
- Driving an automated end-to-end exercise of an interactive workflow (mode switching, multi-turn prompts, agent spawning).
- Observing what claude actually renders on screen — mode lines, status indicators, token counts, prompts — instead of guessing.

If the work is one-shot and non-interactive, prefer `claude --print` directly. This skill exists for cases where interactivity is the point.

---

## 2. Core technique (minimal working loop)

The fundamental loop is: start a tmux session, launch claude in it, send keys, capture output, repeat, then clean up.

```sh
SESSION=cit-$(date +%s)-$$
TMP=/tmp/$SESSION
mkdir -p "$TMP"
trap 'tmux kill-session -t "$SESSION" 2>/dev/null; rm -rf "$TMP"' EXIT INT TERM

# Wide, tall, detached, named, cwd pinned to the test fixture.
tmux new-session -d -s "$SESSION" -x 220 -y 60 -c "$TMP"

# Launch claude inside the pane.
tmux send-keys -t "$SESSION" \
  "claude --plugin-dir /path/to/plugin --permission-mode acceptEdits --effort medium" Enter

# Give it a beat to render the splash and any first-run prompts.
sleep 5
tmux capture-pane -t "$SESSION" -p; echo END

# If a folder-trust prompt appears: send Enter to accept option 1.
tmux send-keys -t "$SESSION" Enter
sleep 2

# Type a slash command.
tmux send-keys -t "$SESSION" "/help" Enter
sleep 4
tmux capture-pane -t "$SESSION" -p; echo END
```

That is the whole shape. Everything else in this document is correctness: choosing the right flags, suppressing user-state contamination, recognizing what the pane is showing, and not leaving litter behind.

### The two non-obvious bits

- **The trailing `; echo END` after `capture-pane`.** Sometimes capture-pane returns nothing — empty pane, redirect quirk, race with rendering. Without `END` you can't tell "no output" from "stalled subprocess". Always print a sentinel.
- **`sleep` between `send-keys` and `capture-pane`.** The pane needs time to render. 3–8 s for a slash command that triggers a prompt; 1–2 s for inline autocomplete; longer when you're waiting on the agent to actually work.

---

## 3. Isolation recipe (THE headline section)

Goal: launch the child claude in a way that **modifies nothing** under the user's `~/.claude/`, reads no user settings, runs no user hooks, loads only the dev plugin, and leaves zero residue when it exits — even on error.

This is the part the user explicitly asked for. Do not skip it. Do not compress it. The previous shortcut — `claude plugin disable <name>` then `claude plugin enable <name>` — mutates the user's installed-plugin set and is easy to leave broken if the test errors mid-flight. We are not doing that any more.

### 3a. The diagnostic technique (more important than the recipe)

The flag set the recipe uses will drift over time as the claude CLI evolves. The diagnostic that *derives* the recipe will not. Encode this in your reflexes:

```sh
# Before launching the child claude:
TS=/tmp/cit-pre-$$
touch -d "1 second ago" "$TS"

# ... run the child claude session, do whatever it does, exit ...

# After cleanup:
find ~/.claude -newer "$TS" -not -path '*/projects/*' 2>/dev/null
```

Anything in that `find` output is contamination. Per-cwd session history under `~/.claude/projects/<encoded-cwd>/` is acceptable when the cwd is a `/tmp/...` path — it is namespaced by cwd and gets garbage-collected eventually. Anything else (settings mutations, plugin enable/disable state, memory writes outside the per-cwd dir, telemetry) must be eliminated.

When the recipe stops working — when you see contamination in the diff — re-run `claude --help`, find the new flag that suppresses the new contamination path, add it to the recipe.

### 3b. Known contamination paths

These are the paths the previous validation pass actually saw written:

1. `claude plugin disable/enable` mutates `~/.claude/installed_plugins.json`. **Don't touch it.**
2. Marketplace-installed plugins load automatically and can shadow same-named dev plugins under `--plugin-dir`.
3. Running claude in any cwd writes `<cwd>/.claude/settings.local.json` for "Yes, allow ... from this project" permission grants. Keep the cwd inside a temp dir that gets nuked.
4. `~/.claude/projects/<encoded-cwd>/` accumulates session history per cwd. Acceptable when cwd is `/tmp/...`.
5. Hooks declared in the user's settings run automatically.
6. Auto-memory writes to `~/.claude/projects/.../memory/`.
7. Plugin-sync background prefetches hit the network with the user's auth.
8. CLAUDE.md auto-discovery walks up from cwd, reading project-level instructions you didn't author.

### 3c. The flags that suppress them

Verify each against `claude --help` before relying on it. As of the most recent validation pass:

- **`--bare`** — the big hammer. Skips hooks, LSP, plugin sync, attribution, auto-memory, background prefetches, keychain reads, and CLAUDE.md auto-discovery. In `--bare` mode authentication is **strictly `ANTHROPIC_API_KEY` or `apiKeyHelper` via `--settings`** — no OAuth, no keychain. Trade-off: you must supply auth explicitly via the parent environment.
- **`--settings <file-or-json>`** — point at a test-only settings file. Use to set an explicit `permissions`, an empty `hooks` list, and (if needed) `apiKeyHelper`.
- **`--setting-sources <comma-list>`** — restrict which scopes load. Try the empty value (or just one scope) to skip user/local/project merges.
- **`--mcp-config <path>` plus `--strict-mcp-config`** — load only test MCPs, ignoring the user's MCP setup entirely.
- **`--add-dir <dir...>`** — explicit allow-list of directories the agent may touch. Pin to test cwd plus the dev plugin path.
- **`--plugin-dir <symlink-wrapper>`** — load only the dev plugin (see §5 for the symlink-wrapper trick that controls the slash-command prefix).
- **`--disable-slash-commands`** — sanity check that nothing else loads; usually overkill.

### 3d. Environment-level isolation (when flags aren't enough)

For maximum isolation, override `HOME` for the tmux pane that runs claude:

```sh
HOME=$TMP/home claude --bare ...
```

This redirects every `~/.claude/...` read and write into a fresh dir under the test temp. The cost: auth state lives under `~/.claude/`, so a fresh HOME means no logged-in account — combine with `ANTHROPIC_API_KEY` in the env. `tmux set-environment -t SESSION KEY VALUE` lets you scope env vars to a single pane without polluting the parent shell:

```sh
tmux set-environment -t "$SESSION" HOME "$TMP/home"
tmux set-environment -t "$SESSION" ANTHROPIC_API_KEY "$ANTHROPIC_API_KEY"
```

`XDG_CONFIG_HOME` and friends *may* be honored — verify by snapshotting writes when launched under an overridden value.

### 3e. The recipe (copy-pasteable)

```sh
# launch_isolated_claude SESSION CWD PLUGIN_PATH PERMISSION_MODE
launch_isolated_claude() {
  local session="$1" cwd="$2" plugin_path="$3" mode="${4:-acceptEdits}"
  local tmp wrapper settings prefix
  tmp="$(dirname "$cwd")"
  wrapper="$tmp/wrapper"
  settings="$tmp/settings.json"
  prefix="$(basename "$plugin_path")"

  # Symlink wrapper controls the slash-command prefix (see §5).
  mkdir -p "$wrapper"
  ln -sfn "$plugin_path" "$wrapper/$prefix"

  # Minimal settings: no hooks, no extra permissions, no MCPs.
  cat > "$settings" <<'JSON'
{
  "hooks": {},
  "permissions": { "allow": [], "deny": [] }
}
JSON

  # Per-pane env, so the parent shell stays clean.
  tmux set-environment -t "$session" HOME "$tmp/home"
  tmux set-environment -t "$session" ANTHROPIC_API_KEY "${ANTHROPIC_API_KEY:?must be set in parent env}"
  mkdir -p "$tmp/home"

  tmux send-keys -t "$session" "cd $cwd && claude \
    --bare \
    --plugin-dir $wrapper/$prefix \
    --settings $settings \
    --setting-sources '' \
    --strict-mcp-config \
    --add-dir $cwd --add-dir $plugin_path \
    --permission-mode $mode \
    --effort medium" Enter
}
```

Driver script that uses it:

```sh
#!/usr/bin/env bash
set -euo pipefail

: "${ANTHROPIC_API_KEY:?must be set in parent env}"

SESSION="cit-$(date +%s)-$$"
TMP="/tmp/$SESSION"
CWD="$TMP/fixture"
PLUGIN="${1:?plugin path required}"

# Pre-test snapshot timestamp for contamination check.
PRE_TS="$TMP/.pre-ts"

cleanup() {
  tmux kill-session -t "$SESSION" 2>/dev/null || true
  rm -rf "$TMP"
  # Verify nothing leaked into ~/.claude (excluding per-cwd projects/).
  if [ -e "$PRE_TS" ]; then
    leak="$(find ~/.claude -newer "$PRE_TS" -not -path '*/projects/*' 2>/dev/null)"
    if [ -n "$leak" ]; then
      echo "WARNING: contamination detected in ~/.claude:" >&2
      echo "$leak" >&2
    fi
  fi
}
trap cleanup EXIT INT TERM

mkdir -p "$TMP" "$CWD"
touch "$PRE_TS"

tmux new-session -d -s "$SESSION" -x 220 -y 60 -c "$CWD"

launch_isolated_claude "$SESSION" "$CWD" "$PLUGIN" acceptEdits
sleep 6
tmux capture-pane -t "$SESSION" -p
echo END
```

### 3f. Non-negotiable design constraints

Encode these as guard rails on every test:

1. **Zero modifications to `~/.claude/`** during the test (excluding the per-cwd `projects/<encoded-tmp-cwd>/`).
2. **No `claude plugin disable/enable`** calls. The dev plugin must load unambiguously without disturbing the user's installed set.
3. **All test artifacts under one temp dir** that gets `rm -rf`'d on cleanup — fixture cwd, settings file, symlink wrapper, HOME override.
4. **Cleanup runs even on error.** `trap cleanup EXIT INT TERM` is installed *before* the temp dir is created.
5. **Auth secret handling.** Read `ANTHROPIC_API_KEY` from the parent env. Never write it to disk.

---

## 4. claude CLI flags reference

Verify these against `claude --help`; the surface drifts.

| Flag | What it does | When to use |
| --- | --- | --- |
| `--plugin-dir <path>` | Load a plugin from disk. Path is the plugin root (containing `plugin.json`). | Always, when testing a dev plugin. See §5. |
| `--permission-mode <mode>` | `default` / `acceptEdits` / `plan` / `bypassPermissions`. | See §6. |
| `--effort <level>` | `low` / `medium` / `high` / `xhigh` / `max`. | Default `medium`. See §6 — xhigh stalls. |
| `--bare` | Skip hooks, LSP, plugin sync, attribution, auto-memory, prefetches, keychain reads, CLAUDE.md walk. Auth becomes API-key-only. | Always for isolated tests. |
| `--settings <file-or-json>` | Override settings. | Pair with `--bare` — supply minimal settings. |
| `--setting-sources <list>` | Restrict which scopes merge. | Empty value to skip user/local/project. |
| `--mcp-config <path>` + `--strict-mcp-config` | Load only specified MCPs, ignore user MCP setup. | When user MCPs would interfere. |
| `--add-dir <dir>` | Allow-list directories. Repeat for multiple. | Pin to test cwd plus plugin path. |
| `--disable-slash-commands` | Don't load slash commands at all. | Sanity check only. |
| `--print` | Non-interactive mode. | Skip tmux entirely if you don't need interactivity. |
| `--debug` | Verbose. **Requires `--print`.** | Don't combine with interactive driving — errors out. |
| `--agents <json>` / `--system-prompt[-file]` | Override agent definitions / system prompt. | Niche; orthogonal. |

---

## 5. Plugin loading (and the directory-name trick)

### Plugin layout

A plugin root is a directory containing `plugin.json` **directly at the root**. The validator (`claude plugin validate <path>`) complains "Expected `.claude-plugin/marketplace.json` or `.claude-plugin/plugin.json`" even for valid plugins — its message is wrong; the loader works fine. Trust the loader, not the validator.

### The slash-command prefix comes from the directory basename

This bites everyone exactly once:

> The prefix in the slash-command namespace comes from the **directory's basename**, not from `plugin.json`'s `name` field.

If `plugin.json` says `"name": "shit"` but the directory is `spec-harness-implementation-trail`, then `--plugin-dir <that-path>` surfaces commands as `/spec-harness-implementation-trail:foo`, not `/shit:foo`.

When a test needs a specific prefix, use a symlink wrapper:

```sh
mkdir -p /tmp/wrapper
ln -sfn /path/to/actual/plugin /tmp/wrapper/desired-prefix-name
claude --plugin-dir /tmp/wrapper/desired-prefix-name ...
```

The symlink basename becomes the prefix. The `launch_isolated_claude` recipe in §3e does this automatically.

### Marketplace conflicts

Marketplace-installed plugins merge with `--plugin-dir` plugins. Same-name conflicts go to the *installed* version unless suppressed. The previous workaround was `claude plugin disable <name>` — **don't**. The isolation recipe in §3 sidesteps this by using `--bare` plus `--setting-sources ''`, which suppresses the user's installed-plugin set. Verify with:

```sh
claude --plugin-dir /tmp/wrapper/desired --bare ... <<< "/help"
# Look for /desired:* commands. No /othername:* should appear.
```

The plugin cache lives at `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/` if you need to inspect which version is actually loaded.

---

## 6. Permission mode and effort

### Permission modes

| Mode | Behavior | Use it when |
| --- | --- | --- |
| `default` | Prompts on every Bash/Edit. | Testing the prompt UX itself. |
| `acceptEdits` | Auto-approves file writes; Bash still prompts. | Testing flow without dealing with every file write. |
| `plan` | Agent plans, doesn't execute. **Often the startup default.** | Almost never what you want for testing — switch out of it. |
| `bypassPermissions` | Skip every prompt. | **Only inside an isolated sandbox** (Lima VM, container, throwaway VM). Never on real machines. |

### Plan mode at startup

A fresh `claude` may launch with `⏸ plan mode on` in the status line even if the user didn't pass `--permission-mode plan` — it's the default in some configurations. Plan mode prevents tool execution, so a test that sends `/build-thing` will see the agent plan beautifully and execute nothing.

Two ways out:

1. **Launch with `--permission-mode acceptEdits`** from the start. Skips plan mode.
2. **Cycle modes with `BTab`.** Send shift-Tab once to advance to auto mode. The pane will show a confirmation dialog: "Yes, and make it my default mode / Yes, enable auto mode / No, go back / No, don't ask again." Reply with `1` Enter to accept for this session only.

In tmux, shift-Tab is `BTab` — **not** `S-Tab`. This bites.

### Folder trust prompt

The first time claude runs in a directory it hasn't seen, it shows: *"Quick safety check: Is this a project you trust?"* Two options. Always send `Enter` (option 1: "Yes, I trust this folder") to proceed. Decision persists for that path.

### Effort levels and the xhigh stall

`--effort` accepts `low | medium | high | xhigh | max`. **xhigh on Opus 4.7 reliably stalls on complex prompts** — token streaming freezes mid-response, the status line shows `Burrowing…` indefinitely, and the agent appears hung.

The same prompt that "Burrows" forever at xhigh completes in 30 seconds at medium. **Default `--effort medium` for tests.** If a user wants xhigh, document it but expect stalls.

---

## 7. The `!` directive and env vars

Inside a slash command's markdown body, the backtick-shell-command form

```markdown
!`some shell command`
```

is a **preprocessing directive**. Claude Code expands it *before* the agent reads the prompt: runs the command, captures stdout, replaces the directive with the output. The agent never sees the directive — only the rendered output.

This is gorgeous when it works. It is also a tar pit. The rules:

- **`${CLAUDE_PLUGIN_ROOT}` IS expanded** in the markdown text the agent sees AND in the command line that `!` runs.
- **`${CLAUDE_PLUGIN_ROOT}` is NOT exported as an env var** to the subshell that runs the `!` directive. A script invoked from `!` cannot read `$CLAUDE_PLUGIN_ROOT` from its own environment — it'll be empty.
- **Workaround:** scripts that need their plugin root should self-locate from `BASH_SOURCE`:

  ```sh
  PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
  ```

  Adjust the `..` count to walk up to the plugin root. **Don't rely on `$CLAUDE_PLUGIN_ROOT` inside script bodies.**

- **`allowed-tools` matchers in frontmatter use glob patterns matched against the rendered command line.** They do NOT do env-var expansion. So this never matches:

  ```yaml
  allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/foo.sh:*)
  ```

  Use this instead:

  ```yaml
  allowed-tools: Bash(*/scripts/foo.sh:*)
  ```

  The trailing `:*` is a word boundary — it treats `cmd args` as `cmd<space>*`. Without it, the glob may match unintended adjacent characters.

- The `!` directive is subject to `allowed-tools`. **If the matcher is wrong, the user gets a permission prompt every invocation.** If the matcher is right, the directive runs silently before the agent ever sees the prompt.

---

## 8. Reading pane state

The pane is the agent's UI. Recognize what it's showing.

### Status indicators (working)

Animated label at the bottom: `Concocting…`, `Thinking…`, `Burrowing…`, `Forging…`, plus a `↓ N tokens` count of downstream tokens received.

**Healthy progress:** elapsed time grows AND the token count grows. Agent is actively producing output.

### Mode line (bottom of pane)

| Display | Meaning |
| --- | --- |
| `⏸ plan mode on` | Plan mode — agent plans, does not execute. |
| `⏵⏵ accept edits on` | acceptEdits — file writes auto-approve, Bash still prompts. |
| `⏵⏵ auto mode on` | Auto mode — autonomous execution. |
| `⏵⏵ bypass permissions on` | Bypass — skips all prompts. |

Confirm the mode matches your test expectations *before* sending real work.

### Permission prompt waiting

Pane shows a numbered options list:

```
❯ 1. Yes
  2. Yes, allow ... from this project
  3. No
```

Reply with the digit + Enter. **Choosing option 2** writes a persisted permission to `<cwd>/.claude/settings.local.json` — fine inside a `/tmp/...` cwd that gets nuked, **invasive** anywhere else.

### Token count

Bottom-right (e.g. `26609 tokens`). A session that hasn't grown past ~5000 tokens probably hasn't actually started running the user's prompt yet — usually still in init / trust / mode-confirmation.

### Capturing scrollback

`tmux capture-pane -t SESSION -p` captures the visible pane only. When content has scrolled past the top, capture more lines:

```sh
tmux capture-pane -t SESSION -p -S -100 -E -
```

`-S -100` starts 100 lines above the visible top; `-E -` ends at the bottom. Adjust as needed.

---

## 9. Detecting stalls

### Healthy vs stalled

- **Healthy:** elapsed timer ticks AND `↓ N tokens` count rises. Agent is alive.
- **Stalled:** elapsed timer ticks, token count stays frozen for >60 seconds. Especially common at `--effort xhigh` on complex prompts.

### What to try, in order

1. **Wait 60 s.** Some genuinely long operations look stalled; if tokens move, it isn't.
2. **Send `Escape`.** Cancels the in-flight turn without killing the session.
3. **Lower effort and retry.** xhigh → medium often unfreezes the same prompt.
4. **Kill and restart** the tmux session. After two failed retries, the session state may be wedged.

### Polling pattern

```sh
prev=0; stalled=0
while true; do
  cur="$(tmux capture-pane -t "$SESSION" -p | grep -oE '↓ [0-9]+ tokens' | head -1 | grep -oE '[0-9]+')"
  cur="${cur:-0}"
  if [ "$cur" -gt "$prev" ]; then
    stalled=0; prev="$cur"
  else
    stalled=$((stalled + 1))
    [ "$stalled" -ge 12 ] && { echo "stalled"; break; }   # 12 × 5 s = 60 s
  fi
  sleep 5
done
```

---

## 10. Cleanup

### The trap

Install before any state is created:

```sh
SESSION="cit-$(date +%s)-$$"
TMP="/tmp/$SESSION"
PRE_TS="/tmp/.cit-pre-$$"

cleanup() {
  tmux kill-session -t "$SESSION" 2>/dev/null || true
  rm -rf "$TMP"
  # Diagnostic: did anything leak into ~/.claude?
  if [ -e "$PRE_TS" ]; then
    leak="$(find ~/.claude -newer "$PRE_TS" -not -path '*/projects/*' 2>/dev/null)"
    [ -n "$leak" ] && {
      echo "WARNING: contamination in ~/.claude:" >&2
      echo "$leak" >&2
    }
    rm -f "$PRE_TS"
  fi
}
trap cleanup EXIT INT TERM

mkdir -p "$TMP"
touch "$PRE_TS"
```

### Invariants

1. `tmux kill-session -t "$SESSION" 2>/dev/null` — idempotent, no-op if already dead.
2. `rm -rf "$TMP"` — fixture cwd, settings, symlink wrapper, HOME override all live here. One delete handles them all.
3. **Don't touch `~/.claude/`.** The whole point of the isolation recipe is that there's nothing to undo.
4. **Verify post-cleanup**: `find ~/.claude -newer "$PRE_TS" -not -path '*/projects/*'` should be empty. The `projects/` exclusion is correct because the per-cwd dir is namespaced by the now-deleted `/tmp/...` cwd and is benign.

---

## 11. Gotchas grab-bag

Quick-reference for things that look wrong but aren't (or look right but aren't):

- **`claude plugin validate` lies.** Says it expects `.claude-plugin/plugin.json` or `.claude-plugin/marketplace.json`. The actual loader takes `plugin.json` at the directory root. Trust the loader.
- **`--debug` requires `--print`.** Combining `--debug` with interactive tmux driving errors out immediately. Skip `--debug`.
- **`capture-pane -p` sometimes empty.** tmux quirk under certain redirect conditions. Always pair with `; echo END` to disambiguate.
- **shift-Tab is `BTab`, not `S-Tab`.** Get this wrong once.
- **A claude session may show `with me…` in the title** for a few seconds during init. Wait it out.
- **Width matters.** Below ~120 cols the UI wraps badly and the rendered output becomes unreliable to parse. 220×60 has been reliable.
- **`tmux send-keys` syntax.** Plain text quoted; specials separate-arg: `Enter`, `BTab`, `Escape`, `C-c`, `C-u`, `C-d`. Multiple keys: `tmux send-keys -t S 'text' Enter`.
- **Backticks in this skill's markdown.** When you copy code blocks into your own scripts, watch for shells that interpret backticks. Single-quote heredocs (`<<'EOF'`) prevent expansion.
- **`xhigh` stalls.** Said it in §6, repeating here so it can't be missed.
- **First-run trust prompt** shows on every fresh cwd. Always send `Enter` to accept.

---

## 12. End-to-end example

A complete driver script that exercises a hypothetical plugin at `~/dev/my-plugin/` by sending its `/my-plugin:hello` slash command and capturing the response.

```sh
#!/usr/bin/env bash
# drive_test.sh — end-to-end test of a dev plugin under tmux remote control.
set -euo pipefail

: "${ANTHROPIC_API_KEY:?must be set in parent env}"

PLUGIN="${1:-$HOME/dev/my-plugin}"
[ -f "$PLUGIN/plugin.json" ] || { echo "no plugin.json at $PLUGIN" >&2; exit 1; }

SESSION="cit-$(date +%s)-$$"
TMP="/tmp/$SESSION"
CWD="$TMP/fixture"
WRAPPER="$TMP/wrapper"
SETTINGS="$TMP/settings.json"
HOME_OVR="$TMP/home"
PRE_TS="$TMP/.pre-ts"
PREFIX="$(basename "$PLUGIN")"

cleanup() {
  tmux kill-session -t "$SESSION" 2>/dev/null || true
  rm -rf "$TMP"
  if [ -e "$PRE_TS" ]; then
    leak="$(find "$HOME/.claude" -newer "$PRE_TS" -not -path '*/projects/*' 2>/dev/null)"
    [ -n "$leak" ] && { echo "WARNING: contamination:" >&2; echo "$leak" >&2; }
  fi
}
trap cleanup EXIT INT TERM

mkdir -p "$CWD" "$WRAPPER" "$HOME_OVR"
ln -sfn "$PLUGIN" "$WRAPPER/$PREFIX"
cat > "$SETTINGS" <<'JSON'
{ "hooks": {}, "permissions": { "allow": [], "deny": [] } }
JSON
touch "$PRE_TS"

# 1. Start the tmux pane.
tmux new-session -d -s "$SESSION" -x 220 -y 60 -c "$CWD"
tmux set-environment -t "$SESSION" HOME "$HOME_OVR"
tmux set-environment -t "$SESSION" ANTHROPIC_API_KEY "$ANTHROPIC_API_KEY"

# 2. Launch claude inside it. Note the &&-chained cd: tmux's -c
#    sets the new pane's cwd, but `set-environment HOME` only takes effect
#    for processes the pane spawns *after*, so we re-cd to be safe.
tmux send-keys -t "$SESSION" "cd $CWD && claude \
  --bare \
  --plugin-dir $WRAPPER/$PREFIX \
  --settings $SETTINGS \
  --setting-sources '' \
  --strict-mcp-config \
  --add-dir $CWD --add-dir $PLUGIN \
  --permission-mode acceptEdits \
  --effort medium" Enter

# 3. Wait for splash, dismiss folder-trust prompt if shown.
sleep 6
out="$(tmux capture-pane -t "$SESSION" -p)"
if echo "$out" | grep -q 'trust'; then
  tmux send-keys -t "$SESSION" Enter
  sleep 3
fi

# 4. Send the slash command we want to test.
tmux send-keys -t "$SESSION" "/$PREFIX:hello" Enter

# 5. Wait for completion, watching the token counter for stalls.
prev=0; stalled=0
for _ in $(seq 1 24); do  # 24 × 5 s = 2 min cap
  sleep 5
  pane="$(tmux capture-pane -t "$SESSION" -p)"
  cur="$(printf '%s' "$pane" | grep -oE '↓ [0-9]+ tokens' | head -1 | grep -oE '[0-9]+')"
  cur="${cur:-0}"
  if printf '%s' "$pane" | grep -qE '> $|esc to interrupt'; then
    : # still working
  fi
  if [ "$cur" -gt "$prev" ]; then
    stalled=0; prev="$cur"
  else
    stalled=$((stalled + 1))
    [ "$stalled" -ge 12 ] && { echo "stalled — giving up" >&2; break; }
  fi
  # Heuristic: if we see a fresh prompt waiting for input AND tokens have moved,
  # the turn is done.
  if [ "$cur" -gt 0 ] && printf '%s' "$pane" | tail -5 | grep -q '^>'; then
    break
  fi
done

# 6. Capture the final scrollback for inspection.
echo "===== FINAL PANE ====="
tmux capture-pane -t "$SESSION" -p -S -200 -E -
echo "===== END ====="
```

What this script encodes that a naive version misses:

- Trap installed before any state is created.
- Per-pane env (HOME and API key) — parent shell stays clean.
- Symlink wrapper for prefix control.
- `--bare` + minimal settings + `--setting-sources ''` for isolation.
- `--add-dir` allow-list pinned to test cwd plus plugin path.
- Folder-trust prompt handled.
- Stall detection via token-count delta.
- Capture-pane scrollback (`-S -200`) for the final read.
- Post-cleanup contamination check via `find ~/.claude -newer`.

---

## Final invariants (read before declaring a test session done)

- [ ] `tmux kill-session` succeeded (or the session was already dead).
- [ ] `rm -rf "$TMP"` succeeded — fixture, settings, wrapper, HOME override all gone.
- [ ] `find ~/.claude -newer "$PRE_TS" -not -path '*/projects/*'` is empty.
- [ ] No `claude plugin disable/enable` was ever called.
- [ ] No writes to `~/.claude/installed_plugins.json` or other user state.
- [ ] The trap was installed before state creation, so cleanup ran on success, error, AND signal.

If any of those is unchecked, the recipe leaked. Re-run the diagnostic from §3a, find the new contamination path, add the suppressing flag, and update this skill.
