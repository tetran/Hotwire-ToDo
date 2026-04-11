# Button

Primary / secondary / danger / icon / link button variants.

**Current (`water-extension.css`)**: Water.css styles all `<button>` and `input[type="submit"]` elements by default. Custom overrides:

```css
.btn                       /* base: neutral surface, 6px radius, 8px padding */
.btn:hover                 /* background: var(--button-hover) */
.btn:active                /* transform: translateY(2px) */
button.primary             /* background: var(--button-primary); color: var(--button-primary-text) */
button.primary:hover       /* background: var(--button-primary-hover) */
```

**Recommended variant matrix**:

| Variant    | Classes                    | Visual                                               |
|------------|----------------------------|-------------------------------------------------------|
| Primary    | `.btn.primary` or `button.primary` | Cyan `#0096bf` fill, light text `#eee`         |
| Secondary  | `.btn` (no modifier)       | Water.css `--button-base` fill, `--form-text` text    |
| Danger     | `.btn.danger` (**new**)    | `var(--color-error)` text, border, or fill           |
| Icon       | `.btn.btn--icon` (**new**) | Transparent, `2px` padding, hover `--overlay-hover`  |
| Link       | Inline `<a>`               | Inherits text color; underline on hover              |

**Target**: introduce `.btn.danger` and `.btn.btn--icon` to replace the ad-hoc icon buttons in `.horizontal-actions` and assignee-unassign rows.

