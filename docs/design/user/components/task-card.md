# Task Card

The primary unit of the task list — complete-check + name + description + due-date + actions.

Structure (see `tasks.css` and `app/views/tasks/_task.html.erb`):

```
.task-card
  .task-card__content
    button.task-card__complete-check  (16x16 circular checkbox)
    .task-card__name (link to task detail)
    .task-card__description           (0.8rem, #999)
    .task-card__due-date              (flex with icon)
  .horizontal-actions                  (icon action buttons)
```

Modifiers: `.task-card--complete` (strikethrough + grey check), `.overdue` (red due-date text), `.task-card--subtask` (compact padding).

When the card contains subtasks, it is wrapped in `.task-card-wrapper--has-subtasks` which owns the bottom border, and `.task-card__subtasks` holds the child list with `padding-left: 1.5rem`.

**Recommended**: extract the "muted meta row" pattern (icon + `0.8rem` text, color `#999`) into a shared `.meta-row` utility used by due-date, subtask-badge, and search-result parent labels.

