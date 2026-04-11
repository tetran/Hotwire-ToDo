# CSS Variables Reference

The target token surface, consolidating what exists in `common.css` + `water-extension.css` and adding the recommended extensions. Water.css-provided tokens are passed through; **do not redefine them**.

```css
:root {
  /* ---- Brand ---- */
  --color-accent: #0096bf;
  --color-accent-hover: #007a9d;
  --color-accent-contrast: #eeeeee;

  /* Backwards-compat aliases (keep existing names in water-extension.css) */
  --button-primary: var(--color-accent);
  --button-primary-hover: var(--color-accent-hover);
  --button-primary-text: var(--color-accent-contrast);

  /* ---- Semantic ---- */
  --color-error: #fc5050;
  --color-warning: #8a6d3b;
  --color-success: #3c763d;
  --color-info: #31708f;
  --color-error-bg: #f2dede;
  --color-warning-bg: #fcf8e3;
  --color-success-bg: #dff0d8;
  --color-info-bg: #d9edf7;

  /* ---- Neutrals (extensions beyond Water.css) ---- */
  --color-muted: #999999;
  --color-surface-hover: #cccccc;
  --color-surface-active: #dddddd;

  /* ---- Overlays / shadows ---- */
  --overlay-scrim: rgba(0, 0, 0, 0.3);
  --overlay-hover: rgba(0, 0, 0, 0.1);
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.08);
  --shadow-md: 0 0 10px rgba(0, 0, 0, 0.3);
  --shadow-lg: 0 4px 20px rgba(0, 0, 0, 0.15);

  /* ---- Typography ---- */
  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;

  /* ---- Spacing ---- */
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 0.75rem;
  --space-4: 1rem;
  --space-5: 1.5rem;
  --space-6: 2rem;
  --space-8: 3rem;

  /* ---- Radius ---- */
  --radius-sm: 4px;
  --radius-md: 6px;
  --radius-lg: 8px;
  --radius-pill: 1rem;
  --radius-full: 50%;

  /* ---- Container widths ---- */
  --modal-max-width: 600px;
  --toast-max-width: 400px;
  --auth-max-width: 400px;
  --menu-min-width: 200px;
}
```

Inherited from Water.css (do not redefine): `--background`, `--background-alt`, `--text-main`, `--text-muted`, `--border`, `--focus`, `--selection`, `--form-text`, `--button-base`, `--button-hover`.

