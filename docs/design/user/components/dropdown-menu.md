# Dropdown Menu

Header-anchored dropdown menus (project selector, members, user menu).

Structure (`header-menu.css`):

```
.menu-container--header
  button.menu-button                (transparent, 10px padding, icon 1.5rem)
  .menu-navigation                  (absolute, top:100%, right:0, 4px radius)
    .menu-navigation__header        (title row, border-bottom)
    ul.menu-list                    (no list-style, 0.25rem padding)
      li                            (hover #ccc, 4px radius)
        button | a                  (full-width, left-aligned, 6px padding)
```

**Recommended**: replace hardcoded `#ccc` hover on menu items with `var(--color-surface-hover)` (or, better, a new `--menu-item-hover` token); ensure focus-visible outlines remain (currently suppressed via `outline: none; box-shadow: none` on `.menu-button:focus` and `.menu-list li button:focus` — this is an **accessibility regression to fix**).

