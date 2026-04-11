# Fieldset Group

Logical groups of related form fields inside a form use `<fieldset>` + `<legend>` **without a border**. The legend acts as a small section heading:

```css
.fieldset-group { border: 0; padding: 0; margin: 0; }
.fieldset-group > legend {
  font-size: var(--text-xs);
  color: var(--color-muted);
  padding: 0;
  margin-bottom: var(--space-1);
}
```

Avoid the native browser `<fieldset>` border — it creates a **box-in-box** look when placed inside a card (see [collapsible-section.md](collapsible-section.md)). Use nested fieldsets only for semantic grouping; rely on spacing (`gap: var(--space-2)`) and the small legend caption for visual separation.

