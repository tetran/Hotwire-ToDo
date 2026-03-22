import { FormEvent, useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { llmProvidersApi, LlmProvider, UpdateLlmProviderInput } from '../../lib/api'

export const LlmProviderEditPage = () => {
  const { id } = useParams<{ id: string }>()
  const providerId = Number(id)
  const navigate = useNavigate()

  const [provider, setProvider] = useState<LlmProvider | null>(null)
  const [name, setName] = useState('')
  const [apiEndpoint, setApiEndpoint] = useState('')
  const [organizationId, setOrganizationId] = useState('')
  const [active, setActive] = useState(true)
  const [apiKey, setApiKey] = useState('')
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)

  useEffect(() => {
    llmProvidersApi.get(providerId)
      .then(data => {
        setProvider(data)
        setName(data.name)
        setApiEndpoint(data.api_endpoint ?? '')
        setOrganizationId(data.organization_id ?? '')
        setActive(data.active)
      })
      .catch(err => setError(err instanceof Error ? err.message : 'Failed to load provider'))
  }, [providerId])

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setSubmitting(true)
    setError('')

    const data: UpdateLlmProviderInput = {
      name,
      api_endpoint: apiEndpoint,
      organization_id: organizationId,
      active,
    }
    if (apiKey !== '') {
      data.api_key = apiKey
    }

    try {
      await llmProvidersApi.update(providerId, data)
      navigate('/admin/llm-providers')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update provider')
      setSubmitting(false)
    }
  }

  if (error && !provider) return (
    <div className="rounded-lg border border-rose-500/30 bg-rose-500/10 px-4 py-3 text-sm text-rose-400">
      {error}
    </div>
  )
  if (!provider) return <p>Loading...</p>

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div className="flex items-end justify-between">
        <div>
          <p className="text-[10px] font-semibold tracking-[0.2em] text-slate-400" style={{ fontFamily: 'DM Mono, monospace' }}>AI INFRASTRUCTURE</p>
          <h1 className="text-2xl font-bold text-slate-800" style={{ fontFamily: 'Syne, sans-serif' }}>Edit LLM Provider</h1>
        </div>
      </div>

      {error && (
        <div className="rounded-lg border border-rose-500/30 bg-rose-500/10 px-4 py-3 text-sm text-rose-400">
          {error}
        </div>
      )}

      {/* Form card */}
      <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <form onSubmit={handleSubmit}>
          <div className="space-y-4">
            <div className="space-y-1">
              <label htmlFor="name" className="text-xs font-medium text-slate-600">Name</label>
              <input
                id="name"
                type="text"
                value={name}
                onChange={e => setName(e.target.value)}
                required
                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none transition focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/30"
              />
            </div>
            <div className="space-y-1">
              <label htmlFor="api_endpoint" className="text-xs font-medium text-slate-600">API Endpoint</label>
              <input
                id="api_endpoint"
                type="text"
                value={apiEndpoint}
                onChange={e => setApiEndpoint(e.target.value)}
                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none transition focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/30"
              />
            </div>
            <div className="space-y-1">
              <label htmlFor="organization_id" className="text-xs font-medium text-slate-600">Organization ID</label>
              <input
                id="organization_id"
                type="text"
                value={organizationId}
                onChange={e => setOrganizationId(e.target.value)}
                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none transition focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/30"
              />
            </div>
            <div className="space-y-1">
              <label htmlFor="api_key" className="text-xs font-medium text-slate-600">API Key (leave blank to keep current)</label>
              <input
                id="api_key"
                type="password"
                value={apiKey}
                onChange={e => setApiKey(e.target.value)}
                placeholder="Enter new API key to change"
                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none transition focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/30"
              />
            </div>
            <div>
              <label className="flex items-center gap-2 text-sm text-slate-700 cursor-pointer">
                <input
                  type="checkbox"
                  checked={active}
                  onChange={e => setActive(e.target.checked)}
                  className="rounded border-slate-300 text-[#6366f1]"
                />
                Active
              </label>
            </div>
          </div>

          <div className="mt-6 flex items-center justify-end gap-2">
            <Link
              to="/admin/llm-providers"
              className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:bg-slate-50"
            >
              Cancel
            </Link>
            <button
              type="submit"
              disabled={submitting}
              className="rounded-lg bg-[#6366f1] px-4 py-2 text-sm font-medium text-white shadow-md shadow-indigo-500/20 transition hover:bg-[#5558e8]"
            >
              {submitting ? 'Saving...' : 'Save'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
