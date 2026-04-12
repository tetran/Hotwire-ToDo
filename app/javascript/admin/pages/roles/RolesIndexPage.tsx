import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { rolesApi, type Role, type PaginationMeta } from '../../lib/api'
import Pagination from '../../components/Pagination'
import { usePagination, useClampPage } from '../../hooks/usePagination'

export const RolesIndexPage = () => {
  const navigate = useNavigate()
  const [roles, setRoles] = useState<Role[]>([])
  const [meta, setMeta] = useState<PaginationMeta | null>(null)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)

  const { page, perPage, setPage, setPerPage, clampPage } = usePagination()
  useClampPage(meta, clampPage)

  useEffect(() => {
    const controller = new AbortController()
    setLoading(true)
    rolesApi.list({ page, per_page: perPage }, { signal: controller.signal })
      .then(response => {
        if (!controller.signal.aborted) {
          setRoles(response.roles)
          setMeta(response.meta)
        }
      })
      .catch(err => {
        if (!controller.signal.aborted) {
          setError(err instanceof Error ? err.message : 'Failed to load roles')
        }
      })
      .finally(() => {
        if (!controller.signal.aborted) setLoading(false)
      })
    return () => controller.abort()
  }, [page, perPage])

  const handleDelete = async (id: number, name: string) => {
    if (!window.confirm(`Are you sure you want to delete the role "${name}"?`)) return
    try {
      await rolesApi.delete(id)
      setRoles(prev => prev.filter(r => r.id !== id))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete role')
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
              style={{ fontFamily: 'Syne, sans-serif' }}>Roles</h1>
        </div>
        <button
          onClick={() => navigate('/admin/roles/new')}
          className="rounded-lg bg-[#6366f1] px-4 py-2 text-sm font-medium text-white shadow-md shadow-indigo-500/20 transition hover:bg-[#5558e8]"
        >
          New Role
        </button>
      </div>

      {error && (
        <div className="rounded-lg border border-rose-500/30 bg-rose-500/10 px-4 py-3 text-sm text-rose-400">
          {error}
        </div>
      )}

      {/* Table */}
      <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr className="border-b border-slate-100">
              <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">ID</th>
              <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Name</th>
              <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Description</th>
              <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-50">
            {roles.map(role => (
              <tr key={role.id} className="transition-colors hover:bg-slate-50/50">
                <td className="px-5 py-3.5 text-xs text-slate-400" style={{ fontFamily: 'DM Mono, monospace' }}>{role.id}</td>
                <td className="px-5 py-3.5 text-sm text-slate-700">{role.name}</td>
                <td className="px-5 py-3.5 text-sm text-slate-700">{role.description}</td>
                <td className="px-5 py-3.5">
                  <div className="flex items-center gap-2">
                    <Link
                      to={`/admin/roles/${role.id}/edit`}
                      className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:bg-slate-50"
                    >
                      Edit
                    </Link>
                    <button
                      onClick={() => handleDelete(role.id, role.name)}
                      className="rounded-md border border-rose-200 px-2.5 py-1 text-xs font-medium text-rose-500 transition hover:bg-rose-50"
                    >
                      Delete
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {meta && (
        <Pagination
          meta={meta}
          page={page}
          perPage={perPage}
          onPageChange={setPage}
          onPerPageChange={setPerPage}
        />
      )}
    </div>
  )
}
