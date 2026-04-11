# Page Layout

Overall page structure, modal overlay pattern, and responsive considerations.

## Overall Page Structure

```
+--------------------------------------------------------+
| Header (horizontal)                                    |
|   [Project selector ▾]          [🔍] [👥] [👤]        |
+--------------------------------------------------------+
| Main content (Water.css centered max-width container)  |
|                                                         |
|   <project header inline with h2 project name>         |
|   .tasks-container                                     |
|     task cards...                                      |
|                                                         |
+--------------------------------------------------------+
| Notification overlay (fixed top, fade in/out)          |
| Modal overlay (<dialog>, 5vh top margin)               |
| Loader overlay (#loader-wrapper, fullscreen)           |
+--------------------------------------------------------+
```

No sidebar. All navigation happens through the top header and dropdown menus.

## Modal Overlay Pattern

- Native `<dialog>` opened via `showModal()`
- `::backdrop` scrim `rgba(0,0,0,0.3)`
- Content rendered server-side into the `modal` Turbo Frame defined in `application.html.erb`
- Modals stack vertically: header (with close button), body (scrollable when content exceeds 75vh), optional actions area

## Responsive Considerations

**Current state**: the application is minimally responsive. It relies on:
- Water.css's built-in fluid container
- `vw`/`vh` units on modals (`80vw`, `90vw`, `5vh` top margin, `75vh` body height)
- No explicit breakpoints, no media queries

**Recommended** (target): introduce a single mobile breakpoint at `640px`:
- Header dropdowns: expand search `width: 300px` should fall back to `width: 100%` below 640px
- Modal: `width: 95vw` below 640px, padding reduced to `var(--space-2)`
- Project selector dropdown `max-width: 67%` is already reasonable

Do not add a mobile nav drawer — the horizontal header is intentional.

