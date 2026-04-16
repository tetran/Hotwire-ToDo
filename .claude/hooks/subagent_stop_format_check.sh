#!/bin/bash
# SubagentStop hook: Validate subagent response format.
#
# Implementation agents (rails-developer, react-developer):
#   5-section format (Summary, Changed Files, Test Result, Deviations, Handoff Notes)
#
# Reviewer agents (rails-reviewer, react-reviewer, architecture-reviewer):
#   3-section format (Findings, Medium/Low Summary, Reviewer Notes)
#
# Exit 2 blocks the response and asks the subagent to regenerate.

INPUT=$(cat)

RESPONSE=$(echo "$INPUT" | jq -r '.last_assistant_message // empty')
[ -z "$RESPONSE" ] && exit 0

AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // empty')
FIRST_LINE=$(echo "$RESPONSE" | head -1 | sed 's/^[[:space:]]*//')

# Reviewer agents: 3-section format
if echo "$AGENT_TYPE" | grep -qE '^(rails|react|architecture)-reviewer$'; then
  if [ "$FIRST_LINE" != "### Findings" ]; then
    echo "FORMAT ERROR: Reviewer response must begin with '### Findings' on the very first line. Got: '$FIRST_LINE'. Rewrite your entire response starting with '### Findings'." >&2
    exit 2
  fi

  MISSING=""
  for section in "### Findings" "### Medium/Low Summary" "### Reviewer Notes"; do
    if ! echo "$RESPONSE" | grep -q "^${section}"; then
      MISSING="$MISSING '$section'"
    fi
  done

  if [ -n "$MISSING" ]; then
    echo "FORMAT ERROR: Missing required section(s):${MISSING}. All three sections must be present. Rewrite your entire response with all sections." >&2
    exit 2
  fi

  exit 0
fi

# Implementation agents: 5-section format
# Only validate known implementation agent types. Unknown types (plan-reviewer, Explore, etc.) pass through.
if ! echo "$AGENT_TYPE" | grep -qE '^(rails|react)-developer$'; then
  exit 0
fi

if [ "$FIRST_LINE" != "### Summary" ]; then
  echo "FORMAT ERROR: Response must begin with '### Summary' on the very first line. Got: '$FIRST_LINE'. Rewrite your entire response starting with '### Summary'." >&2
  exit 2
fi

MISSING=""
for section in "### Summary" "### Changed Files" "### Test Result" "### Deviations from Plan"; do
  if ! echo "$RESPONSE" | grep -q "^${section}"; then
    MISSING="$MISSING '$section'"
  fi
done

if ! echo "$RESPONSE" | grep -q "^### Handoff Notes"; then
  MISSING="$MISSING '### Handoff Notes'"
fi

if [ -n "$MISSING" ]; then
  echo "FORMAT ERROR: Missing required section(s):${MISSING}. All five sections must be present. Rewrite your entire response with all sections." >&2
  exit 2
fi

exit 0
