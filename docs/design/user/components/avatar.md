# Avatar

User avatar — initial-sign and image variants.

Two styles coexist:

- **Initial sign** (`.user-initial-sign`, `common.css`): 1.5rem circle, border, centered bold letter. Used in headers and inline rosters.
- **Image avatar** (`.user-avatar`): `clip-path: circle(50%)`. Sized per context: 1.5rem in menu button, 25px in member lists, larger in profile.

**Recommended**: converge on a single `.avatar` class with `--size-sm` (25px), `--size-md` (36px), `--size-lg` (44px) modifiers, and treat the initial sign as a fallback rendered inside the same container.

