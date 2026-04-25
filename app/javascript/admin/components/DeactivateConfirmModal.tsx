import { useState } from 'react'

interface Props {
  userName: string
  onConfirm: (reason: string) => Promise<void>
  onClose: () => void
}

export const DeactivateConfirmModal = ({ userName, onConfirm, onClose }: Props) => {
  const [reason, setReason] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState('')

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setSubmitting(true)
    setError('')
    try {
      await onConfirm(reason)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to deactivate user')
      setSubmitting(false)
    }
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
      role="dialog"
      aria-modal="true"
      aria-labelledby="deactivate-modal-title"
    >
      <div className="w-full max-w-md rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <h2
          id="deactivate-modal-title"
          className="text-lg font-semibold text-slate-800"
          style={{ fontFamily: 'Syne, sans-serif' }}
        >
          Deactivate User
        </h2>
        <p className="mt-2 text-sm text-slate-600">
          Are you sure you want to deactivate <strong>{userName}</strong>? The user will no longer be able to sign in.
        </p>

        {error && (
          <div className="mt-3 rounded-lg border border-rose-500/30 bg-rose-500/10 px-4 py-3 text-sm text-rose-400">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="mt-4 space-y-3">
          <div className="space-y-1">
            <label className="text-xs font-medium text-slate-600" htmlFor="deactivate-reason">
              Reason <span className="text-slate-400">(optional, max 500 characters)</span>
            </label>
            <textarea
              id="deactivate-reason"
              value={reason}
              onChange={e => setReason(e.target.value)}
              maxLength={500}
              rows={3}
              placeholder="Enter reason for deactivation..."
              className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none transition focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/30"
            />
          </div>
          <div className="flex items-center justify-end gap-2 pt-2">
            <button
              type="button"
              onClick={onClose}
              disabled={submitting}
              className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:bg-slate-50 disabled:opacity-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={submitting}
              className="rounded-md border border-rose-200 px-2.5 py-1 text-xs font-medium text-rose-500 transition hover:bg-rose-50 disabled:opacity-50"
            >
              {submitting ? 'Deactivating...' : 'Deactivate'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
