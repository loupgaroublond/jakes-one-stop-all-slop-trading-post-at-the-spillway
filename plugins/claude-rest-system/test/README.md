# Rest Plugin Test Environment

## Session JSONL Schema

Each line is a JSON object with `type` field:
- `user` - User messages (has `.message.content`)
- `assistant` - Claude responses (has `.message.content`)
- `summary` - Session summaries/checkpoints
- `file-history-snapshot` - File state tracking
- `queue-operation` - Internal operations

Key fields for analysis:
- `.type` - Message type
- `.message.content` - Actual content (for user/assistant)
- `.timestamp` - When message occurred
- `.uuid` - Unique message ID

## Test Sessions

| File | Lines | Size | Types |
|------|-------|------|-------|
| tiny.jsonl | 16 | 5.2K | 4 user, 1 assistant, 9 summary, 2 snapshot |
| small.jsonl | 14 | 14K | varies |
| medium.jsonl | 111 | 129K | 38 user, 61 assistant, 7 summary, 3 snapshot |

## Script Tests

### 1. rest_session_count.sh

**Purpose**: Count total messages in a session file

**Test**:
```bash
./scripts/rest_session_count.sh test/sessions/tiny.jsonl
```

**Expected**: `16`

**Verification**: Output equals `wc -l < test/sessions/tiny.jsonl`


### 2. rest_session_inventory.sh

**Purpose**: Generate compact inventory with message previews and line numbers

**Test**:
```bash
./scripts/rest_session_inventory.sh test/sessions/small.jsonl
```

**Expected format**:
```
1  user     "First user message preview..."
2  assistant "First assistant response..."
3  tool_use  "tool_name: parameter preview..."
...
```

**Verification**:
- Line count in output equals message count
- Each line has: line_number, type, preview
- Types are one of: user, assistant, tool_use, tool_result
- Previews are truncated to reasonable length (~60 chars)


### 3. rest_session_search.sh

**Purpose**: Search for patterns, return matching line numbers

**Test**:
```bash
./scripts/rest_session_search.sh test/sessions/medium.jsonl "error|Error|failed"
```

**Expected format**:
```
23:matched text snippet
45:another matched snippet
```

**Verification**:
- Output matches `grep -n "error|Error|failed" test/sessions/medium.jsonl`
- Line numbers are valid (exist in file)
- Can extract those lines with rest_session_extract.sh


### 4. rest_session_extract.sh

**Purpose**: Extract specific message range by line offset

**Test**:
```bash
./scripts/rest_session_extract.sh test/sessions/medium.jsonl 10 15
```

**Expected**:
- Exactly 6 lines of output (lines 10-15 inclusive)
- Each line is valid JSON
- First line matches `sed -n '10p' test/sessions/medium.jsonl`
- Last line matches `sed -n '15p' test/sessions/medium.jsonl`

**Verification**:
```bash
# Output line count
./scripts/rest_session_extract.sh test/sessions/medium.jsonl 10 15 | wc -l
# Expected: 6

# First line matches
diff <(./scripts/rest_session_extract.sh test/sessions/medium.jsonl 10 15 | head -1) \
     <(sed -n '10p' test/sessions/medium.jsonl)
# Expected: no output (identical)
```


### 5. rest_session_filter.sh

**Purpose**: Filter messages by type (user, assistant, summary, etc.)

**Test**:
```bash
./scripts/rest_session_filter.sh test/sessions/medium.jsonl user
```

**Expected**:
- Only lines where `.type == "user"`
- Exactly 38 lines (per test session stats above)

**Verification**:
```bash
# Count matches expected
./scripts/rest_session_filter.sh test/sessions/medium.jsonl user | wc -l
# Expected: 38

# All output lines have correct type
./scripts/rest_session_filter.sh test/sessions/medium.jsonl user | \
  jq -e '.type == "user"' > /dev/null && echo "PASS" || echo "FAIL"

# Cross-check with jq
diff <(./scripts/rest_session_filter.sh test/sessions/medium.jsonl user | wc -l) \
     <(jq -c 'select(.type == "user")' test/sessions/medium.jsonl | wc -l)
# Expected: no output (counts match)
```


## Storage Layer Tests

### 1. Metadata Creation

**Test**: Create metadata for a test session

**Expected file** `~/.claude/analysis/sessions/test-abc123/metadata.json`:
```json
{
  "session_id": "test-abc123",
  "serial_number": 1,
  "session_file": "test/sessions/tiny.jsonl",
  "first_message_timestamp": "2025-01-15T09:00:00Z",
  "total_messages": 16,
  "analyzed_through_message": 0,
  "analysis_runs": [],
  "status": "pending"
}
```

**Verification**:
```bash
jq -e '.session_id and .serial_number and .total_messages' \
  ~/.claude/analysis/sessions/test-abc123/metadata.json
# Expected: exit code 0
```


### 2. Findings Creation

**Test**: Create findings after analysis

**Expected file** `~/.claude/analysis/sessions/test-abc123/quick-{timestamp}.json`:
```json
{
  "timestamp": "...",
  "range": [0, 16],
  "type": "quick",
  "tier": 0,
  "parent": null,
  "learnings": [...],
  "mistakes": [...],
  "doc_references": [...]
}
```

**Verification**:
```bash
jq -e '.type == "quick" and .tier == 0 and .range[1] == 16' \
  ~/.claude/analysis/sessions/test-abc123/quick-*.json
# Expected: exit code 0
```


### 3. Serial Number Assignment

**Test**: Create metadata for 3 sessions, verify serial numbers

**Verification**:
```bash
for id in test-s1 test-s2 test-s3; do
  jq -r '.serial_number' ~/.claude/analysis/sessions/$id/metadata.json
done
# Expected output:
# 1
# 2
# 3
```


## Integration Tests

### End-to-End Small Session

**Test**: Analyze tiny.jsonl completely

**Steps**:
1. Create metadata (analyzed_through_message: 0)
2. Run analysis
3. Check metadata updated (analyzed_through_message: 16, status: complete)
4. Check findings file exists with valid schema
5. Check report generated

**Verification**:
```bash
# Metadata shows complete
jq -e '.analyzed_through_message == .total_messages and .status == "complete"' \
  ~/.claude/analysis/sessions/test-tiny/metadata.json

# Findings file exists
ls ~/.claude/analysis/sessions/test-tiny/quick-*.json

# Report exists
ls ~/.claude/analysis/reports/rest-*-test.md
```


## Clean Up

```bash
rm -rf ~/.claude/analysis/sessions/test-*
rm -rf ~/.claude/analysis/reports/rest-*-test.md
```
