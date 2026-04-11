# Modal / Dialog

Built on the native `<dialog>` element.

Source: `modal.css`.

```
dialog.modal-base                   (80vw, max-width 600px, margin-top 5vh, padding 0.75rem)
  ::backdrop                        (rgba(0,0,0,0.3))
  .modal-header                     (flex, border-bottom, space-between)
    .modal-header__title            (h?, margin 0.5rem)
    .modal-header__close            (icon button, 6px radius)
  .modal-body                       (max-height 75vh, padding 1% 0.2rem)
  .modal-body.scrollable            (overflow-y: scroll)
```

**Recommended structural spec**:

| Property       | Value                         |
|----------------|-------------------------------|
| Width          | `min(80vw, 600px)`            |
| Border-radius  | `8px` (**target** — currently unset, inherits default) |
| Padding        | `var(--space-3)`              |
| Backdrop       | `var(--overlay-scrim)`        |
| Max body height | `75vh`                       |

