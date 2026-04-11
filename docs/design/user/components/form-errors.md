# Form Errors

Per-field and summary error styles displayed near form fields.

**Current (`form.css` + `common.css`)**:

```css
.form__error           /* ul, no list padding, margin-top 0.5rem */
.form__error li        /* color #fc5050, list-style none, 0.9rem, padding 0 0 0.5rem 0.5rem */
.simple-error          /* same color, 0.9rem, padding 0 0 0.5rem 0.5rem */
```

**Recommended**: consolidate `.form__error li` and `.simple-error` into a single `.field-error` class with a shared token (`color: var(--color-error); font-size: var(--text-sm)`).

