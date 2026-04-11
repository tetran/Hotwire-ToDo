# Migration Notes and Implementation Checklist

The token set in [foundations/tokens.md](foundations/tokens.md) is **additive**. Existing CSS will continue to work; migrate incrementally, one component file at a time.

## Priority Migrations

1. **Eliminate `#999` literals** — 7+ occurrences across `tasks.css` and `search.css`. Replace with `var(--color-muted)`.
2. **Eliminate `#ccc` / `#ddd` literals** — hover backgrounds in `header-menu.css` and `projects.css` should use `var(--color-surface-hover)`; `.tab.active` should use `var(--color-surface-active)`.
3. **Fix accessibility regressions** — remove `outline: none; box-shadow: none` on `.menu-button:focus`, `.menu-list li button:focus`, `.task-card__complete-check:focus`; rely on Water.css focus ring or define one on `--focus`.
4. **Reveal comment actions on focus-within** — add `.comment-card:focus-within .comment-card__actions { visibility: visible }` so keyboard users can reach actions.
5. **Introduce `--color-highlight-bg`** and replace the "assigned to me" `#f2dede` misuse with a cyan-family highlight.
6. **Consolidate form error styles** (`.form__error li` + `.simple-error` → `.field-error`).

## Checklist for New Components

When building a new user-facing component:

1. Reuse Water.css element styles where possible; add custom CSS only for structural layout or brand distinction.
2. Use BEM-style class names: `block__element--modifier`.
3. Reference tokens, never hex literals: `var(--color-accent)` not `#0096bf`.
4. Reference spacing tokens, never raw rem/px for gap/padding/margin: `var(--space-3)` not `0.75rem`.
5. Use Material Symbols Outlined for icons, inline-flex alignment with `gap: var(--space-1)`.
6. Ensure keyboard navigability: do not suppress focus outlines on interactive controls.
7. For overlays, use native `<dialog>` (reuse `.modal-base`).
8. For Turbo Stream targets, assume the component can be replaced at any time — no JS state that outlives the DOM node.
9. Semantic colors: error red (`--color-error`) is reserved for errors and destructive actions only.
10. No custom fonts, no dark theme — stay within the light + system-font aesthetic.

## What Not to Do

- Do not introduce a CSS framework (Tailwind, Bootstrap). The Rails/ERB stack stays on plain CSS + Water.css.
- Do not add a sidebar or alter the horizontal header layout.
- Do not change the cyan brand accent `#0096bf` or introduce a second accent color.
- Do not load additional web fonts for body text.
- Do not replicate admin-SPA patterns (Syne/DM Mono typography, dark surfaces, indigo accent) — the two applications are deliberately distinct.

