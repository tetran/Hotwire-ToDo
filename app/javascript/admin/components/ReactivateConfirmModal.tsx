import { useState } from 'react'
import { ApiError } from '../lib/api'

interface Props {
  userName: string
  onConfirm: (newEmail?: string) => Promise<void>
  onClose: () => void
}

export const ReactivateConfirmModal = ({ userName, onConfirm, onClose }: Props) => {
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState('')
  const [emailConflict, setEmailConflict] = useState(false)
  const [newEmail, setNewEmail] = useState('')

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setSubmitting(true)
    setError('')
    try {
      // 1st send: no new_email. 2nd send (conflict mode): include new_email
      await onConfirm(emailConflict ? newEmail : undefined)
    } catch (err) {
      if (err instanceof ApiError && err.status === 422 && err.body.original_email_conflict === true) {
        setEmailConflict(true)
        setError('')
      } else {
        setError(err instanceof Error ? err.message : 'Failed to reactivate user')
      }
      setSubmitting(false)
    }
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
      role="dialog"
      aria-modal="true"
      aria-labelledby="reactivate-modal-title"
    >
      <div className="w-full max-w-md rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <h2
          id="reactivate-modal-title"
          className="text-lg font-semibold text-slate-800"
          style={{ fontFamily: 'Syne, sans-serif' }}
        >
          Reactivate User
        </h2>
        <p className="mt-2 text-sm text-slate-600">
          Are you sure you want to reactivate <strong>{userName}</strong>? The user will be able to sign in again.
        </p>

        {emailConflict && (
          <div className="mt-3 rounded-lg border border-amber-500/30 bg-amber-500/10 px-4 py-3 text-sm text-amber-600">
            The original email address is already in use by another user. Please enter a new email address.
          </div>
        )}

        {error && (
          <div className="mt-3 rounded-lg border border-rose-500/30 bg-rose-500/10 px-4 py-3 text-sm text-rose-400">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="mt-4">
          {emailConflict && (
            <div className="mb-4 space-y-1">
              <label className="text-xs font-medium text-slate-600" htmlFor="reactivate-new-email">
                New Email Address
              </label>
              <input
                id="reactivate-new-email"
                type="email"
                value={newEmail}
                onChange={e => setNewEmail(e.target.value)}
                required
                placeholder="Enter a new email address..."
                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none transition focus:border-accent focus:ring-1 focus:ring-accent/30"
              />
            </div>
          )}
          <div className="flex items-center justify-end gap-2">
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
              disabled={submitting || (emailConflict && !newEmail)}
              className="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-emerald-700 disabled:opacity-50"
            >
              {submitting ? 'Reactivating...' : 'Reactivate'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
