# Colors

Brand, surface, semantic, and text-hierarchy colors for the admin SPA.

## Brand / Structural Colors

| Token              | Value       | Tailwind                | Usage                           |
|---------------------|------------|-------------------------|---------------------------------|
| `--color-sidebar`   | `#0f1117`  | `bg-[#0f1117]`          | Sidebar background              |
| `--color-sidebar-border` | `#1e2130` | `border-[#1e2130]`  | Sidebar dividers                |
| `--color-accent`    | `#6366f1`  | `bg-[#6366f1]`          | Primary accent (Indigo 500)     |
| Accent hover        | `#5558e8`  | `hover:bg-[#5558e8]`    | Accent hover state              |
| `--color-surface`   | `#f8f9fc`  | `bg-[#f8f9fc]`          | Main content background         |

## Surface Colors

| Surface         | Value            | Usage                          |
|-----------------|------------------|--------------------------------|
| White           | `#ffffff`        | Cards, panels, table containers |
| Surface         | `#f8f9fc`        | Page background                |
| Dark card       | `#161b27`        | Login card (dark theme context) |

## Semantic Colors (Badge System)

Each semantic color uses a three-layer system: background at 15% opacity, text at full color (400 shade), ring at 30% opacity.

| Variant    | Background              | Text                | Ring                      |
|------------|-------------------------|---------------------|---------------------------|
| `success`  | `bg-emerald-500/15`     | `text-emerald-400`  | `ring-emerald-500/30`     |
| `danger`   | `bg-rose-500/15`        | `text-rose-400`     | `ring-rose-500/30`        |
| `info`     | `bg-indigo-500/15`      | `text-indigo-400`   | `ring-indigo-500/30`      |
| `neutral`  | `bg-slate-500/15`       | `text-slate-400`    | `ring-slate-500/30`       |
| `warning`  | `bg-amber-500/15`       | `text-amber-400`    | `ring-amber-500/30`       |

## Text Color Hierarchy

| Level         | Class              | Hex Approx. | Usage                              |
|---------------|--------------------|-------------|-------------------------------------|
| Primary       | `text-slate-800`   | `#1e293b`   | Headings, stat values               |
| Secondary     | `text-slate-700`   | `#334155`   | Body text, names, panel titles      |
| Tertiary      | `text-slate-600`   | `#475569`   | Nav section labels, secondary info  |
| Muted         | `text-slate-400`   | `#94a3b8`   | Captions, metadata, table headers   |
| Faint         | `text-slate-500`   | `#64748b`   | Sidebar subtitles, timestamps       |
| On dark       | `text-white`       | `#ffffff`   | Sidebar text, button labels         |
| On dark muted | `text-slate-200`   | `#e2e8f0`   | Sidebar user name, hover nav items  |

## Accent Color Variants (StatCard)

Used for stat card icon tints:

| Color            | Class              | Usage Example   |
|------------------|--------------------|-----------------|
| Indigo           | `text-indigo-400`  | Users           |
| Purple           | `text-purple-400`  | Roles           |
| Cyan             | `text-cyan-400`    | LLM Providers   |
| Emerald          | `text-emerald-400` | LLM Models      |

