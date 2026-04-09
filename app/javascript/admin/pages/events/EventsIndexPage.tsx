import { useState, useEffect, useCallback } from 'react'
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

export const EventsIndexPage = () => {
  const [events, setEvents] = useState<EventLog[]>([])
  const [meta, setMeta] = useState<EventLogMeta>({ page: 1, per_page: 25, total_count: 0, total_pages: 0 })
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [filters, setFilters] = useState<EventLogListParams>({ page: 1 })

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

  const updateFilter = (key: keyof EventLogListParams, value: string) => {
    setFilters(prev => ({ ...prev, [key]: value || undefined, page: 1 }))
  }

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
      </div>

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
          <tbody className="divide-y divide-slate-50">
            {loading ? (
              <tr>
                <td colSpan={6} className="px-5 py-8 text-center text-sm text-slate-400">
                  Loading...
                </td>
              </tr>
            ) : events.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-5 py-8 text-center text-sm text-slate-400">
                  No events found
                </td>
              </tr>
            ) : (
              events.map(event => (
                <tr key={event.id} className="transition-colors hover:bg-slate-50/50">
                  <td className="px-5 py-3.5 text-xs text-slate-500">
                    {formatDate(event.occurred_at)}
                  </td>
                  <td className="px-5 py-3.5">
                    {getBadge(event.event_name)}
                  </td>
                  <td className="px-5 py-3.5">
                    <div className="text-sm font-medium text-slate-700">{event.user.name}</div>
                    <div className="text-xs text-slate-400">{event.user.email}</div>
                  </td>
                  <td className="px-5 py-3.5 text-sm text-slate-600">
                    {event.project?.name ?? '—'}
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
              onClick={() => setFilters(prev => ({ ...prev, page: (prev.page ?? 1) - 1 }))}
            >
              Previous
            </button>
            <span className="flex items-center px-2 text-xs text-slate-500">
              {meta.page} / {meta.total_pages}
            </span>
            <button
              className="rounded-md border border-slate-200 px-3 py-1.5 text-xs font-medium text-slate-600 transition hover:bg-slate-50 disabled:opacity-50"
              disabled={meta.page >= meta.total_pages}
              onClick={() => setFilters(prev => ({ ...prev, page: (prev.page ?? 1) + 1 }))}
            >
              Next
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
