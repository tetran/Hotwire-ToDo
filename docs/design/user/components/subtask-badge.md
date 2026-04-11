# Subtask Badge

Expand/collapse indicator under a parent task showing the subtask count.

`.task-card__subtask-badge` (`tasks.css`): flex, icon + count, 0.8rem, `#999`, `padding-left: 1.5rem` (indents under the parent task text). Expand/collapse rotates the chevron via `transform: rotate(…)` with `transition: transform 0.2s`.

**Recommended**: document the 1.5rem left-indent as `--subtask-indent` to share with `.task-card__subtasks`.

