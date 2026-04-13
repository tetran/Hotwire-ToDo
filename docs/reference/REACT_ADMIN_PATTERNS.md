# React Admin SPA patterns

Reference for recurring patterns in `app/javascript/admin/`. Distilled from findings accumulated during issues #204, #273, #293 and related admin pagination / filter work.

For Do/Don't day-to-day rules, see `docs/conventions/ADMIN_UI.md`. This file captures the **why** behind a handful of non-obvious patterns and the gotchas that drove them.

---

## 1. URL-synced pagination: three guards, not one

When pagination is driven by `useSearchParams` instead of component state, the view is newly exposed to any page number the user can type into the URL. A naive `Number(params.get('page')) || 1` leaks negatives (truthy), non-integers, and over-upper-bound values.

**Required defenses** — all three:

```tsx
// 1. Parse-time lower-bound guard
page: Math.max(1, Number(params.get('page')) || 1),

// 2. Post-fetch upper-bound clamp
useEffect(() => {
  if (meta.total_pages > 0 && filters.page > meta.total_pages) {
    setSearchParams(prev => {
      const next = new URLSearchParams(prev)
      if (meta.total_pages <= 1) next.delete('page')
      else next.set('page', String(meta.total_pages))
      return next
    }, { replace: true }) // 3. replace: true — do not pollute history
  }
}, [meta.total_pages, filters.page, setSearchParams])
```

- Pre-fetch upper-bound clamp is impossible (can't know `total_pages` without fetching). The post-fetch effect catches it after the first response.
- Guard the effect on `meta.total_pages > 0` to avoid firing before the first fetch.
- When clamped to 1, **delete** the `page` key rather than setting `page=1` — keeps shared URLs clean.
- `replace: true` is not optional — without it, the bad URL gets pushed to history and Back returns the user to it.

## 2. Backend side: pagy configuration

- Use `require "pagy/extras/overflow"` + `Pagy::DEFAULT[:overflow] = :last_page` to handle page > total_pages.
- **This does not cover `page=0` or negatives** — those raise `Pagy::VariableError`. Sanitize in a `Paginatable` concern: `[params.fetch(:page, 1).to_i, 1].max`.
- Index endpoints return `{ resource_key: [...], meta: { page, per_page, total_count, total_pages } }`.
- When changing an API `list()` return shape from `T[]` to `{ key, meta }`, **grep for all callers first** — non-index callers (dropdowns, dashboards, forms) will break silently.

## 3. `useSearchParams` reference is NOT stable — depend on `.toString()`

`useSearchParams()` from `react-router-dom` v7 is not guaranteed to return a referentially stable `URLSearchParams` instance across renders when the URL is unchanged. Using it directly as a `useMemo` / `useEffect` dep re-fires on every parent render — silent double-fetches, no visible symptom beyond extra network traffic.

```tsx
// BAD — re-fires on every render
const derived = useMemo(() => computeFromParams(searchParams), [searchParams])

// GOOD — stable primitive key
const searchParamsKey = searchParams.toString()
const derived = useMemo(() => {
  const params = new URLSearchParams(searchParamsKey) // rebuild inside
  return computeFromParams(params)
}, [searchParamsKey])
```

Rebuilding `URLSearchParams` inside the memo also keeps `react-hooks/exhaustive-deps` happy without a disable comment.

If you see double-fetches on a URL-synced page, check the memo/effect deps for `[searchParams]` first — most common cause.

## 4. `useRef` for previous-value comparison

When comparing current-vs-previous render values (e.g., reset page to 1 on query change), **always** use `useRef`. A plain object `{ current: value }` in the component body is recreated every render, so `prevRef.current !== current` is always false — the reset never fires, no runtime error, completely silent.

```tsx
const prevQueryRef = useRef(debouncedQuery)
useEffect(() => {
  if (prevQueryRef.current !== debouncedQuery) {
    setPage(1)
    prevQueryRef.current = debouncedQuery
  }
}, [debouncedQuery])
```

This is a common copy-paste bug when adapting patterns from examples — verify `useRef` is present in code review.

## 5. Filter chip label flicker: 3-tier fallback with `useRef` cache

Deriving chip labels from the currently-loaded data array works great for **shared URL paste** (label resolves after first fetch), but breaks on the **click-to-filter** path. Clicking a row instantly changes the filter id, but the data array still holds the PREVIOUS filter's results, so `find` returns nothing and the chip flashes `"Loading…"` for a paint cycle.

Fix: keep a write-on-click cache in `useRef`, populated **before** `setSearchParams`.

```tsx
const userLabelCacheRef = useRef<Map<number, string>>(new Map())

const applyUserFilter = (user: { id: number; name: string }) => {
  if (filters.user_id === user.id) return
  userLabelCacheRef.current.set(user.id, displayUserName(user)) // BEFORE URL change
  setFilterParam('user_id', String(user.id))
}

const resolveUserLabel = (): string | undefined => {
  if (!filters.user_id) return undefined
  const cached = userLabelCacheRef.current.get(filters.user_id) // 1. click cache
  if (cached) return cached
  const match = events.find(e => e.user.id === filters.user_id) // 2. derived
  if (match) return displayUserName(match.user)
  if (loading) return 'Loading…'                                 // 3. fallback
  return `User #${filters.user_id}`
}
```

- Use `useRef`, not `useState` — label cache changes must NOT trigger re-renders.
- Fallback order is load-bearing: `cache → derived → loading/id`. Swapping the first two reintroduces the flicker.
- Cache is write-on-click, read-on-render, never invalidated. Theoretically holds stale labels if the server-side name changes mid-session; a P3 edge case for chip UIs.

## 6. Stale-while-revalidate for filtered tables

The naive `{loading ? <LoadingRow /> : events.map(row => ...)}` blanks the entire `<tbody>` to a placeholder every time a filter changes — painful on high-frequency filter interactions.

Reorder the ternary so existing data takes precedence, and dim on refresh:

```tsx
// BAD — blanks the table on every filter change
{loading ? <LoadingRow /> : events.length === 0 ? <Empty /> : events.map(...)}

// GOOD — stale-while-revalidate
{events.length > 0 ? events.map(...) : loading ? <LoadingRow /> : <Empty />}

<tbody className={`transition-opacity duration-150 ${
  loading && events.length > 0 ? 'opacity-60' : 'opacity-100'
}`}>
```

- `LoadingRow` is only for **true initial load** (empty `events`). Once you have data, the loading state should dim, not replace.
- Conditional opacity only when `loading && events.length > 0` — on initial load the placeholder renders at full opacity.
- No new state, no new hooks, no SWR/React Query dependency needed for small local fetches.

## 7. Navigation semantics: `replace: true` vs `replace: false`

- **Pagination controls** (`setPage`, `setPerPage`): `replace: true` — do not flood history.
- **Filter / search changes** (`resetPage` included): `replace: false` — the user may want to undo with Back.
- **Clamp / scrub bad URL**: `replace: true` — never preserve bad state.

## 8. `Pagination` component display — use `meta.*`, not props

The "Showing X-Y of Z" text should use `meta.per_page` (server-confirmed) rather than the `perPage` prop (frontend state). Otherwise there is a momentary inconsistency during in-flight requests where the UI shows a count based on the new `perPage` but the rows are still the old page.

---

## Source incidents

- URL-sync pagination guards, `useSearchParams` stability, stale-while-revalidate, chip-label cache: issue #273 (event log filters)
- `useRef` previous-value, pagy configuration, `meta.*` display: issue #204 (admin pagination)
