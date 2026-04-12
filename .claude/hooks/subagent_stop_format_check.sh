#!/bin/bash
# SubagentStop hook: Validate subagent response format.
#
# Checks:
#   1. Response starts with "### Summary" on the first line
#   2. All five required section headers are present
#
# Exit 2 blocks the response and asks the subagent to regenerate.

INPUT=$(cat)

RESPONSE=$(echo "$INPUT" | jq -r '.last_assistant_message // empty')
[ -z "$RESPONSE" ] && exit 0

FIRST_LINE=$(echo "$RESPONSE" | head -1 | sed 's/^[[:space:]]*//')

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
