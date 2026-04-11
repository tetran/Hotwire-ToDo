# Comment Card

Comment row inside a task detail modal.

`.comment-card` (`tasks.css`): flex row with header (avatar + username + date) and action icons that appear on hover (`.comment-card:hover .comment-card__actions { visibility: visible }`).

**Recommended**: replace visibility toggling with `opacity` + `transition` for a smoother reveal; ensure actions are reachable via keyboard (currently hidden without a focus-within rule — **accessibility issue**).

