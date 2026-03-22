import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { permissionsApi, type Permission } from '../../lib/api'

export const PermissionDetailPage = () => {
  const { id } = useParams<{ id: string }>()
  const [permission, setPermission] = useState<Permission | null>(null)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchPermission = async () => {
      try {
        const data = await permissionsApi.get(Number(id))
        setPermission(data)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load permission')
      } finally {
        setLoading(false)
      }
    }
    fetchPermission()
  }, [id])

  if (loading) return <p>Loading...</p>

  return (
    <div className="space-y-6">
      <div className="flex items-end justify-between">
        <div>
          <p className="text-[10px] font-semibold tracking-[0.2em] text-slate-400"
             style={{ fontFamily: 'DM Mono, monospace' }}>MANAGEMENT</p>
          <h1 className="text-2xl font-bold text-slate-800"
              style={{ fontFamily: 'Syne, sans-serif' }}>Permission Detail</h1>
        </div>
      </div>
      {error && <p className="text-rose-500">{error}</p>}
      {permission && (
        <>
          <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <tbody>
                <tr className="border-b border-slate-100 last:border-0">
                  <th scope="row" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400 w-32">ID</th>
                  <td className="px-5 py-3.5 text-sm text-slate-700">{permission.id}</td>
                </tr>
                <tr className="border-b border-slate-100 last:border-0">
                  <th scope="row" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400 w-32">Resource Type</th>
                  <td className="px-5 py-3.5 text-sm text-slate-700">{permission.resource_type}</td>
                </tr>
                <tr className="border-b border-slate-100 last:border-0">
                  <th scope="row" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400 w-32">Action</th>
                  <td className="px-5 py-3.5 text-sm text-slate-700">{permission.action}</td>
                </tr>
                <tr className="border-b border-slate-100 last:border-0">
                  <th scope="row" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400 w-32">Description</th>
                  <td className="px-5 py-3.5 text-sm text-slate-700">{permission.description ?? '—'}</td>
                </tr>
              </tbody>
            </table>
          </div>
          <div>
            <h2 className="mb-3 text-sm font-semibold text-slate-600">Assigned Roles</h2>
            {permission.roles && permission.roles.length > 0 ? (
              <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                  <thead>
                    <tr className="border-b border-slate-100">
                      <th className="px-5 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Name</th>
                      <th className="px-5 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Description</th>
                      <th className="px-5 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">System Role</th>
                    </tr>
                  </thead>
                  <tbody>
                    {permission.roles.map((role) => (
                      <tr key={role.id} className="border-b border-slate-100 last:border-0">
                        <td className="px-5 py-3.5 text-sm font-medium text-slate-700">{role.name}</td>
                        <td className="px-5 py-3.5 text-sm text-slate-500">{role.description ?? '—'}</td>
                        <td className="px-5 py-3.5 text-sm text-slate-500">{role.system_role ? 'Yes' : 'No'}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <p className="text-sm text-slate-400">No roles assigned.</p>
            )}
          </div>
        </>
      )}
      <div>
        <Link
          to="/admin/permissions"
          className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:bg-slate-50"
        >Back to list</Link>
      </div>
    </div>
  )
}
