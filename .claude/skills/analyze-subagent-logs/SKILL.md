---
name: analyze-subagent-logs
description: Analyze subagent response logs (.claude/logs/subagent_responses.jsonl) to find format violations, permission issues, scope drift, and other patterns worth addressing. Manual invocation only.
disable-model-invocation: true
---

# Analyze Subagent Response Logs

Manually-invoked skill for reviewing subagent (rails-developer / react-developer) response history. Use this to identify recurring issues and inform improvements to agent definitions, hooks, or delegation payloads.

## Log location

`.claude/logs/subagent_responses.jsonl`

Each line is a JSON object with: `timestamp`, `agent_type`, `agent_id`, `session_id`, `response_length`, `first_line`, `response`.

## Procedure

1. **Check the log exists.** If `.claude/logs/subagent_responses.jsonl` is missing or empty, report that there are no logs to analyze and stop.

2. **Produce a summary report** by running the following shell commands against the JSONL file:

  ```
  # Total entry count and date range
  jq -s '{total: length, earliest: (min_by(.timestamp) | .timestamp), latest: (max_by(.timestamp) | .timestamp)}' "$LOG"

  # Breakdown by agent_type
  jq -s 'group_by(.agent_type) | map({agent_type: .[0].agent_type, count: length})' "$LOG"

  # Format violations: first line is not "### Summary"
  jq -s '[.[] | select(.first_line != "### Summary")] | length' "$LOG"

  # Responses with missing sections (use \n prefix instead of ^ with "m" flag — jq multiline anchors are unreliable)
  jq -s '[.[] | select(
    (.response | test("\\n### Changed Files") | not) or
    (.response | test("\\n### Test Result") | not) or
    (.response | test("\\n### Deviations from Plan") | not) or
    (.response | test("\\n### Handoff Notes") | not)
  )] | map({timestamp, agent_type, agent_id, missing: (
    [if (.response | test("\\n### Changed Files") | not) then "Changed Files" else empty end,
    if (.response | test("\\n### Test Result") | not) then "Test Result" else empty end,
    if (.response | test("\\n### Deviations from Plan") | not) then "Deviations from Plan" else empty end,
    if (.response | test("\\n### Handoff Notes") | not) then "Handoff Notes" else empty end]
  )})' "$LOG"

  # Response length stats (min / avg / max)
  jq -s '{min: (min_by(.response_length) | .response_length), avg: ([.[].response_length] | add / length | round), max: (max_by(.response_length) | .response_length)}' "$LOG"
  ```

3. **Read the full response text** of any entries that look problematic (format violations, unusually long/short responses, missing sections). Examine:
   - **Format violations**: What did the agent write before `### Summary`? Is it a pattern (e.g., always starts with a status phrase)?
   - **Scope drift**: Does the response contain changes to files outside the typical domain? Look for paths in Changed Files that cross domain boundaries.
   - **Authorization gaps**: Are there Deviations entries mentioning blocked hooks or permission issues? These suggest the hooks or delegation payloads need adjustment.
   - **Handoff quality**: For rails-developer responses in sequential patterns, does Handoff Notes contain a complete API contract (method, path, params, response shape, auth)?

4. **Present findings** as a concise report with:
   - **Overview**: total logs, date range, breakdown by agent type
   - **Format compliance**: violation count, recurring patterns
   - **Scope issues**: any cross-domain edits or Denylist-related Deviations
   - **Hook effectiveness**: blocked operations found in logs, false positives if any
   - **Recommendations**: concrete changes to agent definitions, hooks, or delegation payloads

Keep the report under 300 words. Link to specific log entries (by timestamp + agent_id) when citing evidence.
