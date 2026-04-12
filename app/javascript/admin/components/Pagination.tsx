import type { PaginationMeta } from '../lib/api'
import { PER_PAGE_OPTIONS } from '../hooks/usePagination'

export interface PaginationProps {
  meta: PaginationMeta
  page: number
  perPage: number
  onPageChange: (page: number) => void
  onPerPageChange: (perPage: number) => void
}

export default function Pagination({ meta, page, perPage, onPageChange, onPerPageChange }: PaginationProps) {
  if (meta.total_count === 0) return null

  const start = (page - 1) * perPage + 1
  const end = Math.min(page * perPage, meta.total_count)

  return (
    <div className="flex flex-wrap items-center justify-between gap-3">
      <p className="text-xs text-slate-400">
        Showing {start}–{end} of {meta.total_count}
      </p>
      <div className="flex items-center gap-2">
        <select
          value={perPage}
          onChange={e => onPerPageChange(Number(e.target.value))}
          className="rounded-md border border-slate-200 bg-white px-2 py-1 text-xs font-medium text-slate-600 transition hover:bg-slate-50"
          aria-label="Rows per page"
        >
          {PER_PAGE_OPTIONS.map(n => (
            <option key={n} value={n}>{n} / page</option>
          ))}
        </select>
        <button
          type="button"
          onClick={() => onPageChange(page - 1)}
          disabled={page <= 1}
          className="rounded-md border border-slate-200 px-3 py-1.5 text-xs font-medium text-slate-600 transition hover:bg-slate-50 disabled:opacity-50"
        >
          Previous
        </button>
        <span className="flex items-center px-2 text-xs text-slate-500">
          {page} / {meta.total_pages}
        </span>
        <button
          type="button"
          onClick={() => onPageChange(page + 1)}
          disabled={page >= meta.total_pages}
          className="rounded-md border border-slate-200 px-3 py-1.5 text-xs font-medium text-slate-600 transition hover:bg-slate-50 disabled:opacity-50"
        >
          Next
        </button>
      </div>
    </div>
  )
}
