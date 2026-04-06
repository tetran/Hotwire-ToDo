# Hobo User Design System

This document describes the visual language of the user-facing (non-admin) Hobo application: the project dashboard, task lists, task detail modals, comments, search, notifications, and authentication screens.

It is **improvement-based**: the "Current" subsections document the shipped CSS; the **Recommended** and **Target** subsections propose a consolidated token system and component conventions for the Rails / Hotwire / plain CSS stack to migrate toward. The intent is to preserve the established cyan-accented light aesthetic built on Water.css while tightening consistency and reducing hardcoded literals.

---

## 1. Overview

The user UI is a server-rendered Rails + Hotwire (Turbo Streams, Turbo Frames, Stimulus) application styled with **Water.css v2 (light)** loaded from CDN and layered custom stylesheets under `app/assets/stylesheets/`. It is optimized for fast, single-purpose task workflows: see a project, scan tasks, open a task modal, comment, assign, complete.

### Design Principles

- **Light and content-first** -- The surface is white on Water.css neutral tones; chrome is minimal so task text dominates. No dark mode is currently defined.
- **Horizontal navigation, no sidebar** -- A single top header contains the project selector (left) and the search, project members, and user menu (right). This is a fundamental contrast with the admin SPA's dark sidebar layout.
- **Cyan accent, semantic everywhere else** -- `#0096bf` is the single brand accent, used exclusively on primary action buttons. Status communication uses semantic colors (error / success / warning / info) only.
- **Native platform controls** -- Interactive surfaces are built on HTML primitives (`<dialog>`, `<details>`, system font stack, Material Symbols Outlined icons) rather than a custom component framework. New work should continue to lean on native elements.
- **BEM-ish class naming** -- Most components use `block__element--modifier` (`task-card__complete-check`, `menu-button--assignee`). New components should follow this convention.
- **Turbo-first interactivity** -- Modals, task updates, comment threads, and assignee changes are driven by Turbo Streams / Frames; CSS should not assume full page reloads.

---

## 2. Color Palette

### 2.1 Brand and Structural Colors

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

### 2.2 Semantic Colors

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

### 2.3 Text Color Hierarchy

| Level            | Current value           | Usage                                           |
|------------------|-------------------------|--------------------------------------------------|
| Primary          | `var(--text-main)`      | Task names, body text                           |
| Form / link text | `var(--form-text)`      | Interactive text, icons in action bars          |
| Muted            | `#999` (hardcoded)      | Descriptions, due dates, timestamps, breadcrumbs |
| Placeholder      | `var(--text-muted)`     | Search placeholders, result counts              |
| Error            | `#fc5050`               | Overdue, form errors, destructive actions       |

**Target**: eliminate every `color: #999` literal (currently used in 7+ places across `tasks.css` and `search.css`) by replacing with `var(--color-muted)`.

---

## 3. Typography

### 3.1 Font Stack

The application uses **the system font stack only** — no custom web fonts are loaded. This is a deliberate choice aligned with the lightweight, Water.css-based aesthetic: zero font payload, native rendering on every platform, and no FOUT.

| Family  | Source      | Usage                                   |
|---------|-------------|------------------------------------------|
| System  | Water.css default (`-apple-system, BlinkMacSystemFont, ...`) | All text |
| Material Symbols Outlined | Google Fonts CDN | Icons only |

This is intentionally different from the admin SPA (Syne + DM Mono). **Do not introduce custom fonts** to the user UI without explicit product direction.

### 3.2 Current Size Scale (observed in CSS)

| Role                  | Size          | Locations                                        |
|-----------------------|---------------|---------------------------------------------------|
| Body / base           | Water.css default (~16px) | Default text                           |
| Notification content  | `16px`        | `.notification__contents`                        |
| Show task description | `0.9rem`      | `.show-task__description`                        |
| Comment user          | `0.9rem`      | `.comment-card__header__user`                    |
| Form error            | `0.9rem`      | `.form__error li`, `.simple-error`               |
| Search input          | `0.875rem`    | `.search-form__input`                            |
| Search result body    | `0.875rem`    | `.search-results__count`, filter toggle          |
| Task description/meta | `0.8rem`      | `.task-card__description`, `__due-date`          |
| Comment date          | `0.8rem`      | `.comment-card__header__date`                    |
| Search result meta    | `0.8125rem`   | `.search-result__description`, `__project`       |
| Search result parent  | `0.75rem`     | `.search-result__parent`                         |
| User initial sign     | `1rem`        | `.user-initial-sign`                             |

### 3.3 Recommended Type Scale

Consolidate the six ad-hoc sizes (`0.75 / 0.8 / 0.8125 / 0.875 / 0.9 / 1 rem`) into a four-step rem-based scale:

| Token             | Value       | px @16base | Usage                                            |
|-------------------|-------------|-----------|---------------------------------------------------|
| `--text-xs`       | `0.75rem`   | 12px      | Secondary meta (parent crumbs, tiny badges)       |
| `--text-sm`       | `0.875rem`  | 14px      | Task meta, descriptions, search results, timestamps |
| `--text-base`     | `1rem`      | 16px      | Body copy, form inputs, task names                |
| `--text-lg`       | `1.125rem`  | 18px      | Modal titles, section headings (currently h2/h3) |

**Font weights**: use `400` (default), `500` (search result names), and `700` (`font-weight: bold` for comment usernames, modal titles, current project). Avoid introducing additional weights.

**Line heights**: rely on Water.css defaults except for icon-aligned rows (`line-height: 1` on close buttons, `1.5` on menu items).

---

## 4. Spacing and Layout

### 4.1 Current Spacing Usage

The current CSS mixes px and rem values inconsistently. Common literals observed:

- **Rem-based** (the majority): `0.25rem`, `0.5rem`, `0.75rem`, `1rem`, `1.5rem`, `2rem`, `3rem`
- **Pixel-based** (small fixed dimensions): `2px`, `4px`, `6px`, `8px`, `10px`, `12px`, `15px`, `25px`
- **Ad-hoc**: `5vh`, `75vh`, `80vw`, `90vw`, `2.5rem` (search collapse), `300px` (search expand)

### 4.2 Recommended Spacing Scale

Adopt a single rem-based 4px step scale and apply it consistently. Keep `px` only for borders and 1-2px adjustments:

| Token         | Value     | px | Usage                                         |
|---------------|-----------|----|------------------------------------------------|
| `--space-0`   | `0`       | 0  | Reset                                          |
| `--space-1`   | `0.25rem` | 4  | Icon gaps, badge padding                       |
| `--space-2`   | `0.5rem`  | 8  | Default element gap, menu item padding         |
| `--space-3`   | `0.75rem` | 12 | Card spacing, modal padding                    |
| `--space-4`   | `1rem`    | 16 | Form item margin, comment spacing              |
| `--space-5`   | `1.5rem`  | 24 | Section gaps                                   |
| `--space-6`   | `2rem`    | 32 | Large section separation                       |
| `--space-8`   | `3rem`    | 48 | Modal description trailing space               |

**Target**: migrate existing values (e.g. `padding: 10px 0` on `.task-card` → `padding: var(--space-2) 0`, `margin-top: 0.5rem` → `var(--space-2)`).

### 4.3 Content Width Constraints

| Context            | Width                        | Source              |
|--------------------|------------------------------|----------------------|
| Main content       | Water.css default (~800px max) | external          |
| Modal              | `80vw`, `max-width: 600px`   | `modal.css`          |
| Search modal       | `90vw`, `max-width: 600px`   | `search.css`         |
| Auth form          | `max-width: 400px`           | `auth.css`           |
| Menu navigation    | `min-width: 200px`, `max-width: 67%` | `header-menu.css` |
| Search expanded    | `300px`                      | `search.css`         |

**Recommended**: align modal and search-modal max widths (both use 600px already — good); document `--modal-max-width: 600px` as a token for reuse.

---

## 5. Component Specifications

Each component lists the **current class names** (for locating code) and a **Recommended** structure for new instances.

### 5.1 Button

**Current (`water-extension.css`)**: Water.css styles all `<button>` and `input[type="submit"]` elements by default. Custom overrides:

```css
.btn                       /* base: neutral surface, 6px radius, 8px padding */
.btn:hover                 /* background: var(--button-hover) */
.btn:active                /* transform: translateY(2px) */
button.primary             /* background: var(--button-primary); color: var(--button-primary-text) */
button.primary:hover       /* background: var(--button-primary-hover) */
```

**Recommended variant matrix**:

| Variant    | Classes                    | Visual                                               |
|------------|----------------------------|-------------------------------------------------------|
| Primary    | `.btn.primary` or `button.primary` | Cyan `#0096bf` fill, light text `#eee`         |
| Secondary  | `.btn` (no modifier)       | Water.css `--button-base` fill, `--form-text` text    |
| Danger     | `.btn.danger` (**new**)    | `var(--color-error)` text, border, or fill           |
| Icon       | `.btn.btn--icon` (**new**) | Transparent, `2px` padding, hover `--overlay-hover`  |
| Link       | Inline `<a>`               | Inherits text color; underline on hover              |

**Target**: introduce `.btn.danger` and `.btn.btn--icon` to replace the ad-hoc icon buttons in `.horizontal-actions` and assignee-unassign rows.

### 5.2 Task Card

Structure (see `tasks.css` and `app/views/tasks/_task.html.erb`):

```
.task-card
  .task-card__content
    button.task-card__complete-check  (16x16 circular checkbox)
    .task-card__name (link to task detail)
    .task-card__description           (0.8rem, #999)
    .task-card__due-date              (flex with icon)
  .horizontal-actions                  (icon action buttons)
```

Modifiers: `.task-card--complete` (strikethrough + grey check), `.overdue` (red due-date text), `.task-card--subtask` (compact padding).

When the card contains subtasks, it is wrapped in `.task-card-wrapper--has-subtasks` which owns the bottom border, and `.task-card__subtasks` holds the child list with `padding-left: 1.5rem`.

**Recommended**: extract the "muted meta row" pattern (icon + `0.8rem` text, color `#999`) into a shared `.meta-row` utility used by due-date, subtask-badge, and search-result parent labels.

### 5.3 Project Header

Structure (see `projects.css` and `app/views/projects/_header.html.erb`):

```
.project-header                     (flex, space-between, relative)
  .project-selector                 (left — dropdown trigger for switching projects)
    h2.project-name                 (inline)
  .project-header__right            (flex, gap: 0)
    .search-container
    .project-members                (menu button for member management)
    .menu-container--header         (main user menu)
```

The selector dropdown uses `.menu-navigation` positioned `left: 0`; the members/user menu dropdowns use `right: 0`.

### 5.4 Form Input

**Current**: `<input>` and `<textarea>` elements inherit Water.css styles. Custom additions:

- `.full-width-input` / `.form-item-inline__input` — `box-sizing: border-box; width: 100%`
- `.form-item-inline` — single-row flex layout pairing input + button
- `.task-form__description` — boxed trix-editor container with `6px` radius, `1px` border, focus ring `2px var(--focus)`

**Recommended**: standardize focus styling so all inputs use the same `box-shadow: 0 0 0 2px var(--focus)` ring Water.css applies by default; never remove focus rings with `box-shadow: none` except on non-text controls (icon buttons, checkboxes).

### 5.5 Form Errors

**Current (`form.css` + `common.css`)**:

```css
.form__error           /* ul, no list padding, margin-top 0.5rem */
.form__error li        /* color #fc5050, list-style none, 0.9rem, padding 0 0 0.5rem 0.5rem */
.simple-error          /* same color, 0.9rem, padding 0 0 0.5rem 0.5rem */
```

**Recommended**: consolidate `.form__error li` and `.simple-error` into a single `.field-error` class with a shared token (`color: var(--color-error); font-size: var(--text-sm)`).

### 5.6 Modal / Dialog

Built on native `<dialog>` element (`modal.css`):

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

### 5.7 Dropdown Menu

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

### 5.8 Notification / Toast

Structure (`common.css`, `_notification.html.erb`):

```
.notification                       (fixed top:0, z-index:9999 when animating)
  .notification__contents           (padding 0.75em, margin 1em, max-width 400px, 5px radius, shadow)
    .notification__contents--{status}
```

Animations: `fadeInOut 1.5s` (default), `fadeIn 0.2s` / `fadeOut 0.2s` (manual control), with `translateY(-100%)` entry.

**Recommended**: expose a `.notification--bottom` modifier (already `.notification.bottom`) in the Turbo Stream contract, and document the 400px max width / 5px radius as `--toast-max-width` / `--radius-sm` tokens.

### 5.9 Avatar

Two styles coexist:

- **Initial sign** (`.user-initial-sign`, `common.css`): 1.5rem circle, border, centered bold letter. Used in headers and inline rosters.
- **Image avatar** (`.user-avatar`): `clip-path: circle(50%)`. Sized per context: 1.5rem in menu button, 25px in member lists, larger in profile.

**Recommended**: converge on a single `.avatar` class with `--size-sm` (25px), `--size-md` (36px), `--size-lg` (44px) modifiers, and treat the initial sign as a fallback rendered inside the same container.

### 5.10 Subtask Badge

`.task-card__subtask-badge` (`tasks.css`): flex, icon + count, 0.8rem, `#999`, `padding-left: 1.5rem` (indents under the parent task text). Expand/collapse rotates the chevron via `transform: rotate(…)` with `transition: transform 0.2s`.

**Recommended**: document the 1.5rem left-indent as `--subtask-indent` to share with `.task-card__subtasks`.

### 5.11 Search Box

Collapsible search affordance in the header (`search.css`):

- Collapsed: 2.5rem icon-only button
- Expanded: 300px flex row with icon + input
- Transition: `width 0.3s ease`, input fades in with `opacity 0.2s ease 0.1s`

Search modal opens as a fixed-position dialog (not a native `<dialog>`), 90vw / 600px max, `8px` radius, shadow `0 4px 20px rgba(0,0,0,0.15)`.

**Recommended**: align the search modal with `<dialog>` semantics so keyboard/ESC handling matches other modals; reuse `.modal-base` once styles are tokenized.

### 5.12 Comment Card

`.comment-card` (`tasks.css`): flex row with header (avatar + username + date) and action icons that appear on hover (`.comment-card:hover .comment-card__actions { visibility: visible }`).

**Recommended**: replace visibility toggling with `opacity` + `transition` for a smoother reveal; ensure actions are reachable via keyboard (currently hidden without a focus-within rule — **accessibility issue**).

### 5.13 Assignee List

`.assignee-list` + `.assignee-list__member` (`tasks.css`): members rendered as rows inside the dropdown `.menu-list`, each with avatar, name, and a button. Unassign row uses error color:

```css
.assignee-list__unassign .assignee-list__member-info button { color: var(--color-error); }
```

The "assigned to me" menu button highlights with `#f2dede` (see Color Palette section 2.2 — **recommend replacing with a dedicated highlight token**).

### 5.14 Loader

Fullscreen overlay (`loader.css`): `rgba(0,0,0,0.5)` backdrop, three concentric rotating circles with decorative colors (`#3498db`, `#e74c3c`, `#f9c922`). Triggered via `#loader-wrapper` visibility toggle.

**Note**: the loader colors are independent of the design palette (legacy decorative choice). **Target**: either refactor to a single cyan spinner using `var(--color-accent)` or explicitly document the current multi-color spinner as an intentional "working" visual.

### 5.15 Collapsible Section

Native `<details>/<summary>` used for opt-in settings that stay inline with a form. Rendered as a **card**:

```css
.collapsible-section {
  border: 1px solid var(--border);
  border-radius: var(--radius-md);
  padding: var(--space-2) var(--space-3);
}
.collapsible-section[open] { padding-bottom: var(--space-3); }
.collapsible-section > summary {
  font-size: var(--text-sm);
  color: var(--form-text);
  cursor: pointer;
}
.collapsible-section[open] > summary { font-weight: 500; }
```

- `summary` aligns with small-icon conventions (§10): icon at `var(--color-muted)`, **not** `var(--color-accent)` — the accent color is reserved for state indicators (badges, checked chips), not for static decoration.
- Body content appears with `margin-top: var(--space-3)` after open.

### 5.16 Fieldset Group

Logical groups of related form fields inside a form use `<fieldset>` + `<legend>` **without a border**. The legend acts as a small section heading:

```css
.fieldset-group { border: 0; padding: 0; margin: 0; }
.fieldset-group > legend {
  font-size: var(--text-xs);
  color: var(--color-muted);
  padding: 0;
  margin-bottom: var(--space-1);
}
```

Avoid the native browser `<fieldset>` border — it creates a **box-in-box** look when placed inside a card (§5.15). Use nested fieldsets only for semantic grouping; rely on spacing (`gap: var(--space-2)`) and the small legend caption for visual separation.

### 5.17 Toggle Chip

Pill-shaped multi-select control for compact sets (days of week, tags, enum options). Each chip is a `<label>` wrapping a `.visually-hidden` checkbox (§ common.css), so the label itself becomes the interactive surface.

```css
.chip {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: var(--space-1) var(--space-2);
  border: 1px solid var(--border);
  border-radius: var(--radius-pill);
  font-size: var(--text-xs);
  color: var(--form-text);
  background: transparent;
  cursor: pointer;
  user-select: none;
}
.chip:has(input:checked) {
  background: color-mix(in srgb, var(--color-accent) 12%, transparent);
  color: var(--color-accent);
  border-color: var(--color-accent);
}
.chip:focus-within {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}
```

- **Accessibility**: `:focus-within` outline is **required** — without it, keyboard users lose focus tracking once the native checkbox is hidden.
- **Contrast**: the selected state uses a **tinted background** (12% accent over page) with accent-colored text. This meets WCAG AA (~4.5:1 for `#0096bf` over tinted background on white) while a solid `#fff` on `#0096bf` fill would fall to ~3.4:1.
- **Layout**: for fixed-arity sets (7 weekdays, 12 months) use a CSS grid (`grid-template-columns: repeat(N, 1fr); gap: var(--space-1)`) for rhythm. For variable sets, use flex-wrap.

**Used by**: `.task-form__recurrence-weekday` (see `tasks.css:397-`).

### 5.18 Conditional Sub-input

A radio or checkbox that reveals/activates an inline sub-input (e.g. "after [N] times", "until [date]"). The row is a single flex line so the radio and its dependent controls read as one unit:

```css
.conditional-option {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex-wrap: wrap;
  color: var(--color-muted);
}
.conditional-option:has(input:checked) {
  color: var(--form-text);
  font-weight: 500;
}
```

- **Do not** dim non-selected rows with `opacity` — it visually collides with the `:disabled` convention. Use `var(--color-muted)` instead.
- The sub-input stays enabled even when its row is not selected; tabbing into the sub-input should implicitly activate its radio in a Stimulus controller (see `recurrence_form_controller.js` for the reference pattern).

**Used by**: `.task-form__recurrence-end-option` (see `tasks.css:397-`).

### 5.19 Inline Numeric Unit Input

A number input paired with a unit select (and optional suffix) on one line — e.g. `[ 2 ] [Weeks] every`. Reserves fewer vertical lines than a labeled 2-row layout:

```css
.numeric-unit {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex-wrap: wrap;
  font-size: var(--text-sm);
}
.numeric-unit input[type="number"] { width: 4rem; }
```

Use when the semantic reading is a natural-language phrase ("every 2 weeks", "2 週間ごと"). Keep the number field first (it carries primary focus) and position any fixed suffix text (`ごと`, `every`) at the end.

---

## 6. Layout System

### 6.1 Overall Page Structure

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

### 6.2 Modal Overlay Pattern

- Native `<dialog>` opened via `showModal()`
- `::backdrop` scrim `rgba(0,0,0,0.3)`
- Content rendered server-side into the `modal` Turbo Frame defined in `application.html.erb`
- Modals stack vertically: header (with close button), body (scrollable when content exceeds 75vh), optional actions area

### 6.3 Responsive Considerations

**Current state**: the application is minimally responsive. It relies on:
- Water.css's built-in fluid container
- `vw`/`vh` units on modals (`80vw`, `90vw`, `5vh` top margin, `75vh` body height)
- No explicit breakpoints, no media queries

**Recommended** (target): introduce a single mobile breakpoint at `640px`:
- Header dropdowns: expand search `width: 300px` should fall back to `width: 100%` below 640px
- Modal: `width: 95vw` below 640px, padding reduced to `var(--space-2)`
- Project selector dropdown `max-width: 67%` is already reasonable

Do not add a mobile nav drawer — the horizontal header is intentional.

---

## 7. Navigation Pattern

### 7.1 Project Selector (Left)

- Trigger: the `h2.project-name` element inside `.project-selector` (the visible project title doubles as the dropdown trigger)
- Dropdown: `.menu-navigation` aligned `left: 0`, listing projects with per-row actions (edit, delete) in `.horizontal-actions`
- Current project: `.current-project` modifier applies `font-weight: bold`
- Footer action: `.project-selector__add-button` renders a "+ New project" CTA

### 7.2 Main Menu (Right)

- User menu trigger: avatar or icon button (`.menu-button`)
- Contains: profile link, settings, logout
- Dropdown: `.menu-navigation` aligned `right: 0`

### 7.3 Project Members Menu (Right, between search and user menu)

- Trigger: `.project-members .menu-button`
- Content: member list with per-row assign/remove actions and an add-member form

### 7.4 Active / Hover States

| State         | Styling                                                |
|---------------|---------------------------------------------------------|
| Menu item hover | `background: #ccc` (`target`: `var(--color-surface-hover)`) |
| Current project | `font-weight: bold`                                  |
| Icon hover    | `background: rgba(0,0,0,0.1)` (`target`: `var(--overlay-hover)`) |
| Icon active   | `transform: translateY(2px)`                            |
| Scale-on-hover icon actions | `scale: 1.2` (used in project-selector row actions) |

---

## 8. Shadow System

### 8.1 Current Usage

| Location                         | Value                           |
|----------------------------------|----------------------------------|
| Dropdown menu (`.menu-navigation`) | `0 0 10px rgba(0, 0, 0, 0.3)` |
| Notification                     | `0 0 10px rgba(0, 0, 0, 0.3)`   |
| Search modal                     | `0 4px 20px rgba(0, 0, 0, 0.15)`|

### 8.2 Recommended Tiered Scale

| Token              | Value                          | Usage                          |
|--------------------|--------------------------------|--------------------------------|
| `--shadow-sm`      | `0 1px 2px rgba(0,0,0,0.08)`   | Subtle card lift (future use)  |
| `--shadow-md`      | `0 0 10px rgba(0,0,0,0.3)`     | Dropdowns, toasts (current)    |
| `--shadow-lg`      | `0 4px 20px rgba(0,0,0,0.15)`  | Modals (current)               |

Keep shadows neutral grey; do not introduce accent-tinted shadows (the admin SPA's `shadow-indigo-500/20` pattern is not part of this design language).

---

## 9. Border and Radius

### 9.1 Border Usage

| Width / Style     | Usage                                       |
|-------------------|----------------------------------------------|
| `1px solid var(--border)` | Cards, form fields, modal header, dividers, tabs |
| `1px solid var(--selection)` | Task complete checkbox              |
| No border         | Menu buttons, icon buttons, primary CTAs     |

### 9.2 Border Radius Scale

Current values observed: `4px`, `5px`, `6px`, `8px`, `1rem`, `50%`.

**Recommended consolidated scale**:

| Token             | Value     | Usage                                   |
|-------------------|-----------|------------------------------------------|
| `--radius-sm`     | `4px`     | Dropdowns, small hover chips, menu items |
| `--radius-md`     | `6px`     | Buttons, trix-editor description box, action icons |
| `--radius-lg`     | `8px`     | Modals, task-form card, search-modal    |
| `--radius-pill`   | `1rem`    | Inline text-input pill (add-comment)     |
| `--radius-full`   | `50%`     | Avatars, checkboxes, user-initial-sign   |

**Target**: replace the orphan `5px` on `.notification__contents` and `.auth-form` with `--radius-md` (6px) for consistency.

---

## 10. Icon Conventions

All icons are rendered via Material Symbols Outlined (loaded from Google Fonts in `application.html.erb`).

### 10.1 Sizing Scale (observed)

| Size       | Usage                                                |
|------------|-------------------------------------------------------|
| `0.9rem`   | Search result parent breadcrumb                       |
| `1rem`     | Task due-date, subtask badge, show-task parent link   |
| `1.2rem`   | Label-with-icon, project-selector row actions         |
| `1.25rem`  | Search input icon, search filter toggle               |
| `1.4rem`   | Assignee-list member sign, project add button         |
| `1.5rem`   | `.menu-button` trigger icons                          |
| `24px`     | Unassign action button                                |

### 10.2 Vertical Alignment

Icons are inline with adjacent text and require per-context alignment tweaks:

| Context               | Alignment                          |
|-----------------------|------------------------------------|
| `.label-with-icon`    | `vertical-align: -4px`              |
| `.menu-button`        | `vertical-align: -0.25rem`          |
| `.assignee-list__member-sign` | `vertical-align: -0.5rem`   |
| `.project-selector__add-button` | `vertical-align: -6px`    |

**Recommended**: adopt the pattern `display: inline-flex; align-items: center; gap: var(--space-1)` on icon+text containers (already used by `.task-card__due-date`, `.search-result__parent`) and retire per-icon `vertical-align` hacks.

### 10.3 Icon Color

Icons inherit `color` from the parent. Utility: `.horizontal-actions .material-symbols-outlined { color: var(--text-main) }`. Use `var(--color-error)` only on destructive actions (unassign).

---

## 11. CSS Variables Reference

The target token surface, consolidating what exists in `common.css` + `water-extension.css` and adding the recommended extensions. Water.css-provided tokens are passed through; **do not redefine them**.

```css
:root {
  /* ---- Brand ---- */
  --color-accent: #0096bf;
  --color-accent-hover: #007a9d;
  --color-accent-contrast: #eeeeee;

  /* Backwards-compat aliases (keep existing names in water-extension.css) */
  --button-primary: var(--color-accent);
  --button-primary-hover: var(--color-accent-hover);
  --button-primary-text: var(--color-accent-contrast);

  /* ---- Semantic ---- */
  --color-error: #fc5050;
  --color-warning: #8a6d3b;
  --color-success: #3c763d;
  --color-info: #31708f;
  --color-error-bg: #f2dede;
  --color-warning-bg: #fcf8e3;
  --color-success-bg: #dff0d8;
  --color-info-bg: #d9edf7;

  /* ---- Neutrals (extensions beyond Water.css) ---- */
  --color-muted: #999999;
  --color-surface-hover: #cccccc;
  --color-surface-active: #dddddd;

  /* ---- Overlays / shadows ---- */
  --overlay-scrim: rgba(0, 0, 0, 0.3);
  --overlay-hover: rgba(0, 0, 0, 0.1);
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.08);
  --shadow-md: 0 0 10px rgba(0, 0, 0, 0.3);
  --shadow-lg: 0 4px 20px rgba(0, 0, 0, 0.15);

  /* ---- Typography ---- */
  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;

  /* ---- Spacing ---- */
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 0.75rem;
  --space-4: 1rem;
  --space-5: 1.5rem;
  --space-6: 2rem;
  --space-8: 3rem;

  /* ---- Radius ---- */
  --radius-sm: 4px;
  --radius-md: 6px;
  --radius-lg: 8px;
  --radius-pill: 1rem;
  --radius-full: 50%;

  /* ---- Container widths ---- */
  --modal-max-width: 600px;
  --toast-max-width: 400px;
  --auth-max-width: 400px;
  --menu-min-width: 200px;
}
```

Inherited from Water.css (do not redefine): `--background`, `--background-alt`, `--text-main`, `--text-muted`, `--border`, `--focus`, `--selection`, `--form-text`, `--button-base`, `--button-hover`.

---

## 12. Migration Notes and Implementation Checklist

The token set above is **additive**. Existing CSS will continue to work; migrate incrementally, one component file at a time.

### 12.1 Priority Migrations

1. **Eliminate `#999` literals** — 7+ occurrences across `tasks.css` and `search.css`. Replace with `var(--color-muted)`.
2. **Eliminate `#ccc` / `#ddd` literals** — hover backgrounds in `header-menu.css` and `projects.css` should use `var(--color-surface-hover)`; `.tab.active` should use `var(--color-surface-active)`.
3. **Fix accessibility regressions** — remove `outline: none; box-shadow: none` on `.menu-button:focus`, `.menu-list li button:focus`, `.task-card__complete-check:focus`; rely on Water.css focus ring or define one on `--focus`.
4. **Reveal comment actions on focus-within** — add `.comment-card:focus-within .comment-card__actions { visibility: visible }` so keyboard users can reach actions.
5. **Introduce `--color-highlight-bg`** and replace the "assigned to me" `#f2dede` misuse with a cyan-family highlight.
6. **Consolidate form error styles** (`.form__error li` + `.simple-error` → `.field-error`).

### 12.2 Checklist for New Components

When building a new user-facing component:

1. Reuse Water.css element styles where possible; add custom CSS only for structural layout or brand distinction.
2. Use BEM-style class names: `block__element--modifier`.
3. Reference tokens, never hex literals: `var(--color-accent)` not `#0096bf`.
4. Reference spacing tokens, never raw rem/px for gap/padding/margin: `var(--space-3)` not `0.75rem`.
5. Use Material Symbols Outlined for icons, inline-flex alignment with `gap: var(--space-1)`.
6. Ensure keyboard navigability: do not suppress focus outlines on interactive controls.
7. For overlays, use native `<dialog>` (reuse `.modal-base`).
8. For Turbo Stream targets, assume the component can be replaced at any time — no JS state that outlives the DOM node.
9. Semantic colors: error red (`--color-error`) is reserved for errors and destructive actions only.
10. No custom fonts, no dark theme — stay within the light + system-font aesthetic.

### 12.3 What Not to Do

- Do not introduce a CSS framework (Tailwind, Bootstrap). The Rails/ERB stack stays on plain CSS + Water.css.
- Do not add a sidebar or alter the horizontal header layout.
- Do not change the cyan brand accent `#0096bf` or introduce a second accent color.
- Do not load additional web fonts for body text.
- Do not replicate admin-SPA patterns (Syne/DM Mono typography, dark surfaces, indigo accent) — the two applications are deliberately distinct.

