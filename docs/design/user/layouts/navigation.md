# Navigation Pattern

Project selector, main menu, members menu, and active/hover states.

## Project Selector (Left)

- Trigger: the `h2.project-name` element inside `.project-selector` (the visible project title doubles as the dropdown trigger)
- Dropdown: `.menu-navigation` aligned `left: 0`, listing projects with per-row actions (edit, delete) in `.horizontal-actions`
- Current project: `.current-project` modifier applies `font-weight: bold`
- Footer action: `.project-selector__add-button` renders a "+ New project" CTA

## Main Menu (Right)

- User menu trigger: avatar or icon button (`.menu-button`)
- Contains: profile link, settings, logout
- Dropdown: `.menu-navigation` aligned `right: 0`

## Project Members Menu (Right, between search and user menu)

- Trigger: `.project-members .menu-button`
- Content: member list with per-row assign/remove actions and an add-member form

## Active / Hover States

| State         | Styling                                                |
|---------------|---------------------------------------------------------|
| Menu item hover | `background: #ccc` (`target`: `var(--color-surface-hover)`) |
| Current project | `font-weight: bold`                                  |
| Icon hover    | `background: rgba(0,0,0,0.1)` (`target`: `var(--overlay-hover)`) |
| Icon active   | `transform: translateY(2px)`                            |
| Scale-on-hover icon actions | `scale: 1.2` (used in project-selector row actions) |

