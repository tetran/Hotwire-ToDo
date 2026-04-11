# Toggle Chip

Pill-shaped multi-select control for compact sets (days of week, tags, enum options). Each chip is a `<label>` wrapping a `.visually-hidden` checkbox (§ common.css), so the label itself becomes the interactive surface.

```css
.chip {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: var(--space-1) var(--space-2);
  border: 1px solid var(--border);
  border-radius: var(--radius-pill);
  font-size: var(--text-xs);
  color: var(--form-text);
  background: transparent;
  cursor: pointer;
  user-select: none;
}
.chip:has(input:checked) {
  background: color-mix(in srgb, var(--color-accent) 12%, transparent);
  color: var(--color-accent);
  border-color: var(--color-accent);
}
.chip:focus-within {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}
```

- **Accessibility**: `:focus-within` outline is **required** — without it, keyboard users lose focus tracking once the native checkbox is hidden.
- **Contrast**: the selected state uses a **tinted background** (12% accent over page) with accent-colored text. This meets WCAG AA (~4.5:1 for `#0096bf` over tinted background on white) while a solid `#fff` on `#0096bf` fill would fall to ~3.4:1.
- **Layout**: for fixed-arity sets (7 weekdays, 12 months) use a CSS grid (`grid-template-columns: repeat(N, 1fr); gap: var(--space-1)`) for rhythm. For variable sets, use flex-wrap.

**Used by**: `.task-form__recurrence-weekday` (see `tasks.css:397-`).

