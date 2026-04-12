#!/bin/bash
# PreToolUse hook (Bash): Block dangerous commands for subagents.
# Only active for subagents (agent_type present in stdin JSON).
#
# Blocked:
#   - git write operations (branch, commit, push, checkout, etc.)
#   - gh CLI
#   - Full test suite (bin/rails test with no args, bin/rails test:all)
#
# Allowed:
#   - git read operations (status, log, diff, show, rev-parse, ls-files)
#   - Domain test suite runs (bin/rails test <specific path>)

INPUT=$(cat)

AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // empty')
[ -z "$AGENT_TYPE" ] && exit 0

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$COMMAND" ] && exit 0

# Block git write operations.
# Match git at line start, after &&, after ;, or after | to avoid false positives
# with commands like: echo "git commit example"
if echo "$COMMAND" | grep -qE '(^|&&|;|\|)\s*git\s+(branch|commit|push|checkout|switch|merge|rebase|tag|add|stash|reset|clean|cherry-pick|am|apply)\b'; then
  echo "BLOCKED: git write operations are reserved for the orchestrator. Report this under Deviations if it blocks your task." >&2
  exit 2
fi

# Block gh CLI
if echo "$COMMAND" | grep -qE '(^|&&|;|\|)\s*gh\s'; then
  echo "BLOCKED: gh CLI is reserved for the orchestrator." >&2
  exit 2
fi

# Block full test suite runs.
# "bin/rails test" with no args or "bin/rails test:all" → blocked
# "bin/rails test test/controllers/..." → allowed (has path argument)
if echo "$COMMAND" | grep -qE '\bbin/rails\s+test(:all)?\s*$'; then
  echo "BLOCKED: Full test suite (bin/rails test or bin/rails test:all) is reserved for the orchestrator's I3 step. Run only the domain test suite specified in the payload." >&2
  exit 2
fi

exit 0
