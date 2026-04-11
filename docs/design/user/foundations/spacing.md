# Spacing and Layout

Spacing scale tokens and content width constraints.

## Current Spacing Usage

The current CSS mixes px and rem values inconsistently. Common literals observed:

- **Rem-based** (the majority): `0.25rem`, `0.5rem`, `0.75rem`, `1rem`, `1.5rem`, `2rem`, `3rem`
- **Pixel-based** (small fixed dimensions): `2px`, `4px`, `6px`, `8px`, `10px`, `12px`, `15px`, `25px`
- **Ad-hoc**: `5vh`, `75vh`, `80vw`, `90vw`, `2.5rem` (search collapse), `300px` (search expand)

## Recommended Spacing Scale

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

## Content Width Constraints

| Context            | Width                        | Source              |
|--------------------|------------------------------|----------------------|
| Main content       | Water.css default (~800px max) | external          |
| Modal              | `80vw`, `max-width: 600px`   | `modal.css`          |
| Search modal       | `90vw`, `max-width: 600px`   | `search.css`         |
| Auth form          | `max-width: 400px`           | `auth.css`           |
| Menu navigation    | `min-width: 200px`, `max-width: 67%` | `header-menu.css` |
| Search expanded    | `300px`                      | `search.css`         |

**Recommended**: align modal and search-modal max widths (both use 600px already — good); document `--modal-max-width: 600px` as a token for reuse.

