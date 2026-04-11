# Icon Conventions

All icons are rendered via Material Symbols Outlined (loaded from Google Fonts in `application.html.erb`).

## Sizing Scale (observed)

| Size       | Usage                                                |
|------------|-------------------------------------------------------|
| `0.9rem`   | Search result parent breadcrumb                       |
| `1rem`     | Task due-date, subtask badge, show-task parent link   |
| `1.2rem`   | Label-with-icon, project-selector row actions         |
| `1.25rem`  | Search input icon, search filter toggle               |
| `1.4rem`   | Assignee-list member sign, project add button         |
| `1.5rem`   | `.menu-button` trigger icons                          |
| `24px`     | Unassign action button                                |

## Vertical Alignment

Icons are inline with adjacent text and require per-context alignment tweaks:

| Context               | Alignment                          |
|-----------------------|------------------------------------|
| `.label-with-icon`    | `vertical-align: -4px`              |
| `.menu-button`        | `vertical-align: -0.25rem`          |
| `.assignee-list__member-sign` | `vertical-align: -0.5rem`   |
| `.project-selector__add-button` | `vertical-align: -6px`    |

**Recommended**: adopt the pattern `display: inline-flex; align-items: center; gap: var(--space-1)` on icon+text containers (already used by `.task-card__due-date`, `.search-result__parent`) and retire per-icon `vertical-align` hacks.

## Icon Color

Icons inherit `color` from the parent. Utility: `.horizontal-actions .material-symbols-outlined { color: var(--text-main) }`. Use `var(--color-error)` only on destructive actions (unassign).

