# Search Box

Collapsible header search and the full-screen search modal.

Source: `search.css`.

- Collapsed: 2.5rem icon-only button
- Expanded: 300px flex row with icon + input
- Transition: `width 0.3s ease`, input fades in with `opacity 0.2s ease 0.1s`

Search modal opens as a fixed-position dialog (not a native `<dialog>`), 90vw / 600px max, `8px` radius, shadow `0 4px 20px rgba(0,0,0,0.15)`.

**Recommended**: align the search modal with `<dialog>` semantics so keyboard/ESC handling matches other modals; reuse `.modal-base` once styles are tokenized.

