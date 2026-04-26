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

## 9. Guard chain ordering: finite-number first, side-effect last

Guard chains that compare external/API numeric data must obey two ordering invariants:

1. **`Number.isFinite()` runs before any `<` / `>` / `===` numeric comparison.** `NaN < 100`, `undefined > 0`, `Infinity <= 50` all evaluate to `false` — a "naive" guard chain becomes *permissive* on malformed input, which is the opposite of what defensive guards exist for.
2. **Side-effect guards (`Set.add`, counter increment, dedup state) run last** — short-circuited calls must not consume shared-state budget.

Document inline as "ordering invariant — do not reorder", not "priority" (refactorers read "priority" as "your call"). Add a regression test poking at the order: malformed input → no-op AND does not register the resource as reported; subsequent valid input still fires normally. This pattern generalizes beyond guards: anywhere `a < b` runs on data from an external boundary (API response, URL query, form input), `Number.isFinite` should be the first thing checked.

## 10. Shared `*Api.ts` signature changes are cross-cutting refactors

Functions in `app/javascript/admin/lib/api.ts` are de-facto contracts; the same `fooApi.list()` is typically imported by 5+ pages with different usage semantics (dropdown full-fetch, paginated browse, config picker). Before proposing a signature change, run:

- `Grep "fooApi\.list"` across the whole admin SPA to enumerate all call sites
- For each call site, check what fields of the response are consumed — response-shape changes break consumers that don't appear in any argument-level grep (e.g. `meta.total_count` flowing into `reportTruncation`)

Prefer **opt-out at the call site** (one page calls differently) over **changing the shared signature**. Document the blast-radius check explicitly in the plan: "Call sites: A, B, C. Each is unaffected because [reason]." This makes the plan reviewable and creates an audit trail.

## 11. ARIA `role="alert"` vs `role="status"` — pick by urgency, not visual style

`role="alert"` carries implicit `aria-live="assertive"` + `aria-atomic="true"` (interrupting). `role="status"` carries implicit `aria-live="polite"` + `aria-atomic="true"` (queued after current narration). Setting an explicit `aria-live="polite"` on `role="alert"` is technically allowed by WAI-ARIA 1.2 but screen reader implementations are inconsistent — some honor the override, some respect only the role's implicit value.

### Placement rule

| UI scope | Role | Behavior |
|---|---|---|
| Section / inline error (e.g. `SectionError` for partial fetch failure) | `role="status"` | polite, queued |
| Page-level critical error (full-page banner blocking interaction) | `role="alert"` | assertive, interrupting |

Do **not** combine `role="alert"` with `aria-live="polite"`. If you want polite, change the role. Same for `role="status"` + `aria-live="assertive"`.

When changing a role attribute, update **all** Testing Library variants (see §12 below) — `getByRole('alert')` only matches `role="alert"` elements, not `role="status"`.

## 12. Role-string refactor: grep all 5 Testing Library query variants

When changing a component's `role` attribute or refactoring tests after one, a single `replace_all` on `getByRole('<old-role>')` misses these siblings:

- `queryByRole('<old-role>')` — negative-assertion variants
- `getAllByRole('<old-role>')` — multiple-element variants
- `findByRole('<old-role>')` — async variants
- `findAllByRole('<old-role>')` — async + multiple

Use a single regex covering all 5 prefixes: `(get|query|getAll|findAll|find)ByRole\(['"]<old-role>['"]`. After Edit, re-grep for the bare role string (`'alert'`, `"alert"`) to confirm zero residue — `expect(elem).toHaveAttribute('role', 'alert')` style assertions also use the literal and need updating. Same trap applies to `getByText` / `getByLabelText` / etc.

## 13. `role="tooltip"` is unwired without `aria-describedby` — prefer `aria-hidden="true"` for purely visual tooltips

The WAI-ARIA `tooltip` role is part of a **trigger ↔ tooltip pair**: the trigger must carry `aria-describedby` pointing to the tooltip element's `id`. Without that wiring, `<span role="tooltip">` leaks stray text into the AT reading order — some screen readers expose the tooltip text right after the trigger's existing label, making the user hear "Dashboard" twice (once from `aria-label` on the link, once from the orphaned tooltip span).

### Placement rule

| Visual is... | AT path is... | Solution |
|---|---|---|
| Decorative hover/focus label, the trigger already carries `aria-label` / `aria-labelledby` (e.g. icon-only nav rail items) | Already covered by trigger's `aria-label` | `aria-hidden="true"` on the visual span. **Do not** use `role="tooltip"`. |
| Genuine descriptive content the trigger does not already convey | Needs to be wired | Trigger: `aria-describedby="tip-id"`. Tooltip: `id="tip-id"` + `role="tooltip"`. Both halves required. |

The wrong default for "I want a hover-revealed label visually" is `role="tooltip"`. The right default is `aria-hidden="true"` + AT path via the trigger's existing `aria-label` / `aria-labelledby`. When a reviewer flags `role="tooltip"` as orphaned, the answer is rarely "wire up `aria-describedby`" — usually the AT path is already covered elsewhere and the visual should just go `aria-hidden`.

## 14. Playwright `getByRole({ name })` is substring matching — distinct labels can collide

`getByRole('button', { name: 'Close navigation' })` matches both `aria-label="Close navigation"` AND `aria-label="Close navigation menu"` because the role-name match is **substring/regex-based by default** (Playwright wraps `name` in a regex `/Close navigation/`). React Testing Library's `getByRole` behaves the same way.

### Concrete failure mode

```
strict mode violation: getByRole('button', { name: 'Close navigation' }) resolved to 2 elements:
  1) <button aria-label="Close navigation"> ... in-drawer ✕
  2) <button aria-label="Close navigation menu"> ... hamburger
```

### Resolutions

- Use `{ name: 'Close navigation', exact: true }` on the targeting query when the labels are already semantically appropriate.
- Or make the labels structurally distinct so substring overlap is impossible (e.g. "Close drawer" vs "Close navigation menu").
- For buttons in the same tree with semantically similar labels, prefer `getByTestId` — exact by definition.

### Pre-test audit

When introducing a dynamic `aria-label` that toggles between two related strings (e.g. "Open X" / "Close X"), grep all `getByRole({ name: ... })` calls for substring matches against either label. Any pair where one label is a strict prefix of another is a collision waiting to happen.

---

## Source incidents

- URL-sync pagination guards, `useSearchParams` stability, stale-while-revalidate, chip-label cache: issue #273 (event log filters)
- `useRef` previous-value, pagy configuration, `meta.*` display: issue #204 (admin pagination)
