# Table

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

