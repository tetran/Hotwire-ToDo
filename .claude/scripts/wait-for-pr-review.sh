#!/bin/bash
# wait-for-pr-review.sh
# Polls PR review endpoints every 3 minutes for up to ~21 minutes.
# Exits 0 when new review comments/reviews arrive after this script started.
# Exits 1 on timeout.
#
# Usage: wait-for-pr-review.sh <pr-number>
#
# Intended to be launched from Claude Code with `run_in_background: true`.
# When the background process exits, Claude will be notified automatically.

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <pr-number>" >&2
  exit 2
fi

PR="$1"
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
if [ -z "$REPO" ]; then
  echo "Failed to determine repo (are you inside a gh-enabled git repo?)" >&2
  exit 2
fi

START=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
echo "Watching PR #$PR in $REPO for new review activity since $START"

MAX_ATTEMPTS="${MAX_ATTEMPTS:-7}"
INTERVAL="${INTERVAL:-180}"

for i in $(seq 1 $MAX_ATTEMPTS); do
  sleep "$INTERVAL"

  # Count items created after START across all three endpoints.
  issue_new=$(gh api "repos/$REPO/issues/$PR/comments" \
    --jq "[.[] | select(.created_at > \"$START\")] | length" 2>/dev/null || echo 0)
  pull_new=$(gh api "repos/$REPO/pulls/$PR/comments" \
    --jq "[.[] | select(.created_at > \"$START\")] | length" 2>/dev/null || echo 0)
  review_new=$(gh api "repos/$REPO/pulls/$PR/reviews" \
    --jq "[.[] | select(.submitted_at != null and .submitted_at > \"$START\")] | length" 2>/dev/null || echo 0)

  total=$((issue_new + pull_new + review_new))

  if [ "$total" -gt 0 ]; then
    echo "Poll $i/$MAX_ATTEMPTS — found $total new review item(s) (issues:$issue_new pulls:$pull_new reviews:$review_new)."
    exit 0
  fi

  echo "Poll $i/$MAX_ATTEMPTS — no new review yet."
done

echo "Timed out waiting for review on PR #$PR after $((MAX_ATTEMPTS * INTERVAL)) seconds."
exit 1
