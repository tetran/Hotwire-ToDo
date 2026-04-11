# Badge

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

