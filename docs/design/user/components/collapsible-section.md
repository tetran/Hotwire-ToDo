# Collapsible Section

Native `<details>/<summary>` used for opt-in settings that stay inline with a form. Rendered as a **card**:

```css
.collapsible-section {
  border: 1px solid var(--border);
  border-radius: var(--radius-md);
  padding: var(--space-2) var(--space-3);
}
.collapsible-section[open] { padding-bottom: var(--space-3); }
.collapsible-section > summary {
  font-size: var(--text-sm);
  color: var(--form-text);
  cursor: pointer;
}
.collapsible-section[open] > summary { font-weight: 500; }
```

- `summary` aligns with small-icon conventions (see [foundations/icons.md](../foundations/icons.md)): icon at `var(--color-muted)`, **not** `var(--color-accent)` — the accent color is reserved for state indicators (badges, checked chips), not for static decoration.
- Body content appears with `margin-top: var(--space-3)` after open.

