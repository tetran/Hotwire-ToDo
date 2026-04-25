import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { rolesApi, permissionsApi, type Permission, DROPDOWN_PER_PAGE } from '../../lib/api'
import { reportTruncation } from '../../lib/sentry'
import { AdminPageHeader } from '../../components/AdminPageHeader'
import { AdminCancelButton } from '../../components/AdminCancelButton'
import { ErrorBanner } from '../../components/ErrorBanner'
import { SectionError } from '../../components/SectionError'

function buildSectionErrorMessage(reason: unknown): string {
  return reason instanceof Error ? reason.message : 'Unknown error'
}

export const RolePermissionPage = () => {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [allPermissions, setAllPermissions] = useState<Permission[]>([])
  const [assignedIds, setAssignedIds] = useState<Set<number>>(new Set())
  const [permissionsError, setPermissionsError] = useState('')
  const [assignedError, setAssignedError] = useState('')
  const [submitError, setSubmitError] = useState('')
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [refreshKey, setRefreshKey] = useState(0)

  useEffect(() => {
    setLoading(true)
    ;(async () => {
      const [resAll, resAssigned] = await Promise.allSettled([
        permissionsApi.list({ per_page: DROPDOWN_PER_PAGE }),
        rolesApi.getPermissions(Number(id)),
      ])

      if (resAll.status === 'fulfilled') {
        setAllPermissions(resAll.value.permissions)
        setPermissionsError('')
        reportTruncation({
          resource: 'permissions',
          fetched: resAll.value.permissions.length,
          total_count: resAll.value.meta?.total_count,
          per_page: DROPDOWN_PER_PAGE,
        })
      } else {
        setPermissionsError(buildSectionErrorMessage(resAll.reason))
      }

      if (resAssigned.status === 'fulfilled') {
        setAssignedIds(new Set(resAssigned.value.map(p => p.id)))
        setAssignedError('')
      } else {
        setAssignedError(buildSectionErrorMessage(resAssigned.reason))
      }

      setLoading(false)
    })()
  }, [id, refreshKey])

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
    setSubmitError('')
    setSubmitting(true)
    try {
      await rolesApi.updatePermissions(Number(id), Array.from(assignedIds))
      navigate('/admin/roles')
    } catch (err) {
      setSubmitError(err instanceof Error ? err.message : 'Failed to update permissions')
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
      <AdminPageHeader eyebrow="MANAGEMENT" title="Role Permissions" />

      <ErrorBanner message={submitError || null} />

      <form onSubmit={handleSubmit}>
        {/* Permission groups */}
        <div className="space-y-4">
          {assignedError ? (
            <SectionError
              title="割り当て済みパーミッション"
              message="現在の割り当てを取得できなかったため Save できません。再試行してください。"
              onRetry={() => setRefreshKey(k => k + 1)}
            />
          ) : permissionsError ? (
            <SectionError
              title="パーミッション一覧"
              onRetry={() => setRefreshKey(k => k + 1)}
            />
          ) : (
            Object.entries(grouped).map(([resourceType, permissions]) => (
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
            ))
          )}
        </div>

        <div className="mt-6 flex items-center justify-end gap-3">
          <AdminCancelButton to="/admin/roles" />
          <button
            type="submit"
            disabled={submitting || !!assignedError}
            className="rounded-lg bg-[#6366f1] px-4 py-2 text-sm font-medium text-white shadow-md shadow-indigo-500/20 transition hover:bg-[#5558e8] disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {submitting ? 'Saving...' : 'Save Permissions'}
          </button>
        </div>
      </form>
    </div>
  )
}
