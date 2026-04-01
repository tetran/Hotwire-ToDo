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
    MSG="WORKFLOW: 作業が進んだらすぐに .progress/issue-XXXXX.md ファイルを更新すること。${REMINDER}"
    echo "{\"systemMessage\": \"$MSG\"}"
    exit 0
  fi
fi

# No active progress files → inject workflow summary
MSG="WORKFLOW: **作業が進んだらすぐに .progress/issue-XXXXX.md を更新すること。** Standard Flow → 1.Issue作成 2.progress file 3.plan 4.plan確認 5.issueにplan記載 6.ブランチ 7.実装 8.テスト 9.PR。Lightweight Flow（typo/小変更）→ ブランチ・実装・テスト・PRのみ。"
echo "{\"systemMessage\": \"$MSG\"}"
