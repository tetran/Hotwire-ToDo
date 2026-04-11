# Hobo User Design System

The visual language of the user-facing (non-admin) Hobo application: the project dashboard, task lists, task detail modals, comments, search, notifications, and authentication screens.

It is **improvement-based**: the "Current" subsections document the shipped CSS; the **Recommended** and **Target** subsections propose a consolidated token system and component conventions for the Rails / Hotwire / plain CSS stack to migrate toward. The intent is to preserve the established cyan-accented light aesthetic built on Water.css while tightening consistency and reducing hardcoded literals.

## Overview

The user UI is a server-rendered Rails + Hotwire (Turbo Streams, Turbo Frames, Stimulus) application styled with **Water.css v2 (light)** loaded from CDN and layered custom stylesheets under `app/assets/stylesheets/`. It is optimized for fast, single-purpose task workflows: see a project, scan tasks, open a task modal, comment, assign, complete.

### Design Principles

- **Light and content-first** -- The surface is white on Water.css neutral tones; chrome is minimal so task text dominates. No dark mode is currently defined.
- **Horizontal navigation, no sidebar** -- A single top header contains the project selector (left) and the search, project members, and user menu (right). This is a fundamental contrast with the admin SPA's dark sidebar layout.
- **Cyan accent, semantic everywhere else** -- `#0096bf` is the single brand accent, used exclusively on primary action buttons. Status communication uses semantic colors (error / success / warning / info) only.
- **Native platform controls** -- Interactive surfaces are built on HTML primitives (`<dialog>`, `<details>`, system font stack, Material Symbols Outlined icons) rather than a custom component framework. New work should continue to lean on native elements.
- **BEM-ish class naming** -- Most components use `block__element--modifier` (`task-card__complete-check`, `menu-button--assignee`). New components should follow this convention.
- **Turbo-first interactivity** -- Modals, task updates, comment threads, and assignee changes are driven by Turbo Streams / Frames; CSS should not assume full page reloads.

## Index

### Foundations
- [Colors](foundations/colors.md)
- [Typography](foundations/typography.md)
- [Spacing & Layout](foundations/spacing.md)
- [Shadows](foundations/shadows.md)
- [Border & Radius](foundations/borders-radius.md)
- [Icons](foundations/icons.md)
- [CSS Variables Reference (Tokens)](foundations/tokens.md)

### Components
- [Button](components/button.md)
- [Task Card](components/task-card.md)
- [Project Header](components/project-header.md)
- [Form Input](components/form-input.md)
- [Form Errors](components/form-errors.md)
- [Modal / Dialog](components/modal.md)
- [Dropdown Menu](components/dropdown-menu.md)
- [Notification / Toast](components/notification.md)
- [Avatar](components/avatar.md)
- [Subtask Badge](components/subtask-badge.md)
- [Search Box](components/search-box.md)
- [Comment Card](components/comment-card.md)
- [Assignee List](components/assignee-list.md)
- [Loader](components/loader.md)
- [Collapsible Section](components/collapsible-section.md)
- [Fieldset Group](components/fieldset-group.md)
- [Toggle Chip](components/toggle-chip.md)
- [Conditional Sub-input](components/conditional-sub-input.md)
- [Inline Numeric Unit Input](components/inline-numeric-unit-input.md)

### Layouts
- [Page Layout](layouts/page-layout.md)
- [Navigation](layouts/navigation.md)

### Migration Notes
- [Migration Notes & Checklist](migration.md)

