# Navigation

## Sidebar States

The sidebar's behavior switches based on viewport width (`md` = 768px). State is persisted per-viewport in independent `localStorage` keys.

| Mode | Viewport | Width | Position | Transform / Width Animation |
|---|---|---|---|---|
| Desktop expanded | ≥ md | `w-[220px]` | relative flow | `transition-[width] duration-200` |
| Desktop collapsed (rail) | ≥ md | `w-16` (64px) | relative flow | `transition-[width] duration-200`; labels and section headings cross-fade between `opacity-0` and `opacity-100` |
| Mobile drawer (open) | < md | `w-64` (256px) | `fixed inset-y-0 left-0 z-40` | `translate-x-0`, `transition-transform duration-300 ease-out` |
| Mobile drawer (closed) | < md | `w-64` (256px) | `fixed inset-y-0 left-0 z-40` | `-translate-x-full` |

**Reduced motion**: `motion-reduce:transition-none motion-reduce:transform-none` is applied to the sidebar and drawer. When the OS "reduce motion" setting is enabled, transitions are disabled.

**Width animation trade-off**: The desktop rail collapse animates the `width` property, which is not GPU-composited. However, the 156px delta over 200ms (220px → 64px) is imperceptible in practice and is considered acceptable. If issues are reported, switch to a fixed-width container with `transform` instead.

## Sidebar Navigation Item States

**Active item**:
```
flex items-center gap-3 rounded-lg px-3 py-2 text-sm
bg-[rgba(99,102,241,0.15)] text-[#6366f1]
Icon: text-[#6366f1]
```

**Inactive item**:
```
flex items-center gap-3 rounded-lg px-3 py-2 text-sm transition-colors
text-slate-400 hover:bg-white/5 hover:text-slate-200
```

## Active State Logic

- Items with `exact: true` match only on exact pathname equality.
- Other items match when the pathname starts with the item's `to` path.

## Navigation Sections

Sections are visually separated into labeled groups:

| Section Label         | Items                                                  |
|-----------------------|--------------------------------------------------------|
| NAVIGATION            | Dashboard, Event Logs, System Info, Users              |
| ADMIN                 | Admin Accounts, Roles, Permissions                     |
| AI INFRASTRUCTURE     | LLM Providers, Prompt Sets, Suggestion Configs         |

## Toggle Locations

| Toggle | Location | Visibility | aria |
|---|---|---|---|
| **Desktop chevron** | Pinned absolute to the top-right edge of the sidebar header (`absolute -right-3 top-6`); circular (`rounded-full`, `h-6 w-6`); `shadow-md shadow-black/40` | `hidden md:flex` (desktop only) | `aria-label="Collapse sidebar" \| "Expand sidebar"`, `aria-controls="admin-sidebar"`, `aria-expanded={isDesktopExpanded}` |
| **Mobile hamburger** | Leftmost element of `AdminHeader` | `md:hidden` (mobile only) | `aria-label` toggles between `"Open navigation menu"` and `"Close navigation menu"` based on `isMobileOpen`; `aria-controls="admin-sidebar"`; `aria-expanded={isMobileOpen}` |
| **In-drawer ✕** | Top-right corner of the mobile drawer header | Mobile drawer only | `aria-label="Close navigation"` (distinct wording from the hamburger to avoid ambiguous role-name targeting in tests and screen readers) |

The chevron points **left** when expanded ("collapse" intent) and **right** when collapsed ("expand" intent — `rotate-180`).

## Three Dismiss Paths (Mobile Drawer)

The mobile drawer can be dismissed via any of the following paths. Multiple paths are intentional, accommodating accidental taps, user preference, and keyboard navigation:

1. **Backdrop tap**: Tap the translucent overlay (`fixed inset-0 z-30 bg-black/40`).
2. **In-drawer ✕**: Tap the close button in the drawer header.
3. **Esc key**: A `keydown` listener inside `useSidebarState` triggers only when `isMobileOpen && !isDesktop`.

## State Persistence

```
admin.sidebar.desktop  → 'expanded' | 'collapsed'
admin.sidebar.mobile   → 'open' | 'closed'
```

- **Storage format**: String literals are stored for human-readability when inspecting DevTools. The hook converts them to booleans in memory.
- **Default (missing key)**:
  - `admin.sidebar.desktop` → `expanded` (the desktop rail sits in normal flow; expanded by default is purely additive).
  - `admin.sidebar.mobile` → `closed` (the mobile drawer is off-canvas with a backdrop; defaulting to open would obscure the main content immediately on first visit).
  - There is no special "first-visit-only" tracking — the user's first toggle persists.
- **Robustness**: If `localStorage` throws (e.g., Safari Private Mode), the hook continues to operate using in-memory state only (failures are caught and swallowed).
- **Viewport transition behavior**:
  - **Mobile → desktop**: `isMobileOpen` is reset to `false` in memory but **not** written to `admin.sidebar.mobile` — preserving the user's last explicit mobile choice for when they return to a mobile viewport.
  - **Desktop → mobile**: `isMobileOpen` is rehydrated from `admin.sidebar.mobile` so a live resize restores the user's previously chosen state instead of always landing closed.
- **Shared-machine note**: `localStorage` is per-browser-profile. State carrying over across account switches is within spec.

## Tooltip Behavior (Collapsed Rail Only)

In the desktop collapsed state, nav item labels are `sr-only`, so a tooltip appears on hover or focus:

- Display is controlled via Tailwind `group-hover` + `group-focus-within` (focus-within ensures the tooltip also appears on Tab navigation).
- Each `<Link>` carries `aria-label={item.label}` so screen readers announce the destination.
- The tooltip uses `pointer-events-none` to avoid intercepting clicks.
- Style: `bg-slate-900 text-white text-xs px-2 py-1 rounded-md`; a flat pill with no arrow.

## z-index Discipline

| Layer | z-index |
|---|---|
| Backdrop | `z-30` |
| Drawer (mobile sidebar) | `z-40` |
| Tooltip (collapsed rail) | `z-50` |

## Out of Scope

The following are out of scope for this issue (#351). They will be addressed in separate issues if a need emerges:

- Focus trap (constraining focus inside the drawer)
- Body scroll lock (skipped due to iOS layout-shift bugs)
- Keyboard shortcuts such as Cmd/Ctrl + B
- Server-side persistence (currently `localStorage`-only)
- Resize handle (variable width)
- Drag-to-reorder for nav items
