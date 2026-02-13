#!/bin/bash
# Generate readable markdown transcript from raw JSONL session file
# Usage: rest_session_transcript.sh <session_file> [start_line] [end_line]
#
# Transforms raw session JSONL into a readable markdown transcript.
# M# numbers correspond to original JSONL line numbers for back-reference.
# Optional start/end parameters enable chunking for monster sessions.
#
# Output: Valid markdown with conversational skeleton:
#   **User (M#N):** text
#   **Assistant (M#N):** text
#     → Used ToolName(key_args)
#   **Tool Result (M#N):** tool → brief
#   [Session compacted at M#N]
#   [System prompt at M#N]

if [ -z "$1" ]; then
  echo "Usage: rest_session_transcript.sh <session_file> [start_line] [end_line]" >&2
  exit 1
fi

SESSION_FILE="$1"
START_LINE="${2:-1}"
END_LINE="${3:-$(wc -l < "$SESSION_FILE" | tr -d ' ')}"
OFFSET=$((START_LINE - 1))

sed -n "${START_LINE},${END_LINE}p" "$SESSION_FILE" | jq -r --argjson offset "$OFFSET" '
# Extract text from content (string or array of blocks)
def get_text:
  if type == "array" then
    map(select(.text) | .text) | join(" ")
  elif type == "string" then .
  else ""
  end;

# Summarize tool_use input args (pick key args, truncate)
def tool_use_summary:
  .name as $name |
  (.input // {}) |
  [to_entries[] |
    select(.key | IN("command","file_path","pattern","query","url","prompt","skill","description","notebook_path","old_string")) |
    "\(.key)=\(.value | tostring | .[0:60])"
  ] |
  if length > 0 then "\($name)(\(join(", ")))"
  else $name
  end;

# Brief summary of tool result content
def tool_result_brief:
  if (.is_error // false) then
    "ERROR: \(.content // "" | if type == "string" then . else tostring end | .[0:100])"
  elif .content then
    (.content | if type == "string" then . elif type == "array" then
      [.[] | select(.text) | .text] | join(" ") | .[0:100]
    else tostring | .[0:100] end)
  else "(no output)"
  end;

# Line number in original file (1-indexed)
(input_line_number + $offset) as $ln |

if .type == "user" then
  if (.message.content | type) == "array" then
    [.message.content[] |
      if .type == "tool_result" then
        "**Tool Result (M#\($ln)):** \(.tool_use_id // "tool") → \(tool_result_brief)"
      elif .type == "text" then
        "**User (M#\($ln)):** \(.text // "")"
      elif type == "string" then
        "**User (M#\($ln)):** \(.)"
      else empty
      end
    ] | join("\n\n")
  elif .message.content then
    "**User (M#\($ln)):** \(.message.content | if type == "string" then . else tostring end)"
  else empty
  end

elif .type == "assistant" then
  if (.message.content | type) == "array" then
    [.message.content[] |
      if .type == "text" then
        "**Assistant (M#\($ln)):** \(.text // "")"
      elif .type == "tool_use" then
        "  \u2192 Used \(tool_use_summary)"
      else empty
      end
    ] | join("\n\n")
  elif .message.content then
    "**Assistant (M#\($ln)):** \(.message.content | get_text)"
  else empty
  end

elif .type == "summary" then
  "\n[Session compacted at M#\($ln)]\n"

elif .type == "system" then
  if input_line_number <= 1 then "[System prompt at M#\($ln)]"
  else empty
  end

else empty
end

| select(. and length > 0)
'
