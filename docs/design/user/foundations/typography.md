# Typography

System font stack only; size scale; font weights and line heights.

## Font Stack

The application uses **the system font stack only** — no custom web fonts are loaded. This is a deliberate choice aligned with the lightweight, Water.css-based aesthetic: zero font payload, native rendering on every platform, and no FOUT.

| Family  | Source      | Usage                                   |
|---------|-------------|------------------------------------------|
| System  | Water.css default (`-apple-system, BlinkMacSystemFont, ...`) | All text |
| Material Symbols Outlined | Google Fonts CDN | Icons only |

This is intentionally different from the admin SPA (Syne + DM Mono). **Do not introduce custom fonts** to the user UI without explicit product direction.

## Current Size Scale (observed in CSS)

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

## Recommended Type Scale

Consolidate the six ad-hoc sizes (`0.75 / 0.8 / 0.8125 / 0.875 / 0.9 / 1 rem`) into a four-step rem-based scale:

| Token             | Value       | px @16base | Usage                                            |
|-------------------|-------------|-----------|---------------------------------------------------|
| `--text-xs`       | `0.75rem`   | 12px      | Secondary meta (parent crumbs, tiny badges)       |
| `--text-sm`       | `0.875rem`  | 14px      | Task meta, descriptions, search results, timestamps |
| `--text-base`     | `1rem`      | 16px      | Body copy, form inputs, task names                |
| `--text-lg`       | `1.125rem`  | 18px      | Modal titles, section headings (currently h2/h3) |

**Font weights**: use `400` (default), `500` (search result names), and `700` (`font-weight: bold` for comment usernames, modal titles, current project). Avoid introducing additional weights.

**Line heights**: rely on Water.css defaults except for icon-aligned rows (`line-height: 1` on close buttons, `1.5` on menu items).

