import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { PromptSet, promptSetsApi, type PaginationMeta } from '../../lib/api'
import Badge from '../../components/Badge'
import Pagination from '../../components/Pagination'
import { usePagination, useClampPage } from '../../hooks/usePagination'

export const PromptSetsIndexPage = () => {
  const [promptSets, setPromptSets] = useState<PromptSet[]>([])
  const [meta, setMeta] = useState<PaginationMeta | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  const { page, perPage, setPage, setPerPage, clampPage } = usePagination()
  useClampPage(meta, clampPage)

  useEffect(() => {
    const controller = new AbortController()
    setLoading(true)
    promptSetsApi.list({ page, per_page: perPage }, { signal: controller.signal })
      .then(response => {
        if (!controller.signal.aborted) {
          setPromptSets(response.prompt_sets)
          setMeta(response.meta)
        }
      })
      .catch(err => {
        if (!controller.signal.aborted) setError(err.message)
      })
      .finally(() => {
        if (!controller.signal.aborted) setLoading(false)
      })
    return () => controller.abort()
  }, [page, perPage])

  if (loading) return <p className="text-sm text-slate-400">Loading…</p>
  if (error) return <p className="text-sm text-rose-500">{error}</p>

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-end justify-between">
        <div>
          <p className="text-[10px] font-semibold uppercase tracking-[0.2em] text-slate-400" style={{ fontFamily: 'DM Mono, monospace' }}>
            AI INFRASTRUCTURE
          </p>
          <h1 className="mt-1 text-2xl font-bold text-slate-800" style={{ fontFamily: 'Syne, sans-serif' }}>
            Prompt Sets
          </h1>
        </div>
        <Link
          to="/admin/prompt-sets/new"
          className="rounded-lg bg-[#6366f1] px-4 py-2 text-sm font-medium text-white shadow-md shadow-indigo-500/20 transition-colors hover:bg-[#5558e8]"
        >
          New Prompt Set
        </Link>
      </div>

      {/* Table */}
      <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr className="border-b border-slate-100">
              <th className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Name</th>
              <th className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Prompts</th>
              <th className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Status</th>
              <th className="px-5 py-3.5 text-right text-xs font-semibold uppercase tracking-wider text-slate-400">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-50">
            {promptSets.map(ps => (
              <tr key={ps.id} className="transition-colors hover:bg-slate-50/50">
                <td className="px-5 py-3.5 text-sm font-medium text-slate-700">{ps.name}</td>
                <td className="px-5 py-3.5 text-sm text-slate-500">
                  {ps.prompts.length} prompt{ps.prompts.length !== 1 ? 's' : ''}
                </td>
                <td className="px-5 py-3.5">
                  <Badge variant={ps.active ? 'success' : 'neutral'}>
                    {ps.active ? 'Active' : 'Inactive'}
                  </Badge>
                </td>
                <td className="px-5 py-3.5 text-right">
                  <Link
                    to={`/admin/prompt-sets/${ps.id}/edit`}
                    className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition-colors hover:bg-slate-50"
                  >
                    Edit
                  </Link>
                </td>
              </tr>
            ))}
            {promptSets.length === 0 && (
              <tr>
                <td colSpan={4} className="px-5 py-8 text-center text-sm text-slate-400">
                  No prompt sets yet. Create your first one.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {meta && (
        <Pagination
          meta={meta}
          page={page}
          perPage={perPage}
          onPageChange={setPage}
          onPerPageChange={setPerPage}
        />
      )}
    </div>
  )
}
