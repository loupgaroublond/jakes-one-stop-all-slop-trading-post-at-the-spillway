#!/bin/bash
# Generate compact inventory of session messages with line numbers and previews
# Usage: rest_session_inventory.sh <session_file>
# Output: line_number  type  "preview..."

if [ -z "$1" ]; then
  echo "Usage: rest_session_inventory.sh <session_file>" >&2
  exit 1
fi

jq -r '
  def preview:
    if . == null or . == "" then "(empty)"
    elif type == "array" then
      if length == 0 then "(empty array)"
      else
        (.[0] // {}) |
        if .text then .text
        elif .thinking then "(thinking)"
        elif type == "object" then "(object)"
        else tostring
        end
      end
    elif type == "string" then .
    else tostring
    end
    | gsub("\n"; " ")
    | gsub("\\s+"; " ")
    | if length > 60 then .[:57] + "..." else . end;

  def get_content:
    if .type == "summary" then (.summary // "(no summary)")
    elif .type == "user" then
      if .message.content then .message.content else "(no content)" end
    elif .type == "assistant" then
      if .message.content then .message.content else "(no content)" end
    elif .type == "tool_use" then
      "tool: \(.name // "unknown")"
    elif .type == "tool_result" then
      if .content then "result: \(.content | tostring | .[:40])" else "(no result)" end
    elif .type == "file-history-snapshot" then
      "files: \((.files // []) | length)"
    elif .type == "queue-operation" then
      "operation: \(.operation // "unknown")"
    else
      .type
    end;

  "\(input_line_number)\t\(.type)\t\"\(get_content | preview)\""
' "$1"
