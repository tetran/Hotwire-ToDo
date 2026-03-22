# Hobo Admin Design System

## 1. Overview

Hobo Admin is a React SPA built with Vite and TailwindCSS v4, serving as the administrative interface for the Hobo application. The visual language is defined by a **dark sidebar + light content area** contrast pattern that provides clear spatial hierarchy and reduces cognitive load for data-heavy admin workflows.

### Design Principles

- **Contrast-Driven Hierarchy** -- The dark sidebar (`#0f1117`) anchors navigation, while the light surface (`#f8f9fc`) gives content maximum readability.
- **Minimalist Data Density** -- Generous whitespace paired with compact typography keeps information scannable without feeling sparse.
- **Subtle Depth** -- Shadows are small and tinted (`shadow-indigo-500/20`), borders are near-invisible (`slate-100`, `slate-200`), and color fills use low opacity (`/15`, `/30`) to avoid visual noise.
- **Typographic Personality** -- Two carefully chosen typefaces (Syne for headings, DM Mono for system labels) create a modern, technical aesthetic.

---

## 2. Color Palette

### 2.1 Brand / Structural Colors

| Token              | Value       | Tailwind                | Usage                           |
|---------------------|------------|-------------------------|---------------------------------|
| `--color-sidebar`   | `#0f1117`  | `bg-[#0f1117]`          | Sidebar background              |
| `--color-sidebar-border` | `#1e2130` | `border-[#1e2130]`  | Sidebar dividers                |
| `--color-accent`    | `#6366f1`  | `bg-[#6366f1]`          | Primary accent (Indigo 500)     |
| Accent hover        | `#5558e8`  | `hover:bg-[#5558e8]`    | Accent hover state              |
| `--color-surface`   | `#f8f9fc`  | `bg-[#f8f9fc]`          | Main content background         |

### 2.2 Surface Colors

| Surface         | Value            | Usage                          |
|-----------------|------------------|--------------------------------|
| White           | `#ffffff`        | Cards, panels, table containers |
| Surface         | `#f8f9fc`        | Page background                |
| Dark card       | `#161b27`        | Login card (dark theme context) |

### 2.3 Semantic Colors (Badge System)

Each semantic color uses a three-layer system: background at 15% opacity, text at full color (400 shade), ring at 30% opacity.

| Variant    | Background              | Text                | Ring                      |
|------------|-------------------------|---------------------|---------------------------|
| `success`  | `bg-emerald-500/15`     | `text-emerald-400`  | `ring-emerald-500/30`     |
| `danger`   | `bg-rose-500/15`        | `text-rose-400`     | `ring-rose-500/30`        |
| `info`     | `bg-indigo-500/15`      | `text-indigo-400`   | `ring-indigo-500/30`      |
| `neutral`  | `bg-slate-500/15`       | `text-slate-400`    | `ring-slate-500/30`       |
| `warning`  | `bg-amber-500/15`       | `text-amber-400`    | `ring-amber-500/30`       |

### 2.4 Text Color Hierarchy

| Level         | Class              | Hex Approx. | Usage                              |
|---------------|--------------------|-------------|-------------------------------------|
| Primary       | `text-slate-800`   | `#1e293b`   | Headings, stat values               |
| Secondary     | `text-slate-700`   | `#334155`   | Body text, names, panel titles      |
| Tertiary      | `text-slate-600`   | `#475569`   | Nav section labels, secondary info  |
| Muted         | `text-slate-400`   | `#94a3b8`   | Captions, metadata, table headers   |
| Faint         | `text-slate-500`   | `#64748b`   | Sidebar subtitles, timestamps       |
| On dark       | `text-white`       | `#ffffff`   | Sidebar text, button labels         |
| On dark muted | `text-slate-200`   | `#e2e8f0`   | Sidebar user name, hover nav items  |

### 2.5 Accent Color Variants (StatCard)

Used for stat card icon tints:

| Color            | Class              | Usage Example   |
|------------------|--------------------|-----------------|
| Indigo           | `text-indigo-400`  | Users           |
| Purple           | `text-purple-400`  | Roles           |
| Cyan             | `text-cyan-400`    | LLM Providers   |
| Emerald          | `text-emerald-400` | LLM Models      |

---

## 3. Typography

### 3.1 Font Families

| Token            | Font Stack               | CSS Variable        | Usage                                  |
|------------------|--------------------------|---------------------|----------------------------------------|
| Display          | `Syne, sans-serif`       | `--font-syne`       | Headings, stat values, panel titles, logo |
| Mono             | `DM Mono, monospace`     | `--font-dm-mono`    | Super-labels, section labels, IDs      |
| Body             | System default (Tailwind)| --                  | All other text                          |

### 3.2 Text Size Hierarchy

| Role              | Size Class    | Weight            | Additional Styles                           | Font      |
|-------------------|---------------|-------------------|---------------------------------------------|-----------|
| Page title        | `text-2xl`    | `font-bold`       | --                                          | Syne      |
| Login title       | `text-xl`     | `font-bold`       | --                                          | Syne      |
| Card heading      | `text-lg`     | `font-semibold`   | --                                          | Syne      |
| Panel title       | `text-sm`     | `font-semibold`   | --                                          | Syne      |
| Stat value        | `text-3xl`    | `font-bold`       | --                                          | Syne      |
| Sidebar logo      | `text-sm`     | `font-bold`       | `leading-none`                              | Syne      |
| Body text         | `text-sm`     | `font-medium`     | --                                          | Default   |
| Small text        | `text-xs`     | `font-medium`     | --                                          | Default   |
| Table header      | `text-xs`     | `font-semibold`   | `uppercase tracking-wider`                  | Default   |
| Stat label        | `text-xs`     | `font-medium`     | `uppercase tracking-widest`                 | Default   |
| Super-label       | `text-[10px]` | `font-semibold`   | `tracking-[0.2em]`                          | DM Mono   |
| Section label     | `text-[9px]`  | `font-semibold`   | `tracking-[0.15em]`                         | DM Mono   |
| Sidebar subtitle  | `text-[9px]`  | --                | `tracking-[0.15em]`                         | DM Mono   |
| ID column         | `text-xs`     | --                | --                                          | DM Mono   |

### 3.3 Special Typography Patterns

**Super-label** (page header category indicator):
```
text-[10px] font-semibold tracking-[0.2em] text-slate-400
font-family: DM Mono, monospace
Content: uppercase (e.g. "OVERVIEW", "MANAGEMENT")
```

**Section label** (sidebar nav group title):
```
text-[9px] font-semibold tracking-[0.15em] text-slate-600
font-family: DM Mono, monospace
Content: uppercase (e.g. "NAVIGATION", "AI INFRASTRUCTURE")
```

---

## 4. Spacing and Layout

### 4.1 Spacing Scale (commonly used values)

| Token   | Value   | Usage                                    |
|---------|---------|------------------------------------------|
| `0.5`   | 2px     | Nav item vertical gap (`space-y-0.5`)    |
| `1`     | 4px     | Badge vertical padding                   |
| `1.5`   | 6px     | Subtitle top margin                      |
| `2`     | 8px     | Badge horizontal padding, small gaps     |
| `2.5`   | 10px    | Small button padding, avatar icon gap    |
| `3`     | 12px    | Nav item padding, element gaps           |
| `4`     | 16px    | Sidebar horizontal padding, section margin |
| `5`     | 20px    | Card padding, table cell padding         |
| `6`     | 24px    | Main content padding, page section gap   |
| `8`     | 32px    | Login card padding                       |

### 4.2 Grid System

- **Stat cards**: `grid grid-cols-2 gap-4 lg:grid-cols-4`
- **Dashboard bottom**: `grid grid-cols-1 gap-4 lg:grid-cols-3` (table `lg:col-span-2`)
- **Page sections**: `space-y-5` or `space-y-6`

### 4.3 Content Width Constraints

| Context        | Width                     |
|----------------|---------------------------|
| Sidebar        | `w-[220px]` fixed         |
| Login form     | `max-w-sm` (384px)        |
| Main content   | `flex-1` (fluid)          |

---

## 5. Component Specifications

### 5.1 Badge

Pill-shaped status indicator with semantic color variants.

**Structure**: `<span>` with inline-flex layout.

**Base classes**:
```
inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium
```

**Variants**:

| Variant   | Classes                                                      |
|-----------|--------------------------------------------------------------|
| `success` | `bg-emerald-500/15 text-emerald-400 ring-1 ring-emerald-500/30` |
| `danger`  | `bg-rose-500/15 text-rose-400 ring-1 ring-rose-500/30`         |
| `info`    | `bg-indigo-500/15 text-indigo-400 ring-1 ring-indigo-500/30`   |
| `neutral` | `bg-slate-500/15 text-slate-400 ring-1 ring-slate-500/30`      |
| `warning` | `bg-amber-500/15 text-amber-400 ring-1 ring-amber-500/30`      |

**Default variant**: `neutral`

**Usage examples**: Role badges (`admin` = danger, `user_manager` = warning, others = info), status indicators (active = success, inactive = neutral).

### 5.2 Avatar

Circular gradient avatar showing user initials.

**Base classes**:
```
flex items-center justify-center rounded-full bg-gradient-to-br font-semibold text-white shrink-0
```

**Size variants**:

| Size | Classes           | Dimensions |
|------|-------------------|------------|
| `sm` | `w-7 h-7 text-xs` | 28px       |
| `md` | `w-9 h-9 text-sm` | 36px       |
| `lg` | `w-11 h-11 text-base` | 44px   |

**Default size**: `md`

**Gradient palette** (selected by `name.charCodeAt(0) % 5`):

| Index | Gradient                          |
|-------|-----------------------------------|
| 0     | `from-indigo-500 to-purple-600`   |
| 1     | `from-cyan-500 to-blue-600`      |
| 2     | `from-emerald-500 to-teal-600`   |
| 3     | `from-orange-500 to-rose-600`    |
| 4     | `from-pink-500 to-fuchsia-600`   |

**Initials logic**: Split name by spaces, take first character of each part, join, uppercase, max 2 characters.

### 5.3 StatCard

Dashboard metric display card.

**Container**:
```
rounded-xl border border-slate-200 bg-white p-5 shadow-sm
```

**Internal structure**:
- **Header row**: `flex items-center justify-between`
  - Label: `text-xs font-medium uppercase tracking-widest text-slate-400`
  - Icon: `text-lg` + accent color class (e.g. `text-indigo-400`)
- **Value**: `mt-3 text-3xl font-bold text-slate-800` with `font-family: Syne`
- **Subtitle** (optional): `mt-1.5 text-xs text-slate-400`

**Props**:
- `label`: string -- uppercase metric name
- `value`: number | string -- large display value
- `icon`: ReactNode -- icon element
- `accent`: string -- Tailwind text color class (default: `text-indigo-400`)
- `subtitle`: string (optional) -- additional context

### 5.4 Button

Three button variants used throughout the application.

**Primary Button**:
```
rounded-lg bg-[#6366f1] px-4 py-2 text-sm font-medium text-white
shadow-md shadow-indigo-500/20 transition hover:bg-[#5558e8]
```
Full-width variant (login): adds `w-full py-2.5 font-semibold shadow-lg active:scale-[0.98]`

**Secondary Button (Edit)**:
```
rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium
text-slate-600 transition hover:bg-slate-50
```

**Danger Button (Delete)**:
```
rounded-md border border-rose-200 px-2.5 py-1 text-xs font-medium
text-rose-500 transition hover:bg-rose-50
```

**Logout Button (Sidebar)**:
```
flex w-full items-center gap-2 rounded-lg px-2 py-2 text-xs
text-slate-500 transition-colors hover:bg-white/5 hover:text-slate-300
```

**Text Link (inline action)**:
```
text-xs text-[#6366f1] hover:underline
```

### 5.5 Table

Data table for list views (Users, etc.).

**Container**:
```
rounded-xl border border-slate-200 bg-white shadow-sm
```

**Table element**: `width: 100%; border-collapse: collapse`

**Header row**:
```
<tr> border-b border-slate-100
<th> px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400
```

**Body**:
```
<tbody> divide-y divide-slate-50
<tr> transition-colors hover:bg-slate-50/50
<td> px-5 py-3.5
```

**Cell content styles**:
- ID column: `text-xs text-slate-400` with `font-family: DM Mono`
- Name: `text-sm font-medium text-slate-700`
- Email / metadata: `text-xs text-slate-400`
- Actions cell: `flex items-center gap-2`

### 5.6 Card / Panel

Generic content container with optional header.

**Container**:
```
rounded-xl border border-slate-200 bg-white shadow-sm
```

**With header**:
```
Header: flex items-center justify-between border-b border-slate-100 px-5 py-4
Title:  text-sm font-semibold text-slate-700 (font-family: Syne)
Action: text-xs text-[#6366f1] hover:underline
```

**List content inside panel**:
```
divide-y divide-slate-50
Item: flex items-center gap-3 px-5 py-3
```

**Dark variant (Login card)**:
```
rounded-2xl border border-[#1e2130] bg-[#161b27] p-8 shadow-2xl
```

### 5.7 SearchBox

Inline search input placeholder.

**Page-level search**:
```
flex items-center gap-2 rounded-lg border border-slate-200 bg-white px-3 py-2
Icon: h-3.5 w-3.5 text-slate-400
Text: text-xs text-slate-400
```

**Header-level search**:
```
flex items-center gap-2 rounded-lg border border-slate-200 bg-slate-50 px-3 py-1.5
Icon: h-3.5 w-3.5 text-slate-400
Text: text-xs text-slate-400
```

### 5.8 Form Input (Login / Dark Theme)

**Label**: `text-xs font-medium text-slate-400`

**Input field**:
```
w-full rounded-lg border border-[#1e2130] bg-[#0f1117] px-3 py-2.5
text-sm text-white placeholder-slate-600 outline-none ring-0 transition
focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/50
```

**Error alert**:
```
rounded-lg border border-rose-500/30 bg-rose-500/10 px-4 py-3 text-sm text-rose-400
```

---

## 6. Layout System

### 6.1 Overall Structure

```
+--[Sidebar 220px]--+--[Main Content flex-1]------+
|  #0f1117           |  Header h-14 bg-white       |
|                    |  border-b border-slate-200   |
|  Logo area         |-------------------------------|
|  border-b          |                               |
|                    |  Content area                 |
|  Nav sections      |  p-6                          |
|  py-4              |  bg-[#f8f9fc]                 |
|                    |  overflow-y-auto              |
|  User footer       |                               |
|  border-t          |                               |
+--------------------+-------------------------------+
```

**Root**: `flex min-h-screen bg-[#f8f9fc]`

### 6.2 Sidebar

- Width: `w-[220px] shrink-0`
- Background: `bg-[#0f1117]`
- Border: `border-r border-[#1e2130]`
- Layout: `flex flex-col` (logo top, nav flex-1, user footer bottom)

**Logo area**:
- Padding: `px-4 py-5`
- Border: `border-b border-[#1e2130]`
- Icon box: `h-8 w-8 rounded-lg bg-[#6366f1] shadow-md shadow-indigo-500/30`

**Nav sections**:
- Container: `py-4`, each section `mb-4 px-3`
- Section label: see Typography section 3.3
- Item list: `space-y-0.5`

**User footer**:
- Border: `border-t border-[#1e2130]`
- Padding: `px-3 py-4`

### 6.3 Top Header

```
flex h-14 shrink-0 items-center border-b border-slate-200 bg-white px-6
```

Contains: breadcrumb on left, search on right.

### 6.4 Main Content Area

```
flex-1 overflow-y-auto p-6
```

### 6.5 Login Page Layout

Full-screen dark background:
```
flex min-h-screen items-center justify-center bg-[#0f1117]
```

Form container: `w-full max-w-sm px-4`

---

## 7. Navigation

### 7.1 Sidebar Navigation States

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
Icon: text-slate-600
```

### 7.2 Active State Logic

- Items with `exact: true` match only on exact pathname equality.
- Other items match when pathname starts with the item's `to` path.

### 7.3 Navigation Sections

Sections are visually separated by labeled groups:

| Section Label         | Items                              |
|-----------------------|------------------------------------|
| NAVIGATION            | Dashboard, Users, Roles, Permissions |
| AI INFRASTRUCTURE     | LLM Providers                      |

---

## 8. Page Header Pattern

Standard page header structure used across all styled pages.

```tsx
<div className="flex items-end justify-between">
  <div>
    {/* Super-label: DM Mono, 10px, tracking 0.2em, uppercase */}
    <p className="text-[10px] font-semibold tracking-[0.2em] text-slate-400"
       style={{ fontFamily: 'DM Mono, monospace' }}>
      SECTION_NAME
    </p>
    {/* Title: Syne, 2xl, bold */}
    <h1 className="text-2xl font-bold text-slate-800"
        style={{ fontFamily: 'Syne, sans-serif' }}>
      Page Title
    </h1>
    {/* Optional subtitle */}
    <p className="mt-0.5 text-xs text-slate-400">Subtitle text</p>
  </div>
  {/* Right side: action buttons / search */}
</div>
```

---

## 9. Shadow System

| Level      | Class                          | Usage                        |
|------------|--------------------------------|------------------------------|
| Subtle     | `shadow-sm`                    | Cards, panels, tables        |
| Medium     | `shadow-md shadow-indigo-500/20` | Primary buttons            |
| Accent     | `shadow-md shadow-indigo-500/30` | Logo icon box              |
| Heavy      | `shadow-lg shadow-indigo-500/20` | Login primary button       |
| Maximum    | `shadow-2xl`                   | Login card                   |
| Accent lg  | `shadow-lg shadow-indigo-500/30` | Login logo icon            |

Note: Tinted shadows using `shadow-indigo-500/XX` are reserved for accent-colored elements only. All other components use neutral `shadow-sm`.

---

## 10. Border System

| Context          | Class                      | Usage                      |
|------------------|----------------------------|----------------------------|
| Card outline     | `border border-slate-200`  | Cards, tables, search box  |
| Panel divider    | `border-b border-slate-100`| Table header, panel header |
| Row divider      | `divide-y divide-slate-50` | Table rows, list items     |
| Sidebar border   | `border-r border-[#1e2130]`| Sidebar right edge         |
| Sidebar divider  | `border-b border-[#1e2130]`| Logo/nav/footer separation |
| Dark card border | `border border-[#1e2130]`  | Login card                 |

---

## 11. Border Radius Scale

| Size        | Class          | Usage                        |
|-------------|----------------|------------------------------|
| Full        | `rounded-full` | Badges, avatars              |
| 2xl         | `rounded-2xl`  | Login card                   |
| xl          | `rounded-xl`   | Cards, panels, tables, logo icon (login) |
| lg          | `rounded-lg`   | Buttons, nav items, inputs, sidebar logo icon |
| md          | `rounded-md`   | Small buttons (edit/delete), provider icons |

---

## 12. Icon Conventions

- **Icon library**: Heroicons (outline style), rendered as inline SVG
- **Sidebar nav icons**: `h-4 w-4`, `strokeWidth={1.5}`
- **Stat card icons**: `h-5 w-5`, `strokeWidth={1.5}`
- **Small UI icons** (search, logout): `h-3.5 w-3.5`, `strokeWidth={2}`
- **Logo icon**: `h-4 w-4` (sidebar), `h-6 w-6` (login), `strokeWidth={2}`

---

## 13. CSS Variables Reference

Defined in `app/javascript/admin/styles/admin.css` via TailwindCSS v4 `@theme`:

```css
@theme {
  --font-syne: 'Syne', sans-serif;
  --font-dm-mono: 'DM Mono', monospace;
  --color-sidebar: #0f1117;
  --color-sidebar-border: #1e2130;
  --color-accent: #6366f1;
  --color-surface: #f8f9fc;
}
```

These tokens can be referenced in Tailwind as `bg-sidebar`, `border-sidebar-border`, `bg-accent`, `bg-surface`, `font-syne`, `font-dm-mono`.

---

## 14. Implementation Checklist for New Components

When creating a new component, verify:

1. Card containers use `rounded-xl border border-slate-200 bg-white shadow-sm`
2. Headings inside cards use `Syne` font family
3. System/category labels use `DM Mono` with appropriate tracking
4. Primary actions use the accent color `#6366f1` with `shadow-md shadow-indigo-500/20`
5. All table headers use `text-xs font-semibold uppercase tracking-wider text-slate-400`
6. Status indicators use the Badge component with correct semantic variant
7. Hover transitions include `transition` or `transition-colors`
8. Text hierarchy follows the slate scale: 800 > 700 > 600 > 400 > 500

---

## 15. Pages Pending Design System Alignment

The following pages currently use inline styles instead of the Tailwind design system and should be updated to match:

- `RolesIndexPage` -- uses raw inline styles for table and layout
- `RoleEditPage` -- unstyled form
- `RoleNewPage` -- unstyled form
- `UserEditPage` -- unstyled form with inline `color: 'red'` errors
- `UserNewPage` -- unstyled form
- `PermissionsIndexPage` -- likely unstyled
- `PermissionDetailPage` -- likely unstyled
- LLM provider/model pages -- partially styled
