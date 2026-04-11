# Page Header Pattern

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

