import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { usersApi, rolesApi, Role } from '../../lib/api'

export const UserRolePage = () => {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [allRoles, setAllRoles] = useState<Role[]>([])
  const [selectedRoleIds, setSelectedRoleIds] = useState<number[]>([])
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!id) return
    Promise.all([
      rolesApi.list(),
      usersApi.getRoles(Number(id)),
    ])
      .then(([roles, userRoles]) => {
        setAllRoles(roles)
        setSelectedRoleIds(userRoles.map(r => r.id))
      })
      .catch(err => setError(err instanceof Error ? err.message : 'Failed to load roles'))
      .finally(() => setLoading(false))
  }, [id])

  const handleToggle = (roleId: number) => {
    setSelectedRoleIds(prev =>
      prev.includes(roleId)
        ? prev.filter(id => id !== roleId)
        : [...prev, roleId]
    )
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    try {
      await usersApi.updateRoles(Number(id), selectedRoleIds)
      navigate('/admin/users')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update roles')
    }
  }

  if (loading) return <p>Loading...</p>

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div className="flex items-end justify-between">
        <div>
          <p className="text-[10px] font-semibold tracking-[0.2em] text-slate-400"
             style={{ fontFamily: 'DM Mono, monospace' }}>MANAGEMENT</p>
          <h1 className="text-2xl font-bold text-slate-800"
              style={{ fontFamily: 'Syne, sans-serif' }}>Assign Roles</h1>
        </div>
      </div>

      {error && (
        <div className="rounded-lg border border-rose-500/30 bg-rose-500/10 px-4 py-3 text-sm text-rose-400">
          {error}
        </div>
      )}

      <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <form onSubmit={handleSubmit}>
          <ul className="space-y-2">
            {allRoles.map(role => (
              <li key={role.id}>
                <label className="flex items-center gap-2 text-sm text-slate-700 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={selectedRoleIds.includes(role.id)}
                    onChange={() => handleToggle(role.id)}
                    className="rounded border-slate-300 text-[#6366f1]"
                  />
                  <span className="text-sm font-medium text-slate-700">{role.name}</span>
                  {role.description && (
                    <span className="text-xs text-slate-400">- {role.description}</span>
                  )}
                </label>
              </li>
            ))}
          </ul>
          <div className="mt-6 flex items-center justify-end gap-2">
            <button type="button" onClick={() => navigate('/admin/users')}
              className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:bg-slate-50">
              Back
            </button>
            <button type="submit"
              className="rounded-lg bg-[#6366f1] px-4 py-2 text-sm font-medium text-white shadow-md shadow-indigo-500/20 transition hover:bg-[#5558e8]">
              Save
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
