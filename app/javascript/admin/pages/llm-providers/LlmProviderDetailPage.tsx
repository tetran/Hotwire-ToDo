import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { llmProvidersApi, LlmProvider } from '../../lib/api'
import Badge from '../../components/Badge'

export const LlmProviderDetailPage = () => {
  const { id } = useParams<{ id: string }>()
  const providerId = Number(id)

  const [provider, setProvider] = useState<LlmProvider | null>(null)
  const [error, setError] = useState('')

  useEffect(() => {
    llmProvidersApi.get(providerId)
      .then(setProvider)
      .catch(err => setError(err instanceof Error ? err.message : 'Failed to load provider'))
  }, [providerId])

  if (error) {
    return (
    <div className="rounded-lg border border-rose-500/30 bg-rose-500/10 px-4 py-3 text-sm text-rose-400">
      {error}
    </div>
    )
  }
  if (!provider) return <p>Loading...</p>

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div className="flex items-end justify-between">
        <div>
          <p className="text-[10px] font-semibold tracking-[0.2em] text-slate-400" style={{ fontFamily: 'DM Mono, monospace' }}>AI INFRASTRUCTURE</p>
          <h1 className="text-2xl font-bold text-slate-800" style={{ fontFamily: 'Syne, sans-serif' }}>LLM Provider: {provider.name}</h1>
        </div>
        <div className="flex items-center gap-2">
          <Link
            to={`/admin/llm-providers/${provider.id}/edit`}
            className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:bg-slate-50"
          >
            Edit
          </Link>
          <Link
            to={`/admin/llm-providers/${provider.id}/models`}
            className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:bg-slate-50"
          >
            Manage Models
          </Link>
          <Link
            to="/admin/llm-providers"
            className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:bg-slate-50"
          >
            Back to list
          </Link>
        </div>
      </div>

      {/* Provider info card */}
      <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <tbody>
            <tr className="border-b border-slate-100 last:border-0">
              <th scope="row" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400 w-36">ID</th>
              <td className="px-5 py-3.5 text-sm text-slate-700" style={{ fontFamily: 'DM Mono, monospace' }}>{provider.id}</td>
            </tr>
            <tr className="border-b border-slate-100 last:border-0">
              <th scope="row" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400 w-36">Name</th>
              <td className="px-5 py-3.5 text-sm text-slate-700">{provider.name}</td>
            </tr>
            <tr className="border-b border-slate-100 last:border-0">
              <th scope="row" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400 w-36">API Endpoint</th>
              <td className="px-5 py-3.5 text-sm text-slate-700">{provider.api_endpoint ?? '—'}</td>
            </tr>
            <tr className="border-b border-slate-100 last:border-0">
              <th scope="row" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400 w-36">Organization ID</th>
              <td className="px-5 py-3.5 text-sm text-slate-700">{provider.organization_id ?? '—'}</td>
            </tr>
            <tr className="border-b border-slate-100 last:border-0">
              <th scope="row" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400 w-36">API Key</th>
              <td className="px-5 py-3.5 text-sm text-slate-700" style={{ fontFamily: 'DM Mono, monospace' }}>***</td>
            </tr>
            <tr className="border-b border-slate-100 last:border-0">
              <th scope="row" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400 w-36">Active</th>
              <td className="px-5 py-3.5 text-sm text-slate-700">
                {provider.active
                  ? <Badge variant="success">Active</Badge>
                  : <Badge variant="neutral">Inactive</Badge>
                }
              </td>
            </tr>
            <tr className="border-b border-slate-100 last:border-0">
              <th scope="row" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400 w-36">Created At</th>
              <td className="px-5 py-3.5 text-sm text-slate-700">{provider.created_at}</td>
            </tr>
            <tr className="border-b border-slate-100 last:border-0">
              <th scope="row" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400 w-36">Updated At</th>
              <td className="px-5 py-3.5 text-sm text-slate-700">{provider.updated_at}</td>
            </tr>
          </tbody>
        </table>
      </div>

    </div>
  )
}
