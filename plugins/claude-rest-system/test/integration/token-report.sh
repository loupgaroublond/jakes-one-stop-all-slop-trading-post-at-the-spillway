#!/bin/bash
# Generate token usage report from integration test session transcripts
# Usage: token-report.sh <results_dir>
#   e.g.: token-report.sh results/latest
#         token-report.sh results/20260212-183920
set -euo pipefail

RESULTS_DIR="${1:?Usage: token-report.sh <results_dir>}"
SESSIONS_DIR="$RESULTS_DIR/claude-sessions"

if [ ! -d "$SESSIONS_DIR" ]; then
  echo "ERROR: No claude-sessions/ directory in $RESULTS_DIR" >&2
  exit 1
fi

COUNT=$(find "$SESSIONS_DIR" -name "*.jsonl" | wc -l | tr -d ' ')
if [ "$COUNT" -eq 0 ]; then
  echo "ERROR: No .jsonl files in $SESSIONS_DIR" >&2
  exit 1
fi

# --- Extract per-session stats ---
declare -a NAMES MODELS TURNS INPUTS CCS CRS OUTPUTS TOTALS

i=0
for f in "$SESSIONS_DIR"/*.jsonl; do
  NAMES[$i]=$(basename "$f" .jsonl)
  MODELS[$i]=$(jq -r 'select(.type == "assistant") | select(.message.model) | .message.model' "$f" | head -1)
  TURNS[$i]=$(jq -c 'select(.type == "assistant") | select(.message.usage)' "$f" | wc -l | tr -d ' ')
  INPUTS[$i]=$(jq -r 'select(.type == "assistant") | select(.message.usage) | .message.usage.input_tokens' "$f" | awk '{s+=$1}END{print s+0}')
  CCS[$i]=$(jq -r 'select(.type == "assistant") | select(.message.usage) | .message.usage.cache_creation_input_tokens' "$f" | awk '{s+=$1}END{print s+0}')
  CRS[$i]=$(jq -r 'select(.type == "assistant") | select(.message.usage) | .message.usage.cache_read_input_tokens' "$f" | awk '{s+=$1}END{print s+0}')
  OUTPUTS[$i]=$(jq -r 'select(.type == "assistant") | select(.message.usage) | .message.usage.output_tokens' "$f" | awk '{s+=$1}END{print s+0}')
  TOTALS[$i]=$(( ${INPUTS[$i]} + ${CCS[$i]} + ${CRS[$i]} + ${OUTPUTS[$i]} ))
  i=$((i + 1))
done

# --- Print report ---
echo "# Token Usage Report"
echo ""
echo "Results: $RESULTS_DIR"
echo "Sessions: $COUNT"
echo ""

# Per-session details
for j in $(seq 0 $((i - 1))); do
  name="${NAMES[$j]}"
  if [[ "$name" == agent-* ]]; then role="subagent"; else role="main"; fi

  echo "## ${name} (${role})"
  echo ""
  echo "| Field | Value |"
  echo "|-------|-------|"
  echo "| Model | ${MODELS[$j]} |"
  echo "| API turns | ${TURNS[$j]} |"
  echo "| Fresh input | ${INPUTS[$j]} |"
  echo "| Cache write | ${CCS[$j]} |"
  echo "| Cache read | ${CRS[$j]} |"
  echo "| Output | ${OUTPUTS[$j]} |"
  echo "| **Total** | **${TOTALS[$j]}** |"
  echo ""
done

# --- Grand totals ---
G_TURNS=0; G_INPUT=0; G_CC=0; G_CR=0; G_OUTPUT=0; G_TOTAL=0
MAIN_COUNT=0; SUB_COUNT=0
for j in $(seq 0 $((i - 1))); do
  G_TURNS=$((G_TURNS + ${TURNS[$j]}))
  G_INPUT=$((G_INPUT + ${INPUTS[$j]}))
  G_CC=$((G_CC + ${CCS[$j]}))
  G_CR=$((G_CR + ${CRS[$j]}))
  G_OUTPUT=$((G_OUTPUT + ${OUTPUTS[$j]}))
  G_TOTAL=$((G_TOTAL + ${TOTALS[$j]}))
  name="${NAMES[$j]}"
  if [[ "$name" == agent-* ]]; then SUB_COUNT=$((SUB_COUNT + 1)); else MAIN_COUNT=$((MAIN_COUNT + 1)); fi
done
G_TOTAL_IN=$((G_INPUT + G_CC + G_CR))

echo "---"
echo ""
echo "## Grand Total"
echo ""
echo "| Metric | Value |"
echo "|--------|-------|"
echo "| Sessions | $COUNT ($MAIN_COUNT main + $SUB_COUNT subagents) |"
echo "| API turns | $G_TURNS |"
echo "| Fresh input | $G_INPUT |"
echo "| Cache write | $G_CC |"
echo "| Cache read | $G_CR |"
echo "| Total input | $G_TOTAL_IN |"
echo "| Output | $G_OUTPUT |"
echo "| **Grand total** | **$G_TOTAL** |"
echo ""

# --- Cost estimate (rough) ---
# Pricing as of 2025: opus input $15/MTok, output $75/MTok; haiku input $0.80/MTok, output $4/MTok
# Cache write = 1.25x input price, cache read = 0.10x input price
echo "## Cost Estimate (approximate)"
echo ""
COST_CENTS=0
for j in $(seq 0 $((i - 1))); do
  model="${MODELS[$j]}"
  input="${INPUTS[$j]}"; cc="${CCS[$j]}"; cr="${CRS[$j]}"; out="${OUTPUTS[$j]}"
  if [[ "$model" == *opus* ]]; then
    # Opus: $15/MTok input, $75/MTok output, cache write 1.25x, cache read 0.1x
    cost=$(awk "BEGIN{printf \"%.4f\", ($input * 15 + $cc * 18.75 + $cr * 1.5 + $out * 75) / 1000000}")
  elif [[ "$model" == *haiku* ]]; then
    # Haiku: $0.80/MTok input, $4/MTok output, cache write 1.25x, cache read 0.1x
    cost=$(awk "BEGIN{printf \"%.4f\", ($input * 0.80 + $cc * 1.0 + $cr * 0.08 + $out * 4) / 1000000}")
  else
    # Default sonnet pricing: $3/MTok input, $15/MTok output
    cost=$(awk "BEGIN{printf \"%.4f\", ($input * 3 + $cc * 3.75 + $cr * 0.3 + $out * 15) / 1000000}")
  fi
  name="${NAMES[$j]}"
  if [[ "$name" == agent-* ]]; then role="sub"; else role="main"; fi
  echo "- ${name} (${role}, ${model}): \$${cost}"
done

TOTAL_COST=0
for j in $(seq 0 $((i - 1))); do
  model="${MODELS[$j]}"
  input="${INPUTS[$j]}"; cc="${CCS[$j]}"; cr="${CRS[$j]}"; out="${OUTPUTS[$j]}"
  if [[ "$model" == *opus* ]]; then
    c=$(awk "BEGIN{print ($input * 15 + $cc * 18.75 + $cr * 1.5 + $out * 75) / 1000000}")
  elif [[ "$model" == *haiku* ]]; then
    c=$(awk "BEGIN{print ($input * 0.80 + $cc * 1.0 + $cr * 0.08 + $out * 4) / 1000000}")
  else
    c=$(awk "BEGIN{print ($input * 3 + $cc * 3.75 + $cr * 0.3 + $out * 15) / 1000000}")
  fi
  TOTAL_COST=$(awk "BEGIN{print $TOTAL_COST + $c}")
done
echo ""
echo "**Total estimated cost: \$$(awk "BEGIN{printf \"%.2f\", $TOTAL_COST}")**"
