#!/bin/bash
# SubagentStop hook: Log subagent responses for operational analysis.
# Output: .claude/logs/subagent_responses.jsonl (one JSON object per line)
#
# Each entry contains: timestamp, agent_type, agent_id, session_id,
# response length, first line, and full response text.

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -z "$REPO_ROOT" ] && exit 0

LOGDIR="$REPO_ROOT/.claude/logs"
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/subagent_responses.jsonl"

INPUT=$(cat)

AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // "unknown"')
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
RESPONSE=$(echo "$INPUT" | jq -r '.last_assistant_message // ""')
RESPONSE_LEN=$(echo "$RESPONSE" | wc -c | tr -d ' ')
FIRST_LINE=$(echo "$RESPONSE" | head -1)

jq -nc \
  --arg ts "$(date -Iseconds)" \
  --arg agent_type "$AGENT_TYPE" \
  --arg agent_id "$AGENT_ID" \
  --arg session_id "$SESSION_ID" \
  --argjson response_length "$RESPONSE_LEN" \
  --arg first_line "$FIRST_LINE" \
  --arg response "$RESPONSE" \
  '{timestamp: $ts, agent_type: $agent_type, agent_id: $agent_id, session_id: $session_id, response_length: $response_length, first_line: $first_line, response: $response}' \
  >> "$LOGFILE"

exit 0
