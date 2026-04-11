# Colors

Brand, semantic, and text-hierarchy color tokens for the user UI.

## Brand and Structural Colors

The structural neutrals (`--background`, `--border`, `--form-text`, `--button-base`, `--button-hover`, `--focus`, `--selection`, `--text-main`, `--text-muted`, `--background-alt`) are inherited from **Water.css light**. Custom CSS overrides add only the brand accent and semantic tokens.

| Token (current)             | Value     | Source            | Usage                                   |
|-----------------------------|-----------|-------------------|------------------------------------------|
| `--button-primary`          | `#0096bf` | `water-extension` | Primary button background (cyan accent) |
| `--button-primary-hover`    | `#007a9d` | `water-extension` | Primary button hover                    |
| `--button-primary-text`     | `#eee`    | `water-extension` | Primary button text color               |
| `--background`              | Water.css | external          | Page background, inputs                 |
| `--background-alt`          | Water.css | external          | Dropdown menu surface, hover rows       |
| `--border`                  | Water.css | external          | Dividers, card edges, inputs            |
| `--form-text`               | Water.css | external          | Primary text, link-like controls        |
| `--button-base`             | Water.css | external          | Secondary button surface                |
| `--button-hover`            | Water.css | external          | Secondary button hover                  |
| `--focus`                   | Water.css | external          | Focus ring color (e.g. trix-editor)     |
| `--selection`               | Water.css | external          | Checkbox outline, selection highlight   |
| `--text-main`               | Water.css | external          | Default body text                       |
| `--text-muted`              | Water.css | external          | Placeholders, meta, search hints        |

**Recommended token additions** (to be defined in `common.css`, extending the existing `:root` block — do not rename existing Water.css tokens):

```css
:root {
  /* Brand (already defined in water-extension.css — move to common.css) */
  --color-accent: #0096bf;
  --color-accent-hover: #007a9d;
  --color-accent-contrast: #eeeeee;

  /* Neutral extensions (replace hardcoded #999, #ccc, #ddd) */
  --color-muted: #999999;
  --color-surface-hover: #cccccc;
  --color-surface-active: #dddddd;

  /* Overlays (replace rgba literals) */
  --overlay-scrim: rgba(0, 0, 0, 0.3);
  --overlay-hover: rgba(0, 0, 0, 0.1);
  --shadow-dropdown: 0 0 10px rgba(0, 0, 0, 0.3);
  --shadow-modal: 0 4px 20px rgba(0, 0, 0, 0.15);
}
```

## Semantic Colors

Currently defined in `common.css`:

| Token              | Value     | Usage                                 |
|--------------------|-----------|----------------------------------------|
| `--color-error`    | `#fc5050` | Overdue tasks, error messages, destructive actions |
| `--color-warning`  | `#8a6d3b` | Warning text                           |
| `--color-success`  | `#3c763d` | Success text                           |
| `--color-info`     | `#31708f` | Info text                              |

**Notification background fills** (currently hardcoded in `common.css`):

| Variant   | Background | Text                 | Class                                   |
|-----------|------------|----------------------|------------------------------------------|
| Success   | `#dff0d8`  | `var(--color-success)` | `.notification__contents--success`     |
| Error     | `#f2dede`  | `var(--color-error)`   | `.notification__contents--error`       |
| Warning   | `#fcf8e3`  | `var(--color-warning)` | `.notification__contents--warning`     |
| Info      | `#d9edf7`  | `var(--color-info)`    | `.notification__contents--info`        |

**Recommended**: promote the notification backgrounds to paired tokens so other components (inline banners, status pills) can reuse them:

```css
:root {
  --color-success-bg: #dff0d8;
  --color-error-bg: #f2dede;
  --color-warning-bg: #fcf8e3;
  --color-info-bg: #d9edf7;
}
```

Note: the "assigned-to-me" indicator in `tasks.css` currently reuses `#f2dede` (error background) as a highlight fill — this is a semantic mismatch. **Target**: introduce a dedicated `--color-highlight-bg` (e.g. a pale cyan derived from the accent) for affordance highlights so error color stays reserved for errors.

## Text Color Hierarchy

| Level            | Current value           | Usage                                           |
|------------------|-------------------------|--------------------------------------------------|
| Primary          | `var(--text-main)`      | Task names, body text                           |
| Form / link text | `var(--form-text)`      | Interactive text, icons in action bars          |
| Muted            | `#999` (hardcoded)      | Descriptions, due dates, timestamps, breadcrumbs |
| Placeholder      | `var(--text-muted)`     | Search placeholders, result counts              |
| Error            | `#fc5050`               | Overdue, form errors, destructive actions       |

**Target**: eliminate every `color: #999` literal (currently used in 7+ places across `tasks.css` and `search.css`) by replacing with `var(--color-muted)`.

