#!/bin/bash
# Rest Plugin Test Runner
# Run from plugin root: ./test/run_tests.sh

cd "$(dirname "$0")/.."

PASS=0
FAIL=0

run_test() {
  local name="$1"
  shift
  if "$@"; then
    echo "✓ $name"
    ((PASS++))
  else
    echo "✗ $name"
    ((FAIL++))
  fi
}

echo "=== Rest Plugin Tests ==="
echo ""

# --- Script Tests ---
echo "## Script Tests"

# 1. rest_session_count.sh
if [ -f scripts/rest_session_count.sh ]; then
  actual=$(./scripts/rest_session_count.sh test/sessions/tiny.jsonl)
  run_test "rest_session_count.sh returns correct count (16)" [ "$actual" -eq 16 ]
else
  echo "⊘ rest_session_count.sh not implemented yet"
fi

# 2. rest_session_inventory.sh
if [ -f scripts/rest_session_inventory.sh ]; then
  actual=$(./scripts/rest_session_inventory.sh test/sessions/tiny.jsonl | wc -l | tr -d ' ')
  run_test "rest_session_inventory.sh outputs one line per message (16)" [ "$actual" -eq 16 ]
else
  echo "⊘ rest_session_inventory.sh not implemented yet"
fi

# 3. rest_session_search.sh
if [ -f scripts/rest_session_search.sh ]; then
  result=$(./scripts/rest_session_search.sh test/sessions/medium.jsonl "user" | head -1)
  # Check format: starts with digits followed by colon
  if echo "$result" | grep -qE '^[0-9]+:'; then
    echo "✓ rest_session_search.sh returns line_number:content format"
    ((PASS++))
  else
    echo "✗ rest_session_search.sh returns line_number:content format"
    ((FAIL++))
  fi
else
  echo "⊘ rest_session_search.sh not implemented yet"
fi

# 4. rest_session_extract.sh
if [ -f scripts/rest_session_extract.sh ]; then
  actual=$(./scripts/rest_session_extract.sh test/sessions/medium.jsonl 10 15 | wc -l | tr -d ' ')
  run_test "rest_session_extract.sh extracts correct range (6 lines)" [ "$actual" -eq 6 ]

  extracted=$(./scripts/rest_session_extract.sh test/sessions/medium.jsonl 10 15 | head -1)
  expected=$(sed -n '10p' test/sessions/medium.jsonl)
  run_test "rest_session_extract.sh first line matches source" [ "$extracted" = "$expected" ]
else
  echo "⊘ rest_session_extract.sh not implemented yet"
fi

# 5. rest_session_filter.sh
if [ -f scripts/rest_session_filter.sh ]; then
  actual=$(./scripts/rest_session_filter.sh test/sessions/medium.jsonl user | wc -l | tr -d ' ')
  run_test "rest_session_filter.sh filters correct count (38 user)" [ "$actual" -eq 38 ]

  jq_count=$(jq -c 'select(.type == "user")' test/sessions/medium.jsonl | wc -l | tr -d ' ')
  run_test "rest_session_filter.sh matches jq filter" [ "$actual" -eq "$jq_count" ]
else
  echo "⊘ rest_session_filter.sh not implemented yet"
fi

# 6. rest_session_prefilter.sh
if [ -f scripts/rest_session_prefilter.sh ]; then
  # Should return valid JSON array with 3 sessions
  count=$(./scripts/rest_session_prefilter.sh test/sessions/ | jq 'length')
  run_test "rest_session_prefilter.sh returns JSON array (3 sessions)" [ "$count" -eq 3 ]

  # Check that each entry has required fields
  if ./scripts/rest_session_prefilter.sh test/sessions/ | jq -e '.[0] | .session_id and .message_count and .size_bytes' > /dev/null 2>&1; then
    echo "✓ rest_session_prefilter.sh entries have required fields"
    ((PASS++))
  else
    echo "✗ rest_session_prefilter.sh entries missing required fields"
    ((FAIL++))
  fi
else
  echo "⊘ rest_session_prefilter.sh not implemented yet"
fi

# 7. rest_session_count.sh handles empty files
if [ -f scripts/rest_session_count.sh ]; then
  # Create empty test file
  touch test/sessions/empty.jsonl
  actual=$(./scripts/rest_session_count.sh test/sessions/empty.jsonl)
  rm test/sessions/empty.jsonl
  run_test "rest_session_count.sh returns 0 for empty files" [ "$actual" -eq 0 ]
else
  echo "⊘ rest_session_count.sh not implemented yet"
fi

echo ""
echo "## Plugin Structure Tests"

# Check plugin.json exists and is valid
if [ -f .claude-plugin/plugin.json ]; then
  if jq -e '.name == "rest-plugin"' .claude-plugin/plugin.json > /dev/null 2>&1; then
    echo "✓ plugin.json exists and has correct name"
    ((PASS++))
  else
    echo "✗ plugin.json exists but has wrong name"
    ((FAIL++))
  fi
else
  echo "✗ plugin.json missing"
  ((FAIL++))
fi

# Check commands/rest.md exists
if [ -f commands/rest.md ]; then
  echo "✓ commands/rest.md exists"
  ((PASS++))
else
  echo "✗ commands/rest.md missing"
  ((FAIL++))
fi

# Check agents/rest-analyzer.md exists
if [ -f agents/rest-analyzer.md ]; then
  echo "✓ agents/rest-analyzer.md exists"
  ((PASS++))
else
  echo "✗ agents/rest-analyzer.md missing"
  ((FAIL++))
fi

# Check skill exists
if [ -f skills/session-analysis/SKILL.md ]; then
  echo "✓ skills/session-analysis/SKILL.md exists"
  ((PASS++))
else
  echo "✗ skills/session-analysis/SKILL.md missing"
  ((FAIL++))
fi

echo ""
echo "## Storage Tests"

# Storage tests require analysis directory
if [ -d ~/.claude/analysis/sessions ]; then
  # Find test metadata files
  test_meta=$(ls ~/.claude/analysis/sessions/test-*/metadata.json 2>/dev/null | head -1)
  if [ -n "$test_meta" ]; then
    if jq -e '.session_id and .serial_number and .total_messages' "$test_meta" > /dev/null 2>&1; then
      echo "✓ metadata.json has required fields"
      ((PASS++))
    else
      echo "✗ metadata.json has required fields"
      ((FAIL++))
    fi
  else
    echo "⊘ No test metadata files to validate"
  fi
else
  echo "⊘ ~/.claude/analysis/sessions not created yet"
fi

echo ""
echo "=== Results ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"

[ "$FAIL" -eq 0 ]
