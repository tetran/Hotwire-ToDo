import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { usersApi, User } from '../../lib/api'
import { AdminCancelButton } from '../../components/AdminCancelButton'
import { DeactivatedUserBadge } from '../../components/DeactivatedUserBadge'
import { DeactivateConfirmModal } from '../../components/DeactivateConfirmModal'
import { ReactivateConfirmModal } from '../../components/ReactivateConfirmModal'

export const UserEditPage = () => {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [user, setUser] = useState<User | null>(null)
  const [email, setEmail] = useState('')
  const [name, setName] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)

  const [showDeactivateModal, setShowDeactivateModal] = useState(false)
  const [showReactivateModal, setShowReactivateModal] = useState(false)

  useEffect(() => {
    if (!id) return
    usersApi.get(Number(id))
      .then(u => {
        setUser(u)
        setEmail(u.email)
        setName(u.name)
      })
      .catch(err => setError(err instanceof Error ? err.message : 'Failed to load user'))
      .finally(() => setLoading(false))
  }, [id])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    try {
      await usersApi.update(Number(id), { email, name })
      navigate('/admin/users')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update user')
    }
  }

  const handleDeactivate = async (reason: string) => {
    await usersApi.deactivate(Number(id), reason || undefined)
    navigate('/admin/users')
  }

  const handleReactivate = async (newEmail?: string) => {
    await usersApi.reactivate(Number(id), newEmail)
    navigate('/admin/users')
  }

  if (loading) return <p>Loading...</p>

  const isDeactivated = Boolean(user?.deactivated_at)

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div className="flex items-end justify-between">
        <div>
          <p className="text-[10px] font-semibold tracking-[0.2em] text-slate-400"
             style={{ fontFamily: 'DM Mono, monospace' }}>MANAGEMENT</p>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-bold text-slate-800"
                style={{ fontFamily: 'Syne, sans-serif' }}>Edit User</h1>
            {isDeactivated && <DeactivatedUserBadge />}
          </div>
        </div>
      </div>

      {/* Deactivation info panel — shown at top when user is deactivated */}
      {isDeactivated && user && (
        <div className="rounded-xl border border-amber-200 bg-amber-50 p-5 shadow-sm">
          <h3 className="text-sm font-semibold text-amber-800" style={{ fontFamily: 'Syne, sans-serif' }}>
            Deactivation Info
          </h3>
          <dl className="mt-3 space-y-2 text-sm">
            {user.original_email && (
              <div>
                <dt className="text-xs font-medium text-slate-500">Original Email</dt>
                <dd className="mt-0.5 text-slate-700">{user.original_email}</dd>
              </div>
            )}
            {user.deactivation_reason && (
              <div>
                <dt className="text-xs font-medium text-slate-500">Reason</dt>
                <dd className="mt-0.5 text-slate-700">{user.deactivation_reason}</dd>
              </div>
            )}
            {user.deactivated_at && (
              <div>
                <dt className="text-xs font-medium text-slate-500">Deactivated At</dt>
                <dd className="mt-0.5 text-slate-700">{new Date(user.deactivated_at).toLocaleString()}</dd>
              </div>
            )}
            {user.deactivated_by && (
              <div>
                <dt className="text-xs font-medium text-slate-500">Deactivated By</dt>
                <dd className="mt-0.5 text-slate-700">{user.deactivated_by.name ?? `Admin #${user.deactivated_by.id}`}</dd>
              </div>
            )}
          </dl>
          <div className="mt-4">
            <button
              type="button"
              onClick={() => setShowReactivateModal(true)}
              className="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-emerald-700"
            >
              Reactivate User
            </button>
          </div>
        </div>
      )}

      {error && (
        <div className="rounded-lg border border-rose-500/30 bg-rose-500/10 px-4 py-3 text-sm text-rose-400">
          {error}
        </div>
      )}

      <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <form onSubmit={handleSubmit}>
          <div className="space-y-4">
            <div className="space-y-1">
              <label className="text-xs font-medium text-slate-600">Email</label>
              <input type="email" value={email} onChange={e => setEmail(e.target.value)} required
                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none transition focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/30" />
            </div>
            <div className="space-y-1">
              <label className="text-xs font-medium text-slate-600">Name</label>
              <input type="text" value={name} onChange={e => setName(e.target.value)} required
                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none transition focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/30" />
            </div>
          </div>
          <div className="mt-6 flex items-center justify-end gap-2">
            <AdminCancelButton to="/admin/users" />
            <button type="submit"
              className="rounded-lg bg-[#6366f1] px-4 py-2 text-sm font-medium text-white shadow-md shadow-indigo-500/20 transition hover:bg-[#5558e8]">
              Update
            </button>
          </div>
        </form>
      </div>

      {/* Danger Zone — shown at bottom when user is active */}
      {!isDeactivated && (
        <div className="rounded-xl border border-rose-200 bg-white p-5 shadow-sm">
          <h3 className="text-sm font-semibold text-rose-600" style={{ fontFamily: 'Syne, sans-serif' }}>
            Danger Zone
          </h3>
          <p className="mt-1 text-xs text-slate-500">
            Deactivating a user will prevent them from signing in. This can be reversed.
          </p>
          <div className="mt-4">
            <button
              type="button"
              onClick={() => setShowDeactivateModal(true)}
              className="rounded-md border border-rose-200 px-2.5 py-1 text-xs font-medium text-rose-500 transition hover:bg-rose-50"
            >
              Deactivate User
            </button>
          </div>
        </div>
      )}

      {showDeactivateModal && user && (
        <DeactivateConfirmModal
          userName={user.name ?? user.email}
          onConfirm={handleDeactivate}
          onClose={() => setShowDeactivateModal(false)}
        />
      )}

      {showReactivateModal && user && (
        <ReactivateConfirmModal
          userName={user.name ?? user.email}
          onConfirm={handleReactivate}
          onClose={() => setShowReactivateModal(false)}
        />
      )}
    </div>
  )
}
