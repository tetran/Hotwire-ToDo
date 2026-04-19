import { useEffect, useState } from 'react'
import { Link, useLocation, useNavigate, useParams } from 'react-router-dom'
import { llmProvidersApi, llmModelsApi, LlmProvider, LlmModel } from '../../lib/api'
import Badge from '../../components/Badge'
import { AdminBackLink } from '../../components/AdminBackLink'

export const LlmProviderWorkspacePage = () => {
  const { id } = useParams<{ id: string }>()
  const providerId = Number(id)
  const navigate = useNavigate()
  const location = useLocation()

  const [provider, setProvider] = useState<LlmProvider | null>(null)
  const [models, setModels] = useState<LlmModel[]>([])
  const [error, setError] = useState('')
  const [refreshKey, setRefreshKey] = useState(0)

  // Flash message from location.state (e.g. after save/create)
  const flash = (location.state as { flash?: string } | null)?.flash ?? null

  // Clear location.state after first mount to prevent re-display on back navigation.
  // Capturing pathname and hasFlash as primitives avoids stale-closure re-runs.
  // Note: location.state currently only carries `flash`. If additional keys are added
  // in the future, use `{ ...location.state, flash: undefined }` instead of `null`.
  const hasFlash = flash !== null
  const pathname = location.pathname
  useEffect(() => {
    if (hasFlash) {
      navigate(pathname, { replace: true, state: null })
    }
  }, [hasFlash, pathname, navigate])

  useEffect(() => {
    const controller = new AbortController()

    Promise.all([
      llmProvidersApi.get(providerId, { signal: controller.signal }),
      llmModelsApi.list(providerId, { signal: controller.signal }),
    ])
      .then(([providerData, modelsResponse]) => {
        if (!controller.signal.aborted) {
          setProvider(providerData)
          setModels(modelsResponse.llm_models)
        }
      })
      .catch(err => {
        if (!controller.signal.aborted) {
          setError(err instanceof Error ? err.message : 'Failed to load workspace')
        }
      })

    return () => controller.abort()
  }, [providerId, refreshKey])

  const handleDeleteModel = async (modelId: number) => {
    if (!window.confirm('Are you sure you want to delete this model?')) return
    try {
      await llmModelsApi.delete(providerId, modelId)
      setRefreshKey(k => k + 1)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete model')
    }
  }

  if (error && !provider) {
    return (
      <div className="rounded-lg border border-rose-500/30 bg-rose-500/10 px-4 py-3 text-sm text-rose-400">
        {error}
      </div>
    )
  }
  if (!provider) return <p>Loading...</p>

  return (
    <div className="space-y-6">
      <AdminBackLink to="/admin/llm-providers" label="LLM Providers" />

      {/* Page header */}
      <div className="flex items-end justify-between">
        <div>
          <p className="text-[10px] font-semibold tracking-[0.2em] text-slate-400" style={{ fontFamily: 'DM Mono, monospace' }}>AI INFRASTRUCTURE</p>
          <h1 className="text-2xl font-bold text-slate-800" style={{ fontFamily: 'Syne, sans-serif' }}>LLM Provider: {provider.name}</h1>
        </div>
      </div>

      {/* Success flash banner */}
      {flash && (
        <div className="rounded-lg border border-emerald-500/30 bg-emerald-500/15 px-4 py-3 text-sm text-emerald-400">
          {flash}
        </div>
      )}

      {error && (
        <div className="rounded-lg border border-rose-500/30 bg-rose-500/10 px-4 py-3 text-sm text-rose-400">
          {error}
        </div>
      )}

      {/* Provider Info card */}
      <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
        <div className="flex items-center justify-between border-b border-slate-100 px-5 py-4">
          <h2 className="text-sm font-semibold text-slate-700" style={{ fontFamily: 'Syne, sans-serif' }}>Provider Info</h2>
          <Link
            to={`/admin/llm-providers/${provider.id}/edit`}
            data-testid="workspace-provider-edit"
            className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:bg-slate-50"
          >
            Edit
          </Link>
        </div>
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

      {/* Models section */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <h2 className="text-sm font-semibold text-slate-700" style={{ fontFamily: 'Syne, sans-serif' }}>Models</h2>
          <Link
            to={`/admin/llm-providers/${provider.id}/models/new`}
            className="rounded-lg bg-[#6366f1] px-4 py-2 text-sm font-medium text-white shadow-md shadow-indigo-500/20 transition hover:bg-[#5558e8]"
          >
            + New Model
          </Link>
        </div>

        <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr className="border-b border-slate-100">
                <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">ID</th>
                <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Name</th>
                <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Display Name</th>
                <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Active</th>
                <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Default</th>
                <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {models.length === 0 && (
                <tr>
                  <td colSpan={6} className="px-5 py-10 text-center text-sm text-slate-400">
                    No models configured for this provider yet.
                  </td>
                </tr>
              )}
              {models.map(model => (
                <tr key={model.id} className="transition-colors hover:bg-slate-50/50">
                  <td className="px-5 py-3.5 text-sm text-slate-700" style={{ fontFamily: 'DM Mono, monospace' }}>{model.id}</td>
                  <td className="px-5 py-3.5 text-sm text-slate-700">{model.name}</td>
                  <td className="px-5 py-3.5 text-sm text-slate-700">{model.display_name}</td>
                  <td className="px-5 py-3.5 text-sm text-slate-700">
                    {model.active
                      ? <Badge variant="success">Active</Badge>
                      : <Badge variant="neutral">Inactive</Badge>
                    }
                  </td>
                  <td className="px-5 py-3.5 text-sm text-slate-700">
                    {model.default_model
                      ? <Badge variant="info">Default</Badge>
                      : <Badge variant="neutral">-</Badge>
                    }
                  </td>
                  <td className="px-5 py-3.5 text-sm text-slate-700">
                    <div className="flex items-center gap-2">
                      <Link
                        to={`/admin/llm-providers/${providerId}/models/${model.id}/edit`}
                        className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:bg-slate-50"
                      >
                        Edit
                      </Link>
                      <button
                        onClick={() => handleDeleteModel(model.id)}
                        className="rounded-md border border-rose-200 px-2.5 py-1 text-xs font-medium text-rose-500 transition hover:bg-rose-50"
                      >
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
