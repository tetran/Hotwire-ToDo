import { FormEvent, useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { LlmModel, LlmProvider, PromptSet, llmModelsApi, llmProvidersApi, promptSetsApi, suggestionConfigsApi } from '../../lib/api'

interface EntryRow {
  key: number
  llm_model_id: string
  prompt_set_id: string
  weight: string
}

let nextKey = 1

const MAX_ENTRIES = 3

export const SuggestionConfigNewPage = () => {
  const navigate = useNavigate()
  const [entries, setEntries] = useState<EntryRow[]>([{ key: nextKey++, llm_model_id: '', prompt_set_id: '', weight: '100' }])
  const [models, setModels] = useState<LlmModel[]>([])
  const [promptSets, setPromptSets] = useState<PromptSet[]>([])
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    const loadData = async () => {
      try {
        const [providers, ps] = await Promise.all([
          llmProvidersApi.list(),
          promptSetsApi.list(),
        ])
        const activeProviders = providers.filter((p: LlmProvider) => p.active)
        const allModels = await Promise.all(
          activeProviders.map((p: LlmProvider) => llmModelsApi.list(p.id))
        )
        setModels(allModels.flat().filter((m: LlmModel) => m.active))
        setPromptSets(ps.filter((p: PromptSet) => p.active))
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load data')
      }
    }
    loadData()
  }, [])

  const weightsTotal = entries.reduce((sum, e) => sum + (Number(e.weight) || 0), 0)

  const addEntry = () => {
    if (entries.length >= MAX_ENTRIES) return
    setEntries(prev => [...prev, { key: nextKey++, llm_model_id: '', prompt_set_id: '', weight: '' }])
  }

  const removeEntry = (key: number) => {
    setEntries(prev => prev.filter(e => e.key !== key))
  }

  const updateEntry = (key: number, field: keyof EntryRow, value: string) => {
    setEntries(prev => prev.map(e => e.key === key ? { ...e, [field]: value } : e))
  }

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setSubmitting(true)
    setError('')

    const entries_attributes = entries.map(entry => ({
      llm_model_id: Number(entry.llm_model_id),
      prompt_set_id: Number(entry.prompt_set_id),
      weight: Number(entry.weight),
    }))

    try {
      await suggestionConfigsApi.create({ entries_attributes })
      navigate('/admin/suggestion-configs')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create config')
      setSubmitting(false)
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <p className="text-[10px] font-semibold uppercase tracking-[0.2em] text-slate-400" style={{ fontFamily: 'DM Mono, monospace' }}>
          SUGGESTION CONFIGS
        </p>
        <h1 className="mt-1 text-2xl font-bold text-slate-800" style={{ fontFamily: 'Syne, sans-serif' }}>
          New Suggestion Config
        </h1>
      </div>

      {error && (
        <div className="rounded-lg border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-600">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
          <div className="mb-4 flex items-center justify-between">
            <h2 className="text-sm font-semibold text-slate-700">Entries</h2>
            <div className="flex items-center gap-3">
              <span className={`text-xs font-medium ${weightsTotal === 100 ? 'text-emerald-600' : 'text-rose-500'}`}>
                Total: {weightsTotal}%{weightsTotal !== 100 && ' (must be 100%)'}
              </span>
              {entries.length < MAX_ENTRIES && (
                <button
                  type="button"
                  onClick={addEntry}
                  className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition-colors hover:bg-slate-50"
                >
                  + Add Entry
                </button>
              )}
            </div>
          </div>

          <div className="space-y-4">
            {entries.map((entry, idx) => (
              <div key={entry.key} className="rounded-lg border border-slate-100 bg-slate-50/50 p-4">
                <div className="mb-3 flex items-center justify-between">
                  <span className="text-xs font-medium text-slate-400">Entry #{idx + 1}</span>
                  {entries.length > 1 && (
                    <button
                      type="button"
                      onClick={() => removeEntry(entry.key)}
                      className="text-xs text-rose-400 transition-colors hover:text-rose-600"
                    >
                      Remove
                    </button>
                  )}
                </div>
                <div className="grid grid-cols-3 gap-4">
                  <div className="space-y-1">
                    <label className="text-xs font-semibold uppercase tracking-wider text-slate-500">Model</label>
                    <select
                      value={entry.llm_model_id}
                      onChange={e => updateEntry(entry.key, 'llm_model_id', e.target.value)}
                      required
                      className="block w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/30"
                    >
                      <option value="">Select model…</option>
                      {models.map(m => (
                        <option key={m.id} value={m.id}>{m.display_name || m.name}</option>
                      ))}
                    </select>
                  </div>
                  <div className="space-y-1">
                    <label className="text-xs font-semibold uppercase tracking-wider text-slate-500">Prompt Set</label>
                    <select
                      value={entry.prompt_set_id}
                      onChange={e => updateEntry(entry.key, 'prompt_set_id', e.target.value)}
                      required
                      className="block w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/30"
                    >
                      <option value="">Select prompt set…</option>
                      {promptSets.map(ps => (
                        <option key={ps.id} value={ps.id}>{ps.name}</option>
                      ))}
                    </select>
                  </div>
                  <div className="space-y-1">
                    <label className="text-xs font-semibold uppercase tracking-wider text-slate-500">Weight (%)</label>
                    <input
                      type="number"
                      min="1"
                      max="100"
                      value={entry.weight}
                      onChange={e => updateEntry(entry.key, 'weight', e.target.value)}
                      required
                      className="block w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/30"
                    />
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="flex justify-end gap-3">
          <Link
            to="/admin/suggestion-configs"
            className="rounded-lg border border-slate-200 px-4 py-2 text-sm font-medium text-slate-600 transition-colors hover:bg-slate-50"
          >
            Cancel
          </Link>
          <button
            type="submit"
            disabled={submitting || weightsTotal !== 100}
            className="rounded-lg bg-[#6366f1] px-4 py-2 text-sm font-medium text-white shadow-md shadow-indigo-500/20 transition-colors hover:bg-[#5558e8] disabled:opacity-50"
          >
            {submitting ? 'Creating…' : 'Create Config'}
          </button>
        </div>
      </form>

      <p className="text-xs text-slate-400">
        Creating a new config will automatically deactivate the currently active config.
      </p>
    </div>
  )
}
