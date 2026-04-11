# Notification / Toast

Transient success/error/warning/info toast rendered at the top of the viewport.

Structure (`common.css`, `_notification.html.erb`):

```
.notification                       (fixed top:0, z-index:9999 when animating)
  .notification__contents           (padding 0.75em, margin 1em, max-width 400px, 5px radius, shadow)
    .notification__contents--{status}
```

Animations: `fadeInOut 1.5s` (default), `fadeIn 0.2s` / `fadeOut 0.2s` (manual control), with `translateY(-100%)` entry.

**Recommended**: expose a `.notification--bottom` modifier (already `.notification.bottom`) in the Turbo Stream contract, and document the 400px max width / 5px radius as `--toast-max-width` / `--radius-sm` tokens.

