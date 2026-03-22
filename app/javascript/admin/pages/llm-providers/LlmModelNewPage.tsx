import { FormEvent, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { llmModelsApi, CreateLlmModelInput } from '../../lib/api'

export const LlmModelNewPage = () => {
  const { id } = useParams<{ id: string }>()
  const providerId = Number(id)
  const navigate = useNavigate()

  const [name, setName] = useState('')
  const [displayName, setDisplayName] = useState('')
  const [active, setActive] = useState(true)
  const [defaultModel, setDefaultModel] = useState(false)
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setSubmitting(true)
    setError('')

    const data: CreateLlmModelInput = {
      name,
      display_name: displayName,
      active,
      default_model: defaultModel,
    }

    try {
      await llmModelsApi.create(providerId, data)
      navigate(`/admin/llm-providers/${providerId}/models`)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create model')
      setSubmitting(false)
    }
  }

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div className="flex items-end justify-between">
        <div>
          <p className="text-[10px] font-semibold tracking-[0.2em] text-slate-400" style={{ fontFamily: 'DM Mono, monospace' }}>AI INFRASTRUCTURE</p>
          <h1 className="text-2xl font-bold text-slate-800" style={{ fontFamily: 'Syne, sans-serif' }}>New LLM Model</h1>
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
            <Link
              to={`/admin/llm-providers/${providerId}/models`}
              className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:bg-slate-50"
            >
              Cancel
            </Link>
            <button
              type="submit"
              disabled={submitting}
              className="rounded-lg bg-[#6366f1] px-4 py-2 text-sm font-medium text-white shadow-md shadow-indigo-500/20 transition hover:bg-[#5558e8]"
            >
              {submitting ? 'Creating...' : 'Create'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
