import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { permissionsApi, type Permission, type PaginationMeta } from '../../lib/api'
import Pagination from '../../components/Pagination'
import { usePagination, useClampPage } from '../../hooks/usePagination'

export const PermissionsIndexPage = () => {
  const [permissions, setPermissions] = useState<Permission[]>([])
  const [meta, setMeta] = useState<PaginationMeta | null>(null)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)

  const { page, perPage, setPage, setPerPage, clampPage } = usePagination()
  useClampPage(meta, clampPage)

  useEffect(() => {
    const controller = new AbortController()
    setLoading(true)
    permissionsApi.list({ page, per_page: perPage }, { signal: controller.signal })
      .then(response => {
        if (!controller.signal.aborted) {
          setPermissions(response.permissions)
          setMeta(response.meta)
        }
      })
      .catch(err => {
        if (!controller.signal.aborted) {
          setError(err instanceof Error ? err.message : 'Failed to load permissions')
        }
      })
      .finally(() => {
        if (!controller.signal.aborted) setLoading(false)
      })
    return () => controller.abort()
  }, [page, perPage])

  if (loading) return <p>Loading...</p>

  return (
    <div className="space-y-6">
      <div className="flex items-end justify-between">
        <div>
          <p className="text-[10px] font-semibold tracking-[0.2em] text-slate-400"
             style={{ fontFamily: 'DM Mono, monospace' }}>MANAGEMENT</p>
          <h1 className="text-2xl font-bold text-slate-800"
              style={{ fontFamily: 'Syne, sans-serif' }}>Permissions</h1>
        </div>
      </div>
      {error && <p className="text-rose-500">{error}</p>}
      <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr className="border-b border-slate-100">
              <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">ID</th>
              <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Name</th>
              <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Resource Type</th>
              <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Action</th>
              <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Description</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-50">
            {permissions.map(permission => (
              <tr key={permission.id} className="transition-colors hover:bg-slate-50/50">
                <td className="px-5 py-3.5 text-xs text-slate-400" style={{ fontFamily: 'DM Mono, monospace' }}>{permission.id}</td>
                <td className="px-5 py-3.5 text-sm text-slate-700">
                  <Link
                    to={`/admin/permissions/${permission.id}`}
                    className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:bg-slate-50"
                  >{`${permission.resource_type}:${permission.action}`}</Link>
                </td>
                <td className="px-5 py-3.5 text-sm text-slate-700">{permission.resource_type}</td>
                <td className="px-5 py-3.5 text-sm text-slate-700">{permission.action}</td>
                <td className="px-5 py-3.5 text-sm text-slate-700">{permission.description ?? '—'}</td>
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
