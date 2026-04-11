#!/bin/bash
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -z "$REPO_ROOT" ] && exit 0

PROGRESS_DIR="$REPO_ROOT/.progress"

if [ -d "$PROGRESS_DIR" ]; then
  REMINDER=""
  for f in "$PROGRESS_DIR"/issue-*.md; do
    [ -f "$f" ] || continue
    if grep -q '^\- \[ \]' "$f"; then
      ISSUE=$(basename "$f" .md)
      NEXT=$(grep '^\- \[ \]' "$f" | head -1 | sed 's/^\- \[ \] //')
      REMINDER="${REMINDER} | $ISSUE: next→ $NEXT"
    fi
  done

  if [ -n "$REMINDER" ]; then
    MSG="WORKFLOW: Update .progress/issue-XXXXX.md immediately after completing each step.${REMINDER}"
    echo "{\"systemMessage\": \"$MSG\"}"
    exit 0
  fi
fi

# No active progress files → inject workflow summary
MSG="WORKFLOW: **Update .progress/issue-XXXXX.md immediately after completing each step.** Full spec: docs/process/WORKFLOW.md. Standard Flow → 1.Issue 2.progress file 3.plan 4.plan confirm 5.post plan to issue 6.branch 7.implement 8.test 9.local-review 10.PR 11.review-response. Lightweight Flow (typo/small change) → branch, implement, test, PR, review-response only."
echo "{\"systemMessage\": \"$MSG\"}"
