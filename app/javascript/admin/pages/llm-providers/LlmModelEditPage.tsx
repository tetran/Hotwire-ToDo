import { FormEvent, useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { llmModelsApi, LlmModel, UpdateLlmModelInput } from '../../lib/api'
import { AdminCancelButton } from '../../components/AdminCancelButton'

export const LlmModelEditPage = () => {
  const { id, modelId } = useParams<{ id: string; modelId: string }>()
  const providerId = Number(id)
  const llmModelId = Number(modelId)
  const navigate = useNavigate()

  const [model, setModel] = useState<LlmModel | null>(null)
  const [name, setName] = useState('')
  const [displayName, setDisplayName] = useState('')
  const [active, setActive] = useState(true)
  const [defaultModel, setDefaultModel] = useState(false)
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)

  useEffect(() => {
    llmModelsApi.get(providerId, llmModelId)
      .then(data => {
        setModel(data)
        setName(data.name)
        setDisplayName(data.display_name)
        setActive(data.active)
        setDefaultModel(data.default_model)
      })
      .catch(err => setError(err instanceof Error ? err.message : 'Failed to load model'))
  }, [providerId, llmModelId])

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setSubmitting(true)
    setError('')

    // name is intentionally excluded — it is read-only and must not be sent on update
    const data: UpdateLlmModelInput = {
      display_name: displayName,
      active,
      default_model: defaultModel,
    }

    try {
      await llmModelsApi.update(providerId, llmModelId, data)
      navigate(`/admin/llm-providers/${providerId}`, { state: { flash: 'Model updated' } })
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update model')
      setSubmitting(false)
    }
  }

  if (error && !model) {
    return (
    <div className="rounded-lg border border-rose-500/30 bg-rose-500/10 px-4 py-3 text-sm text-rose-400">
      {error}
    </div>
    )
  }
  if (!model) return <p>Loading...</p>

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div className="flex items-end justify-between">
        <div>
          <p className="text-[10px] font-semibold tracking-[0.2em] text-slate-400" style={{ fontFamily: 'DM Mono, monospace' }}>AI INFRASTRUCTURE</p>
          <h1 className="text-2xl font-bold text-slate-800" style={{ fontFamily: 'Syne, sans-serif' }}>Edit LLM Model</h1>
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
              <label htmlFor="name" className="flex items-center gap-1.5 text-xs font-medium text-slate-600">
                Name
                <span className="text-xs text-slate-400">(read-only)</span>
              </label>
              <input
                id="name"
                type="text"
                value={name}
                readOnly
                aria-readonly="true"
                className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm text-slate-500 outline-none cursor-not-allowed"
              />
            </div>
            <div className="space-y-1">
              <label htmlFor="display_name" className="text-xs font-medium text-slate-600">Display Name</label>
              <input
                id="display_name"
                type="text"
                value={displayName}
                onChange={e => setDisplayName(e.target.value)}
                required
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
            <div>
              <label className="flex items-center gap-2 text-sm text-slate-700 cursor-pointer">
                <input
                  type="checkbox"
                  checked={defaultModel}
                  onChange={e => setDefaultModel(e.target.checked)}
                  className="rounded border-slate-300 text-[#6366f1]"
                />
                Default Model
              </label>
            </div>
          </div>

          <div className="mt-6 flex items-center justify-end gap-2">
            <AdminCancelButton to={`/admin/llm-providers/${providerId}`} />
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
