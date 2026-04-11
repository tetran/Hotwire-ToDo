# Navigation

## Sidebar Navigation States

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

## Active State Logic

- Items with `exact: true` match only on exact pathname equality.
- Other items match when pathname starts with the item's `to` path.

## Navigation Sections

Sections are visually separated by labeled groups:

| Section Label         | Items                              |
|-----------------------|------------------------------------|
| NAVIGATION            | Dashboard, Users, Roles, Permissions |
| AI INFRASTRUCTURE     | LLM Providers                      |

