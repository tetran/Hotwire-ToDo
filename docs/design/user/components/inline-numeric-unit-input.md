# Inline Numeric Unit Input

A number input paired with a unit select (and optional suffix) on one line — e.g. `[ 2 ] [Weeks] every`. Reserves fewer vertical lines than a labeled 2-row layout:

```css
.numeric-unit {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex-wrap: wrap;
  font-size: var(--text-sm);
}
.numeric-unit input[type="number"] { width: 4rem; }
```

Use when the semantic reading is a natural-language phrase ("every 2 weeks", "2 週間ごと"). Keep the number field first (it carries primary focus) and position any fixed suffix text (`ごと`, `every`) at the end.

