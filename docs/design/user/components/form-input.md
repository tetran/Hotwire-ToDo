# Form Input

Text inputs and textareas inheriting Water.css with narrow overrides for full-width layouts.

**Current**: `<input>` and `<textarea>` elements inherit Water.css styles. Custom additions:

- `.full-width-input` / `.form-item-inline__input` — `box-sizing: border-box; width: 100%`
- `.form-item-inline` — single-row flex layout pairing input + button
- `.task-form__description` — boxed trix-editor container with `6px` radius, `1px` border, focus ring `2px var(--focus)`

**Recommended**: standardize focus styling so all inputs use the same `box-shadow: 0 0 0 2px var(--focus)` ring Water.css applies by default; never remove focus rings with `box-shadow: none` except on non-text controls (icon buttons, checkboxes).

