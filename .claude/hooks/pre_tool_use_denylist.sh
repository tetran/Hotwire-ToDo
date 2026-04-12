#!/bin/bash
# PreToolUse hook (Write|Edit): Block edits to denylist paths.
# Only active for subagents (agent_type present in stdin JSON).
#
# Universal denylist (all subagents):
#   .progress/*, .claude/*, docs/*, CLAUDE.md
#
# Domain-specific denylist:
#   rails-developer: app/javascript/**
#   react-developer: app/controllers/**, app/models/**, app/services/**,
#                    config/routes.rb, db/**, test/controllers/**, test/models/**

INPUT=$(cat)

AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // empty')
[ -z "$AGENT_TYPE" ] && exit 0

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -z "$REPO_ROOT" ] && exit 0

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$FILE_PATH" ] && exit 0

REL_PATH="${FILE_PATH#$REPO_ROOT/}"

# --- Universal denylist ---
case "$REL_PATH" in
  .progress/*)
    echo "BLOCKED: '$REL_PATH' is owned by the orchestrator (.progress/). Report this under Deviations." >&2
    exit 2 ;;
  .claude/*)
    echo "BLOCKED: '$REL_PATH' is owned by the orchestrator (.claude/). Report this under Deviations." >&2
    exit 2 ;;
  docs/*)
    echo "BLOCKED: '$REL_PATH' is owned by the orchestrator (docs/). Report this under Deviations." >&2
    exit 2 ;;
  CLAUDE.md)
    echo "BLOCKED: 'CLAUDE.md' is owned by the orchestrator. Report this under Deviations." >&2
    exit 2 ;;
esac

# --- Domain-specific denylist ---
if [ "$AGENT_TYPE" = "rails-developer" ]; then
  case "$REL_PATH" in
    app/javascript/*)
      echo "BLOCKED: '$REL_PATH' belongs to the React domain. rails-developer cannot edit app/javascript/**. Report this under Deviations." >&2
      exit 2 ;;
    config/routes.rb)
      echo "BLOCKED: 'config/routes.rb' is owned by the orchestrator. Report the required route entry under Handoff Notes." >&2
      exit 2 ;;
  esac
fi

if [ "$AGENT_TYPE" = "react-developer" ]; then
  case "$REL_PATH" in
    app/controllers/*|app/models/*|app/services/*)
      echo "BLOCKED: '$REL_PATH' belongs to the Rails domain. react-developer cannot edit this path. Report this under Deviations." >&2
      exit 2 ;;
    config/routes.rb)
      echo "BLOCKED: 'config/routes.rb' is owned by the orchestrator. Report this under Deviations." >&2
      exit 2 ;;
    db/*)
      echo "BLOCKED: '$REL_PATH' belongs to the Rails domain. react-developer cannot edit db/**. Report this under Deviations." >&2
      exit 2 ;;
    test/controllers/*|test/models/*)
      echo "BLOCKED: '$REL_PATH' belongs to the Rails domain. react-developer cannot edit this test path. Report this under Deviations." >&2
      exit 2 ;;
    app/javascript/admin/App.tsx)
      echo "BLOCKED: 'App.tsx' is owned by the orchestrator. Report the required route entry under Handoff Notes for orchestrator." >&2
      exit 2 ;;
  esac
fi

exit 0
