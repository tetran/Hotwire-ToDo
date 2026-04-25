#!/bin/bash
# check-subagent-response.sh
# Manual format check for a subagent response, reusing the SubagentStop hook logic
# in `.claude/hooks/subagent_stop_format_check.sh`. Use this from the orchestrator
# at I2 / I4 post-receipt validation, since the hook does not fire on maxTurns
# force-stop (see Issue #332 post-mortem and docs/process/DELEGATION.md → Dispatch Sizing).
#
# Usage:
#   .claude/scripts/check-subagent-response.sh <agent_type> < response.txt
#
# Reads the full agent response from stdin (verbatim text, including all
# section headers). Exits 0 on pass, 1 on fail. On fail, the reason from
# the hook script is printed to stderr.
#
# Agent types covered (see subagent_stop_format_check.sh for the schema):
#   - rails-developer / react-developer  → 5-section implementation format
#   - rails-reviewer / react-reviewer / architecture-reviewer → 3-section reviewer format
#   - other types                         → pass-through (exit 0)

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <agent_type> < response.txt" >&2
  exit 2
fi

AGENT_TYPE="$1"
RESPONSE=$(cat)

# Empty response is treated as failure here even though the underlying hook
# passes empty through (a sane choice in hook context, since no message means
# nothing to validate). At post-receipt time, an empty response from the
# orchestrator's perspective indicates the subagent crashed or produced nothing,
# which is exactly the failure mode this check exists to catch.
if [ -z "$RESPONSE" ]; then
  echo "FORMAT ERROR: empty response (no last_assistant_message). Subagent crashed before emitting any text." >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$REPO_ROOT" ]; then
  echo "error: not inside a git repository" >&2
  exit 2
fi

HOOK_SCRIPT="$REPO_ROOT/.claude/hooks/subagent_stop_format_check.sh"
if [ ! -x "$HOOK_SCRIPT" ]; then
  echo "error: $HOOK_SCRIPT not found or not executable" >&2
  exit 2
fi

PAYLOAD=$(jq -nc \
  --arg type "$AGENT_TYPE" \
  --arg msg "$RESPONSE" \
  '{agent_type: $type, last_assistant_message: $msg}')

# The hook script exits 2 to "block" in hook context; for our manual usage we
# translate that into exit 1 (fail) and surface the reason on stderr.
set +e
HOOK_OUTPUT=$(printf '%s' "$PAYLOAD" | bash "$HOOK_SCRIPT" 2>&1)
HOOK_RC=$?
set -e

if [ "$HOOK_RC" -eq 0 ]; then
  exit 0
fi

echo "$HOOK_OUTPUT" >&2
exit 1
