# Typography

Font families (Syne / DM Mono / system) and the text size hierarchy.

## Font Families

| Token            | Font Stack               | CSS Variable        | Usage                                  |
|------------------|--------------------------|---------------------|----------------------------------------|
| Display          | `Syne, sans-serif`       | `--font-syne`       | Headings, stat values, panel titles, logo |
| Mono             | `DM Mono, monospace`     | `--font-dm-mono`    | Super-labels, section labels, IDs      |
| Body             | System default (Tailwind)| --                  | All other text                          |

## Text Size Hierarchy

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

## Special Typography Patterns

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

