import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { rolesApi, permissionsApi, type Permission } from '../../lib/api'

export const RolePermissionPage = () => {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [allPermissions, setAllPermissions] = useState<Permission[]>([])
  const [assignedIds, setAssignedIds] = useState<Set<number>>(new Set())
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [allResponse, assigned] = await Promise.all([
          permissionsApi.list({ per_page: 100 }),
          rolesApi.getPermissions(Number(id)),
        ])
        setAllPermissions(allResponse.permissions)
        setAssignedIds(new Set(assigned.map(p => p.id)))
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load permissions')
      } finally {
        setLoading(false)
      }
    }
    fetchData()
  }, [id])

  const handleToggle = (permissionId: number) => {
    setAssignedIds(prev => {
      const next = new Set(prev)
      if (next.has(permissionId)) {
        next.delete(permissionId)
      } else {
        next.add(permissionId)
      }
      return next
    })
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setSubmitting(true)
    try {
      await rolesApi.updatePermissions(Number(id), Array.from(assignedIds))
      navigate('/admin/roles')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update permissions')
      setSubmitting(false)
    }
  }

  if (loading) return <p>Loading...</p>

  const grouped = allPermissions.reduce<Record<string, Permission[]>>((acc, p) => {
    const key = p.resource_type
    if (!acc[key]) acc[key] = []
    acc[key].push(p)
    return acc
  }, {})

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div className="flex items-end justify-between">
        <div>
          <p className="text-[10px] font-semibold tracking-[0.2em] text-slate-400"
             style={{ fontFamily: 'DM Mono, monospace' }}>MANAGEMENT</p>
          <h1 className="text-2xl font-bold text-slate-800"
              style={{ fontFamily: 'Syne, sans-serif' }}>Role Permissions</h1>
        </div>
      </div>

      {error && (
        <div className="rounded-lg border border-rose-500/30 bg-rose-500/10 px-4 py-3 text-sm text-rose-400">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit}>
        {/* Permission groups */}
        <div className="space-y-4">
          {Object.entries(grouped).map(([resourceType, permissions]) => (
            <div key={resourceType} className="rounded-xl border border-slate-200 bg-white shadow-sm">
              <div className="border-b border-slate-100 px-5 py-3 text-sm font-semibold text-slate-700"
                   style={{ fontFamily: 'Syne, sans-serif' }}>
                {resourceType}
              </div>
              <div className="divide-y divide-slate-50">
                {permissions.map(permission => (
                  <div key={permission.id} className="flex items-center gap-3 px-5 py-3">
                    <label className="flex items-center gap-2 text-sm text-slate-700 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={assignedIds.has(permission.id)}
                        onChange={() => handleToggle(permission.id)}
                        className="rounded border-slate-300 text-[#6366f1]"
                      />
                      <span className="text-sm font-medium text-slate-700">{permission.action}</span>
                      {permission.description && (
                        <span className="text-xs text-slate-400">— {permission.description}</span>
                      )}
                    </label>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>

        <div className="mt-6 flex items-center justify-end">
          <button
            type="submit"
            disabled={submitting}
            className="rounded-lg bg-[#6366f1] px-4 py-2 text-sm font-medium text-white shadow-md shadow-indigo-500/20 transition hover:bg-[#5558e8]"
          >
            {submitting ? 'Saving...' : 'Save Permissions'}
          </button>
        </div>
      </form>
    </div>
  )
}
