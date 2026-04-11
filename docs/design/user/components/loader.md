# Loader

Fullscreen loading overlay.

Source: `loader.css`. Fullscreen overlay: `rgba(0,0,0,0.5)` backdrop, three concentric rotating circles with decorative colors (`#3498db`, `#e74c3c`, `#f9c922`). Triggered via `#loader-wrapper` visibility toggle.

**Note**: the loader colors are independent of the design palette (legacy decorative choice). **Target**: either refactor to a single cyan spinner using `var(--color-accent)` or explicitly document the current multi-color spinner as an intentional "working" visual.

