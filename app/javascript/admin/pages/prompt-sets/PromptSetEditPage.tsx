import { FormEvent, useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { PromptInput, PromptSet, promptSetsApi } from '../../lib/api'

const VARIABLES = ['goal', 'context', 'due_date', 'start_date']

interface PromptRow {
  key: number
  id?: number
  role: 'system' | 'user'
  body: string
  position: number
  _destroy?: boolean
}

let nextKey = 1

export const PromptSetEditPage = () => {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [promptSet, setPromptSet] = useState<PromptSet | null>(null)
  const [name, setName] = useState('')
  const [active, setActive] = useState(true)
  const [prompts, setPrompts] = useState<PromptRow[]>([])
  const [inUse, setInUse] = useState(false)
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    promptSetsApi.get(Number(id))
      .then(data => {
        setPromptSet(data)
        setName(data.name)
        setActive(data.active)
        setInUse(data.in_use ?? false)
        setPrompts(data.prompts.map(p => ({
          key: nextKey++,
          id: p.id,
          role: p.role,
          body: p.body,
          position: p.position,
        })))
      })
      .catch(err => setError(err.message))
      .finally(() => setLoading(false))
  }, [id])

  const addPrompt = () => {
    setPrompts(prev => [...prev, {
      key: nextKey++,
      role: 'system',
      body: '',
      position: prev.length + 1,
    }])
  }

  const removePrompt = (key: number) => {
    setPrompts(prev => {
      const updated = prev.map(p =>
        p.key === key ? { ...p, _destroy: true } : p
      )
      let pos = 1
      return updated.map(p => p._destroy ? p : { ...p, position: pos++ })
    })
  }

  const updatePrompt = (key: number, field: keyof PromptRow, value: string | number) => {
    setPrompts(prev => prev.map(p => p.key === key ? { ...p, [field]: value } : p))
  }

  const insertVariable = (key: number, variable: string) => {
    setPrompts(prev => prev.map(p =>
      p.key === key ? { ...p, body: p.body + `{{${variable}}}` } : p
    ))
  }

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()

    if (inUse && !window.confirm(
      'This prompt set is used in an active suggestion config. Changes will take effect immediately. Continue?'
    )) return

    setSubmitting(true)
    setError('')

    const prompts_attributes: PromptInput[] = prompts.map(p => ({
      ...(p.id ? { id: p.id } : {}),
      role: p.role,
      body: p.body,
      position: p.position,
      ...(p._destroy ? { _destroy: true } : {}),
    }))

    try {
      await promptSetsApi.update(Number(id), { name, active, prompts_attributes })
      navigate('/admin/prompt-sets')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update prompt set')
      setSubmitting(false)
    }
  }

  if (loading) return <p className="text-sm text-slate-400">Loading…</p>
  if (!promptSet) return <p className="text-sm text-rose-500">{error || 'Not found'}</p>

  const livePrompts = prompts.filter(p => !p._destroy)

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <p className="text-[10px] font-semibold uppercase tracking-[0.2em] text-slate-400" style={{ fontFamily: 'DM Mono, monospace' }}>
          PROMPT SETS
        </p>
        <h1 className="mt-1 text-2xl font-bold text-slate-800" style={{ fontFamily: 'Syne, sans-serif' }}>
          Edit Prompt Set
        </h1>
      </div>

      {inUse && (
        <div className="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-700">
          ⚠ This prompt set is used in an active suggestion config. Changes will take effect immediately.
        </div>
      )}

      {error && (
        <div className="rounded-lg border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-600">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Name & Active */}
        <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
          <div className="space-y-4">
            <div className="space-y-1">
              <label className="text-xs font-semibold uppercase tracking-wider text-slate-500">Name</label>
              <input
                type="text"
                value={name}
                onChange={e => setName(e.target.value)}
                required
                className="block w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/30"
              />
            </div>
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={active}
                onChange={e => setActive(e.target.checked)}
                className="rounded border-slate-300"
              />
              <span className="text-sm text-slate-600">Active</span>
            </label>
          </div>
        </div>

        {/* Prompts */}
        <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
          <div className="mb-4 flex items-center justify-between">
            <h2 className="text-sm font-semibold text-slate-700">Prompts</h2>
            <button
              type="button"
              onClick={addPrompt}
              className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition-colors hover:bg-slate-50"
            >
              + Add Prompt
            </button>
          </div>

          <div className="space-y-4">
            {livePrompts.map(prompt => (
              <div key={prompt.key} className="rounded-lg border border-slate-100 bg-slate-50/50 p-4">
                <div className="mb-3 flex items-center gap-3">
                  <span className="text-xs font-medium text-slate-400">#{prompt.position}</span>
                  <select
                    value={prompt.role}
                    onChange={e => updatePrompt(prompt.key, 'role', e.target.value)}
                    className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm outline-none focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/30"
                  >
                    <option value="system">System</option>
                    <option value="user">User</option>
                  </select>
                  <div className="flex-1" />
                  {livePrompts.length > 1 && (
                    <button
                      type="button"
                      onClick={() => removePrompt(prompt.key)}
                      className="text-xs text-rose-400 transition-colors hover:text-rose-600"
                    >
                      Remove
                    </button>
                  )}
                </div>
                <textarea
                  value={prompt.body}
                  onChange={e => updatePrompt(prompt.key, 'body', e.target.value)}
                  required
                  rows={4}
                  maxLength={1000}
                  className="block w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/30"
                  placeholder="Enter prompt body…"
                />
                <div className="mt-2 flex items-center gap-1.5">
                  <span className="text-[10px] text-slate-400">Variables:</span>
                  {VARIABLES.map(v => (
                    <button
                      key={v}
                      type="button"
                      onClick={() => insertVariable(prompt.key, v)}
                      className="rounded border border-slate-200 px-1.5 py-0.5 text-[10px] font-medium text-slate-500 transition-colors hover:bg-slate-100"
                    >
                      {`{{${v}}}`}
                    </button>
                  ))}
                </div>
                <p className="mt-1 text-right text-[10px] text-slate-400">{prompt.body.length}/1000</p>
              </div>
            ))}
          </div>
        </div>

        {/* Actions */}
        <div className="flex justify-end gap-3">
          <Link
            to="/admin/prompt-sets"
            className="rounded-lg border border-slate-200 px-4 py-2 text-sm font-medium text-slate-600 transition-colors hover:bg-slate-50"
          >
            Cancel
          </Link>
          <button
            type="submit"
            disabled={submitting}
            className="rounded-lg bg-[#6366f1] px-4 py-2 text-sm font-medium text-white shadow-md shadow-indigo-500/20 transition-colors hover:bg-[#5558e8] disabled:opacity-50"
          >
            {submitting ? 'Saving…' : 'Save Changes'}
          </button>
        </div>
      </form>
    </div>
  )
}
