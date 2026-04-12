import { useEffect, useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { adminAccountsApi, rolesApi, Role } from '../../lib/api'

export const AdminAccountNewPage = () => {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [name, setName] = useState('')
  const [password, setPassword] = useState('')
  const [passwordConfirmation, setPasswordConfirmation] = useState('')
  const [selectedRoleIds, setSelectedRoleIds] = useState<number[]>([])
  const [roles, setRoles] = useState<Role[]>([])
  const [error, setError] = useState('')
  const [loadingRoles, setLoadingRoles] = useState(true)

  useEffect(() => {
    rolesApi.list({ per_page: 100 })
      .then(response => setRoles(response.roles))
      .catch(() => setError('Failed to load roles'))
      .finally(() => setLoadingRoles(false))
  }, [])

  const toggleRole = (roleId: number) => {
    setSelectedRoleIds(prev =>
      prev.includes(roleId) ? prev.filter(id => id !== roleId) : [...prev, roleId]
    )
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    if (password !== passwordConfirmation) {
      setError('Password confirmation does not match')
      return
    }
    if (selectedRoleIds.length === 0) {
      setError('At least one role must be selected')
      return
    }
    try {
      await adminAccountsApi.create({ email, name, password, role_ids: selectedRoleIds })
      navigate('/admin/admin-accounts')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create admin account')
    }
  }

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div className="flex items-end justify-between">
        <div>
          <p className="text-[10px] font-semibold tracking-[0.2em] text-slate-400"
             style={{ fontFamily: 'DM Mono, monospace' }}>ADMIN</p>
          <h1 className="text-2xl font-bold text-slate-800"
              style={{ fontFamily: 'Syne, sans-serif' }}>New Admin Account</h1>
        </div>
      </div>

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
            <div className="space-y-1">
              <label className="text-xs font-medium text-slate-600">Password</label>
              <input type="password" value={password} onChange={e => setPassword(e.target.value)} required
                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none transition focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/30" />
            </div>
            <div className="space-y-1">
              <label className="text-xs font-medium text-slate-600">Confirm Password</label>
              <input type="password" value={passwordConfirmation} onChange={e => setPasswordConfirmation(e.target.value)} required
                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none transition focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/30" />
            </div>
            <div className="space-y-2">
              <label className="text-xs font-medium text-slate-600">Roles</label>
              {loadingRoles ? (
                <p className="text-xs text-slate-400">Loading roles...</p>
              ) : (
                <div className="space-y-1.5">
                  {roles.map(role => (
                    <label key={role.id} className="flex items-center gap-2.5 rounded-lg border border-slate-100 px-3 py-2 transition hover:bg-slate-50/50 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={selectedRoleIds.includes(role.id)}
                        onChange={() => toggleRole(role.id)}
                        className="h-3.5 w-3.5 rounded border-slate-300 text-[#6366f1] focus:ring-[#6366f1]/30"
                      />
                      <div className="flex items-center gap-2">
                        <span className="text-sm font-medium text-slate-700">{role.name}</span>
                        {role.system_role && (
                          <span className="text-[10px] text-slate-400">system</span>
                        )}
                      </div>
                      {role.description && (
                        <span className="ml-auto text-xs text-slate-400">{role.description}</span>
                      )}
                    </label>
                  ))}
                </div>
              )}
            </div>
          </div>
          <div className="mt-6 flex items-center justify-end gap-2">
            <Link to="/admin/admin-accounts"
              className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:bg-slate-50">
              Cancel
            </Link>
            <button type="submit"
              className="rounded-lg bg-[#6366f1] px-4 py-2 text-sm font-medium text-white shadow-md shadow-indigo-500/20 transition hover:bg-[#5558e8]">
              Create
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
