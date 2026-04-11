# Assignee List

Assignee dropdown listing project members with assign/unassign actions.

`.assignee-list` + `.assignee-list__member` (`tasks.css`): members rendered as rows inside the dropdown `.menu-list`, each with avatar, name, and a button. Unassign row uses error color:

```css
.assignee-list__unassign .assignee-list__member-info button { color: var(--color-error); }
```

The "assigned to me" menu button highlights with `#f2dede` (see [foundations/colors.md](../foundations/colors.md) — **recommend replacing with a dedicated highlight token**).

