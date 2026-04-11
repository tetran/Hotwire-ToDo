# Border and Radius

Border width/style usage and the recommended radius scale.

## Border Usage

| Width / Style     | Usage                                       |
|-------------------|----------------------------------------------|
| `1px solid var(--border)` | Cards, form fields, modal header, dividers, tabs |
| `1px solid var(--selection)` | Task complete checkbox              |
| No border         | Menu buttons, icon buttons, primary CTAs     |

## Border Radius Scale

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

