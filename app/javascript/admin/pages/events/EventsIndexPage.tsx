import { useState, useEffect, useCallback, useMemo, useRef } from 'react'
import { useSearchParams } from 'react-router-dom'
import { eventsApi, type EventLog, type EventLogMeta, type EventLogListParams } from '../../lib/api'

const EVENT_BADGE_COLORS: Record<string, { bg: string; text: string; ring: string }> = {
  task_created: { bg: 'bg-emerald-500/15', text: 'text-emerald-400', ring: 'ring-emerald-500/30' },
  task_completed: { bg: 'bg-indigo-500/15', text: 'text-indigo-400', ring: 'ring-indigo-500/30' },
  task_updated: { bg: 'bg-amber-500/15', text: 'text-amber-400', ring: 'ring-amber-500/30' },
  task_deleted: { bg: 'bg-rose-500/15', text: 'text-rose-400', ring: 'ring-rose-500/30' },
  comment_posted: { bg: 'bg-violet-500/15', text: 'text-violet-400', ring: 'ring-violet-500/30' },
  project_created: { bg: 'bg-teal-500/15', text: 'text-teal-400', ring: 'ring-teal-500/30' },
  assignee_changed: { bg: 'bg-orange-500/15', text: 'text-orange-400', ring: 'ring-orange-500/30' },
  due_date_changed: { bg: 'bg-pink-500/15', text: 'text-pink-400', ring: 'ring-pink-500/30' },
}

const CATEGORY_LABELS: Record<string, string> = {
  basic_operation: 'Basic',
  collaboration: 'Collaboration',
  planning: 'Planning',
}

const EVENT_NAMES = [
  'task_created', 'task_completed', 'task_updated', 'task_deleted',
  'comment_posted', 'project_created', 'assignee_changed', 'due_date_changed',
]

// Fall back to email, then ID, when a user has no name set.
// (The TypeScript type says `name: string` but the DB allows empty.)
const displayUserName = (user: { id: number; name: string; email: string }): string =>
  user.name?.trim() || user.email || `User #${user.id}`

const FilterChip = ({ label, onClear }: { label: string; onClear: () => void }) => (
  <span className="inline-flex items-center gap-1.5 rounded-full border border-slate-200 bg-white px-2.5 py-1 text-xs text-slate-600">
    {label}
    <button
      type="button"
      onClick={onClear}
      aria-label={`Clear ${label} filter`}
      className="rounded text-slate-400 transition hover:text-slate-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-1 focus-visible:outline-indigo-500"
    >
      ✕
    </button>
  </span>
)

export const EventsIndexPage = () => {
  const [events, setEvents] = useState<EventLog[]>([])
  const [meta, setMeta] = useState<EventLogMeta>({ page: 1, per_page: 25, total_count: 0, total_pages: 0 })
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const [searchParams, setSearchParams] = useSearchParams()
  const searchParamsKey = searchParams.toString()

  // Label caches populated at click time. They survive the brief window after
  // `setSearchParams` fires but before the new fetch completes — without them,
  // the chip would flash to "Loading…" every time the user clicks a different
  // row (because the old `events` no longer contain the new filter's id).
  // The cache is keyed by id and persists for the component's lifetime; it is
  // NOT used on shared-URL first paint (no click ever happened), where the
  // `events`-derived fallback still applies.
  const userLabelCacheRef = useRef<Map<number, string>>(new Map())
  const projectLabelCacheRef = useRef<Map<number, string>>(new Map())

  const filters = useMemo<EventLogListParams>(() => {
    const params = new URLSearchParams(searchParamsKey)
    return {
      page: Number(params.get('page')) || 1,
      user_id: Number(params.get('user_id')) || undefined,
      project_id: Number(params.get('project_id')) || undefined,
      event_name: params.get('event_name') || undefined,
      from: params.get('from') || undefined,
      to: params.get('to') || undefined,
    }
  }, [searchParamsKey])

  const hasAnyFilter = Boolean(
    filters.event_name || filters.from || filters.to || filters.user_id || filters.project_id
  )

  const fetchEvents = useCallback(async (params: EventLogListParams, signal?: AbortSignal) => {
    setLoading(true)
    setError(null)
    try {
      const data = await eventsApi.list(params, { signal })
      setEvents(data.events)
      setMeta(data.meta)
    } catch (e) {
      if (e instanceof DOMException && e.name === 'AbortError') return
      setError(e instanceof Error ? e.message : 'Failed to fetch events')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    const controller = new AbortController()
    fetchEvents(filters, controller.signal)
    return () => controller.abort()
  }, [filters, fetchEvents])

  const setFilterParam = (key: string, value: string | undefined) => {
    setSearchParams(prev => {
      const next = new URLSearchParams(prev)
      if (!value) next.delete(key)
      else next.set(key, value)
      next.delete('page') // reset to page 1 on any filter change
      return next
    }, { replace: false })
  }

  const updateFilter = (key: keyof EventLogListParams, value: string) => {
    setFilterParam(key, value || undefined)
  }

  const applyUserFilter = (user: { id: number; name: string; email: string }) => {
    if (filters.user_id === user.id) return
    // Cache the label before updating the URL so the chip renders the real
    // name on the very next render, avoiding the "Loading…" flicker.
    userLabelCacheRef.current.set(user.id, displayUserName(user))
    setFilterParam('user_id', String(user.id))
  }

  const applyProjectFilter = (project: { id: number; name: string }) => {
    if (filters.project_id === project.id) return
    projectLabelCacheRef.current.set(project.id, project.name)
    setFilterParam('project_id', String(project.id))
  }

  const clearUserFilter = () => setFilterParam('user_id', undefined)
  const clearProjectFilter = () => setFilterParam('project_id', undefined)

  const clearAllFilters = () => {
    setSearchParams(new URLSearchParams(), { replace: false })
  }

  const setPage = (nextPage: number, options?: { replace?: boolean }) => {
    setSearchParams(prev => {
      const next = new URLSearchParams(prev)
      if (nextPage <= 1) next.delete('page')
      else next.set('page', String(nextPage))
      return next
    }, { replace: options?.replace ?? false })
  }

  // Clamp an out-of-range `page` param that arrives via a shared/bookmarked URL
  // (e.g. `/admin/events?page=999`, or a URL whose filter later narrowed the
  // result set below the stored page number). Without this, the view gets
  // stuck on an empty table with broken pagination even though earlier pages
  // have data. Uses `replace: true` to scrub the bad URL from history.
  useEffect(() => {
    if (meta.total_pages > 0 && filters.page > meta.total_pages) {
      setSearchParams(prev => {
        const next = new URLSearchParams(prev)
        if (meta.total_pages <= 1) next.delete('page')
        else next.set('page', String(meta.total_pages))
        return next
      }, { replace: true })
    }
  }, [meta.total_pages, filters.page, setSearchParams])

  const resolveUserLabel = (): string | undefined => {
    if (!filters.user_id) return undefined
    // 1. Click cache — populated when the user clicked a row. Survives the
    //    brief window where the new URL has been committed but the new events
    //    haven't arrived yet.
    const cached = userLabelCacheRef.current.get(filters.user_id)
    if (cached) return cached
    // 2. Derive from the currently-loaded events (handles shared-URL paste
    //    after the first fetch completes).
    const match = events.find(e => e.user.id === filters.user_id)
    if (match) return displayUserName(match.user)
    // 3. Fallbacks for first paint / empty result set.
    if (loading) return 'Loading…'
    return `User #${filters.user_id}`
  }

  const resolveProjectLabel = (): string | undefined => {
    if (!filters.project_id) return undefined
    const cached = projectLabelCacheRef.current.get(filters.project_id)
    if (cached) return cached
    const match = events.find(e => e.project?.id === filters.project_id)
    if (match?.project) return match.project.name
    if (loading) return 'Loading…'
    return `Project #${filters.project_id}`
  }

  const userLabel = resolveUserLabel()
  const projectLabel = resolveProjectLabel()

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr)
    return date.toLocaleString('ja-JP', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    })
  }

  const getBadge = (eventName: string) => {
    const colors = EVENT_BADGE_COLORS[eventName] ?? { bg: 'bg-slate-500/15', text: 'text-slate-400', ring: 'ring-slate-500/30' }
    return (
      <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${colors.bg} ${colors.text} ring-1 ${colors.ring}`}>
        {eventName}
      </span>
    )
  }

  return (
    <div className="space-y-5">
      {/* Header */}
      <div>
        <p className="text-[10px] font-semibold tracking-[0.2em] text-slate-400"
          style={{ fontFamily: 'DM Mono, monospace' }}>
          ANALYTICS
        </p>
        <h1 className="text-2xl font-bold text-slate-800"
          style={{ fontFamily: 'Syne, sans-serif' }}>
          Event Logs
        </h1>
        <p className="mt-0.5 text-xs text-slate-400">User activity timeline</p>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-end gap-3">
        <div>
          <label className="mb-1 block text-xs font-medium text-slate-500">Event Type</label>
          <select
            className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm text-slate-700"
            value={filters.event_name ?? ''}
            onChange={e => updateFilter('event_name', e.target.value)}
          >
            <option value="">All events</option>
            {EVENT_NAMES.map(name => (
              <option key={name} value={name}>{name}</option>
            ))}
          </select>
        </div>
        <div>
          <label className="mb-1 block text-xs font-medium text-slate-500">From</label>
          <input
            type="date"
            className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm text-slate-700"
            value={filters.from ?? ''}
            onChange={e => updateFilter('from', e.target.value)}
          />
        </div>
        <div>
          <label className="mb-1 block text-xs font-medium text-slate-500">To</label>
          <input
            type="date"
            className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm text-slate-700"
            value={filters.to ?? ''}
            onChange={e => updateFilter('to', e.target.value)}
          />
        </div>
        {hasAnyFilter && (
          <button
            type="button"
            onClick={clearAllFilters}
            className="ml-auto self-end rounded-md border border-slate-200 px-3 py-1.5 text-xs font-medium text-slate-600 transition hover:bg-slate-50 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-500"
          >
            Clear all filters
          </button>
        )}
      </div>

      {/* Active row-click filters */}
      {(userLabel || projectLabel) && (
        <div className="flex flex-wrap items-center gap-2">
          <span className="text-xs font-medium text-slate-500">Active filters:</span>
          {userLabel && (
            <FilterChip label={`User: ${userLabel}`} onClear={clearUserFilter} />
          )}
          {projectLabel && (
            <FilterChip label={`Project: ${projectLabel}`} onClear={clearProjectFilter} />
          )}
        </div>
      )}

      {/* Error */}
      {error && (
        <div className="rounded-lg border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-600">
          {error}
        </div>
      )}

      {/* Table */}
      <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
        <table className="w-full">
          <thead>
            <tr className="border-b border-slate-100">
              <th className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">
                Time
              </th>
              <th className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">
                Event
              </th>
              <th className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">
                User
              </th>
              <th className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">
                Project
              </th>
              <th className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">
                Task
              </th>
              <th className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">
                Category
              </th>
            </tr>
          </thead>
          <tbody
            className={`divide-y divide-slate-50 transition-opacity duration-150 ${
              loading && events.length > 0 ? 'opacity-60' : 'opacity-100'
            }`}
          >
            {events.length > 0 ? (
              events.map(event => (
                <tr key={event.id} className="transition-colors hover:bg-slate-50/50">
                  <td className="px-5 py-3.5 text-xs text-slate-500">
                    {formatDate(event.occurred_at)}
                  </td>
                  <td className="px-5 py-3.5">
                    {getBadge(event.event_name)}
                  </td>
                  <td className="px-5 py-3.5">
                    <button
                      type="button"
                      onClick={() => applyUserFilter(event.user)}
                      aria-label={`Filter by user ${displayUserName(event.user)}`}
                      className="cursor-pointer rounded text-left underline-offset-2 transition hover:text-indigo-600 hover:underline focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-500"
                    >
                      <div className="text-sm font-medium text-slate-700">{event.user.name}</div>
                      <div className="text-xs text-slate-400">{event.user.email}</div>
                    </button>
                  </td>
                  <td className="px-5 py-3.5 text-sm text-slate-600">
                    {event.project ? (
                      <button
                        type="button"
                        onClick={() => applyProjectFilter(event.project!)}
                        aria-label={`Filter by project ${event.project.name}`}
                        className="cursor-pointer rounded text-left underline-offset-2 transition hover:text-indigo-600 hover:underline focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-500"
                      >
                        {event.project.name}
                      </button>
                    ) : (
                      '—'
                    )}
                  </td>
                  <td className="px-5 py-3.5 text-sm text-slate-600">
                    {event.task?.name ?? '—'}
                  </td>
                  <td className="px-5 py-3.5">
                    <span className="inline-flex items-center rounded-full bg-slate-500/15 px-2 py-0.5 text-xs font-medium text-slate-400 ring-1 ring-slate-500/30">
                      {CATEGORY_LABELS[event.feature_category] ?? event.feature_category}
                    </span>
                  </td>
                </tr>
              ))
            ) : loading ? (
              <tr>
                <td colSpan={6} className="px-5 py-8 text-center text-sm text-slate-400">
                  Loading...
                </td>
              </tr>
            ) : (
              <tr>
                <td colSpan={6} className="px-5 py-8 text-center text-sm text-slate-400">
                  {hasAnyFilter ? (
                    <div className="space-y-2">
                      <p>No events match the active filters.</p>
                      <button
                        type="button"
                        onClick={clearAllFilters}
                        className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:bg-slate-50"
                      >
                        Clear all filters
                      </button>
                    </div>
                  ) : (
                    'No events found'
                  )}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {meta.total_pages > 1 && (
        <div className="flex items-center justify-between">
          <p className="text-xs text-slate-400">
            Showing {((meta.page - 1) * meta.per_page) + 1}–{Math.min(meta.page * meta.per_page, meta.total_count)} of {meta.total_count}
          </p>
          <div className="flex gap-2">
            <button
              className="rounded-md border border-slate-200 px-3 py-1.5 text-xs font-medium text-slate-600 transition hover:bg-slate-50 disabled:opacity-50"
              disabled={meta.page <= 1}
              onClick={() => setPage(meta.page - 1)}
            >
              Previous
            </button>
            <span className="flex items-center px-2 text-xs text-slate-500">
              {meta.page} / {meta.total_pages}
            </span>
            <button
              className="rounded-md border border-slate-200 px-3 py-1.5 text-xs font-medium text-slate-600 transition hover:bg-slate-50 disabled:opacity-50"
              disabled={meta.page >= meta.total_pages}
              onClick={() => setPage(meta.page + 1)}
            >
              Next
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
