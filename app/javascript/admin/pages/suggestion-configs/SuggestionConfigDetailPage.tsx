import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { SuggestionConfig, suggestionConfigsApi } from '../../lib/api'
import Badge from '../../components/Badge'

export const SuggestionConfigDetailPage = () => {
  const { id } = useParams<{ id: string }>()
  const [config, setConfig] = useState<SuggestionConfig | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    suggestionConfigsApi.get(Number(id))
      .then(setConfig)
      .catch(err => setError(err.message))
      .finally(() => setLoading(false))
  }, [id])

  if (loading) return <p className="text-sm text-slate-400">Loading…</p>
  if (!config) return <p className="text-sm text-rose-500">{error || 'Not found'}</p>

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-end justify-between">
        <div>
          <p className="text-[10px] font-semibold uppercase tracking-[0.2em] text-slate-400" style={{ fontFamily: 'DM Mono, monospace' }}>
            SUGGESTION CONFIGS
          </p>
          <h1 className="mt-1 text-2xl font-bold text-slate-800" style={{ fontFamily: 'Syne, sans-serif' }}>
            Config #{config.id}
          </h1>
        </div>
        <Link
          to="/admin/suggestion-configs"
          className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition-colors hover:bg-slate-50"
        >
          Back to list
        </Link>
      </div>

      {/* Info */}
      <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <tbody>
            <tr className="border-b border-slate-100">
              <th scope="row" className="w-36 px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">
                Status
              </th>
              <td className="px-5 py-3.5 text-sm text-slate-700">
                <Badge variant={config.active ? 'success' : 'neutral'}>
                  {config.active ? 'Active' : 'Inactive'}
                </Badge>
              </td>
            </tr>
            <tr className="border-b border-slate-100">
              <th scope="row" className="w-36 px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">
                Created
              </th>
              <td className="px-5 py-3.5 text-sm text-slate-700">
                {new Date(config.created_at).toLocaleString()}
              </td>
            </tr>
            <tr className="border-b border-slate-100 last:border-0">
              <th scope="row" className="w-36 px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">
                Entries
              </th>
              <td className="px-5 py-3.5 text-sm text-slate-700">
                {config.entries.length} entr{config.entries.length !== 1 ? 'ies' : 'y'}
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      {/* Entries */}
      <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
        <div className="border-b border-slate-100 px-5 py-3.5">
          <h2 className="text-sm font-semibold text-slate-700">Configuration Entries</h2>
        </div>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr className="border-b border-slate-100">
              <th className="px-5 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Model</th>
              <th className="px-5 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Prompt Set</th>
              <th className="px-5 py-3 text-right text-xs font-semibold uppercase tracking-wider text-slate-400">Weight</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-50">
            {config.entries.map(entry => (
              <tr key={entry.id} className="transition-colors hover:bg-slate-50/50">
                <td className="px-5 py-3.5 text-sm text-slate-700">
                  {entry.llm_model.display_name || entry.llm_model.name}
                </td>
                <td className="px-5 py-3.5 text-sm text-slate-700">
                  {entry.prompt_set.name}
                </td>
                <td className="px-5 py-3.5 text-right text-sm font-medium text-slate-700">
                  {entry.weight}%
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
