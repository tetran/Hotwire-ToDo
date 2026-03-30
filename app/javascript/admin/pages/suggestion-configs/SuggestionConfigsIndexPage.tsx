import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { SuggestionConfig, suggestionConfigsApi } from '../../lib/api'
import Badge from '../../components/Badge'

export const SuggestionConfigsIndexPage = () => {
  const [configs, setConfigs] = useState<SuggestionConfig[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    suggestionConfigsApi.list()
      .then(setConfigs)
      .catch(err => setError(err.message))
      .finally(() => setLoading(false))
  }, [])

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
            Suggestion Configs
          </h1>
        </div>
        <Link
          to="/admin/suggestion-configs/new"
          className="rounded-lg bg-[#6366f1] px-4 py-2 text-sm font-medium text-white shadow-md shadow-indigo-500/20 transition-colors hover:bg-[#5558e8]"
        >
          New Config
        </Link>
      </div>

      {/* Table */}
      <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr className="border-b border-slate-100">
              <th className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">ID</th>
              <th className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Entries</th>
              <th className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Status</th>
              <th className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Created</th>
              <th className="px-5 py-3.5 text-right text-xs font-semibold uppercase tracking-wider text-slate-400">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-50">
            {configs.map(config => (
              <tr key={config.id} className="transition-colors hover:bg-slate-50/50">
                <td className="px-5 py-3.5 text-sm font-medium text-slate-700">#{config.id}</td>
                <td className="px-5 py-3.5 text-sm text-slate-500">
                  {config.entries.length} entr{config.entries.length !== 1 ? 'ies' : 'y'}
                </td>
                <td className="px-5 py-3.5">
                  <Badge variant={config.active ? 'success' : 'neutral'}>
                    {config.active ? 'Active' : 'Inactive'}
                  </Badge>
                </td>
                <td className="px-5 py-3.5 text-sm text-slate-500">
                  {new Date(config.created_at).toLocaleDateString()}
                </td>
                <td className="px-5 py-3.5 text-right">
                  <Link
                    to={`/admin/suggestion-configs/${config.id}`}
                    className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition-colors hover:bg-slate-50"
                  >
                    View
                  </Link>
                </td>
              </tr>
            ))}
            {configs.length === 0 && (
              <tr>
                <td colSpan={5} className="px-5 py-8 text-center text-sm text-slate-400">
                  No suggestion configs yet. Create your first one.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
