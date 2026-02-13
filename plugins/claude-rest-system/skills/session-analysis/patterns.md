# Search Patterns Reference

## Error Detection

Patterns that indicate something went wrong:

```bash
# General errors
"error|Error|ERROR|failed|Failed|FAILED|exception|Exception"

# Command failures
"exit code|Exit code|non-zero|command not found"

# Tool errors
"permission denied|No such file|cannot access"

# API/network errors
"timeout|connection refused|rate limit|quota exceeded"
```

## Learning Indicators

Patterns suggesting Claude learned something:

```bash
# Explicit acknowledgment
"I see|I understand|understood|makes sense|got it"

# Realization moments
"realized|learned|discovered|figured out|turns out"

# Applying new knowledge
"now I know|going forward|in the future|remember to"
```

## User Corrections

Patterns where user corrected Claude:

```bash
# Direct corrections
"no,|nope|wrong|incorrect|that's not right"

# Redirection
"actually|instead|rather than|don't|stop"

# Retry requests
"try again|redo|fix|that didn't work"
```

## Friction Points

Patterns indicating confusion or difficulty:

```bash
# Uncertainty
"not sure|unsure|unclear|confused|don't understand"

# Hesitation
"might|maybe|perhaps|I think|possibly"

# Asking for clarification
"could you clarify|what do you mean|can you explain"
```

## Domain-Specific Patterns

### Shell Scripting
```bash
# Path issues
"spaces in path|quote|unquoted|$HOME|~/"

# Variable issues
"unset variable|empty variable|\$\{.*:-"

# Piping/redirection
"pipe|redirect|stdout|stderr|>/dev/null"
```

### Kubernetes
```bash
# Context issues
"kube.*context|KUBECONFIG|namespace"

# Resource issues
"not found|already exists|forbidden|unauthorized"

# kubectl patterns
"kubectl|k8s|pod|deployment|service|ingress"
```

### JSON/YAML Processing
```bash
# jq patterns
"jq|\..*\.|select\(|map\("

# yq patterns
"yq|\..*\[\]"

# Parse errors
"parse error|invalid json|yaml.*error"
```

### Git Operations
```bash
# Common issues
"merge conflict|detached HEAD|dirty working"

# Branch operations
"checkout|branch|rebase|cherry-pick"
```

## jq Best Practices

### Avoid Shell Escaping Issues

**BAD** - `!= null` gets escaped to `\!= null` in some shells:
```bash
jq 'select(.content != null)'  # May fail
```

**GOOD** - Use truthy checks instead:
```bash
jq 'select(.content)'          # Works reliably
jq 'select(.content | type == "string")'  # Explicit type check
```

### Handle Array vs String Content

Session messages have inconsistent `.message.content` structure:
- **User messages**: string
- **Assistant messages**: array of objects with `.text` or `.thinking`

**Extract text safely**:
```jq
def get_text:
  if type == "array" then
    map(select(.text) | .text) | join(" ")
  elif type == "string" then .
  else ""
  end;

.message.content | get_text
```

**Quick preview** (first 300 chars):
```jq
.message.content |
  if type == "array" then (.[0].text // "") else (. // "") end |
  .[0:300]
```

### Filter Useful Messages

Skip tool_use/tool_result with null content:
```bash
jq 'select(.type == "user" or .type == "assistant") | select(.message.content)'
```

### Prefilter Sessions

Use the prefilter script to inventory before analysis:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/rest_session_prefilter.sh <dir>
```

Returns JSON with session_id, message_count, first_timestamp, size_bytes.

## Walked-Through Process Indicators

Patterns suggesting the user walked the agent through a multi-step procedure.
Used as supplementary grep when transcript analysis needs raw data confirmation.

**Note:** These patterns are reference material for supplementary grep searches.
Primary detection happens when the analysis agent reads the session transcript.

### Single-message sequential instructions
```bash
"step 1|step 2|1\.|2\.|3\.|first,|second,|third,"
"first do|then do|next do|after that|now do|once.*done"
"follow these steps|here's the process|here's how|the procedure is"
```

### Multi-turn instruction sequences
```bash
"now |next |then |okay now|go ahead and"
"run |execute |create |set up|configure |install |deploy "
"check |verify |confirm |make sure|does it show"
```

### Process correction/re-explanation
```bash
"no, the order is|you need to.*first|let me walk you through|the steps are"
```

## Navigation Confusion Indicators

Patterns suggesting the agent doesn't know where something is in the project.
These are learning candidates: the resolution is documenting "you find X here."

### Search-heavy sequences (visible as rapid tool_use in transcripts)
```bash
"let me search|let me try|let me check|let me look|looking for"
"that wasn't it|not there|try another|different path|wrong location|wrong file"
"where is|can't find|trying to locate|trying to find"
```

### Multiple file reads in quick succession
```bash
# In transcripts, look for 3+ consecutive → Used lines with
# Glob, Grep, or Read targeting different directories
"→ Used Glob|→ Used Grep|→ Used Read"
```

### Resolution indicators (the learning)
```bash
"found it|there it is|that's the one|located at|the config is at"
```

## Usage Tips

1. **Start broad, then narrow**: Begin with general error patterns, then drill into specific domains

2. **Context matters**: When a pattern matches, extract surrounding lines (±5) for full context

3. **Chain searches**: If "error" finds too many hits, combine with domain: `"error.*kubectl|kubectl.*error"`

4. **User message focus**: For corrections, filter to user messages first:
   ```bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/rest_session_filter.sh <file> user | grep -i "no,\|actually\|wrong"
   ```

5. **Multiple passes**: First pass finds regions of interest; second pass analyzes those regions deeply

6. **Read in chunks**: For large sessions, extract ranges rather than reading entire file:
   ```bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/rest_session_extract.sh <file> 50 100
   ```
