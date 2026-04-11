# Implementation Checklist for New Components

When creating a new component, verify:

1. Card containers use `rounded-xl border border-slate-200 bg-white shadow-sm`
2. Headings inside cards use `Syne` font family
3. System/category labels use `DM Mono` with appropriate tracking
4. Primary actions use the accent color `#6366f1` with `shadow-md shadow-indigo-500/20`
5. All table headers use `text-xs font-semibold uppercase tracking-wider text-slate-400`
6. Status indicators use the Badge component with correct semantic variant
7. Hover transitions include `transition` or `transition-colors`
8. Text hierarchy follows the slate scale: 800 > 700 > 600 > 400 > 500

