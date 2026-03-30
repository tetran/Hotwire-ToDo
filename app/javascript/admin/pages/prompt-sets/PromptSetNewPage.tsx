import { FormEvent, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { PromptInput, promptSetsApi } from '../../lib/api'

const VARIABLES = ['goal', 'context', 'due_date', 'start_date']

interface PromptRow {
  key: number
  role: 'system' | 'user'
  body: string
  position: number
}

let nextKey = 1

const newPromptRow = (position: number): PromptRow => ({
  key: nextKey++,
  role: 'system',
  body: '',
  position,
})

export const PromptSetNewPage = () => {
  const navigate = useNavigate()
  const [name, setName] = useState('')
  const [prompts, setPrompts] = useState<PromptRow[]>([newPromptRow(1)])
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState('')

  const addPrompt = () => {
    setPrompts(prev => [...prev, newPromptRow(prev.length + 1)])
  }

  const removePrompt = (key: number) => {
    setPrompts(prev => {
      const filtered = prev.filter(p => p.key !== key)
      return filtered.map((p, i) => ({ ...p, position: i + 1 }))
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
    setSubmitting(true)
    setError('')

    const prompts_attributes: PromptInput[] = prompts.map(p => ({
      role: p.role,
      body: p.body,
      position: p.position,
    }))

    try {
      await promptSetsApi.create({ name, prompts_attributes })
      navigate('/admin/prompt-sets')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create prompt set')
      setSubmitting(false)
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <p className="text-[10px] font-semibold uppercase tracking-[0.2em] text-slate-400" style={{ fontFamily: 'DM Mono, monospace' }}>
          PROMPT SETS
        </p>
        <h1 className="mt-1 text-2xl font-bold text-slate-800" style={{ fontFamily: 'Syne, sans-serif' }}>
          New Prompt Set
        </h1>
      </div>

      {error && (
        <div className="rounded-lg border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-600">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Name */}
        <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
          <div className="space-y-1">
            <label className="text-xs font-semibold uppercase tracking-wider text-slate-500">Name</label>
            <input
              type="text"
              value={name}
              onChange={e => setName(e.target.value)}
              required
              className="block w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/30"
              placeholder="e.g. Task Suggestion v1"
            />
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
            {prompts.map(prompt => (
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
                  {prompts.length > 1 && (
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
            {submitting ? 'Creating…' : 'Create Prompt Set'}
          </button>
        </div>
      </form>
    </div>
  )
}
