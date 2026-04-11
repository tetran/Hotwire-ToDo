# CSS Variables Reference

Defined in `app/javascript/admin/styles/admin.css` via TailwindCSS v4 `@theme`:

```css
@theme {
  --font-syne: 'Syne', sans-serif;
  --font-dm-mono: 'DM Mono', monospace;
  --color-sidebar: #0f1117;
  --color-sidebar-border: #1e2130;
  --color-accent: #6366f1;
  --color-surface: #f8f9fc;
}
```

These tokens can be referenced in Tailwind as `bg-sidebar`, `border-sidebar-border`, `bg-accent`, `bg-surface`, `font-syne`, `font-dm-mono`. Note: the current implementation mostly uses hardcoded values (e.g. `bg-[#0f1117]`). Prefer token references for new components.

