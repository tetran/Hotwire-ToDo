# StatCard

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

