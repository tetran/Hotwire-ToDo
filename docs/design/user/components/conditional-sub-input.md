# Conditional Sub-input

A radio or checkbox that reveals/activates an inline sub-input (e.g. "after [N] times", "until [date]"). The row is a single flex line so the radio and its dependent controls read as one unit:

```css
.conditional-option {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex-wrap: wrap;
  color: var(--color-muted);
}
.conditional-option:has(input:checked) {
  color: var(--form-text);
  font-weight: 500;
}
```

- **Do not** dim non-selected rows with `opacity` — it visually collides with the `:disabled` convention. Use `var(--color-muted)` instead.
- The sub-input stays enabled even when its row is not selected; tabbing into the sub-input should implicitly activate its radio in a Stimulus controller (see `recurrence_form_controller.js` for the reference pattern).

**Used by**: `.task-form__recurrence-end-option` (see `tasks.css:397-`).

