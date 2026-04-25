import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { usersApi, rolesApi, Role, DROPDOWN_PER_PAGE } from '../../lib/api'
import { reportTruncation } from '../../lib/sentry'
import { AdminCancelButton } from '../../components/AdminCancelButton'
import { ErrorBanner } from '../../components/ErrorBanner'
import { SectionError } from '../../components/SectionError'

function buildSectionErrorMessage(reason: unknown): string {
  return reason instanceof Error ? reason.message : 'Unknown error'
}

export const UserRolePage = () => {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [allRoles, setAllRoles] = useState<Role[]>([])
  const [selectedRoleIds, setSelectedRoleIds] = useState<number[]>([])
  const [allRolesError, setAllRolesError] = useState('')
  const [assignedError, setAssignedError] = useState('')
  const [submitError, setSubmitError] = useState('')
  const [loading, setLoading] = useState(true)
  const [refreshKey, setRefreshKey] = useState(0)

  useEffect(() => {
    if (!id) return
    setLoading(true)

    ;(async () => {
      const [resRoles, resUserRoles] = await Promise.allSettled([
        rolesApi.list({ per_page: DROPDOWN_PER_PAGE }),
        usersApi.getRoles(Number(id)),
      ])

      if (resRoles.status === 'fulfilled') {
        setAllRoles(resRoles.value.roles)
        setAllRolesError('')
        reportTruncation({
          resource: 'roles',
          fetched: resRoles.value.roles.length,
          total_count: resRoles.value.meta?.total_count,
          per_page: DROPDOWN_PER_PAGE,
        })
      } else {
        setAllRolesError(buildSectionErrorMessage(resRoles.reason))
      }

      if (resUserRoles.status === 'fulfilled') {
        setSelectedRoleIds(resUserRoles.value.map(r => r.id))
        setAssignedError('')
      } else {
        setAssignedError(buildSectionErrorMessage(resUserRoles.reason))
      }

      setLoading(false)
    })()
  }, [id, refreshKey])

  const handleToggle = (roleId: number) => {
    setSelectedRoleIds(prev =>
      prev.includes(roleId)
        ? prev.filter(rid => rid !== roleId)
        : [...prev, roleId]
    )
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setSubmitError('')
    try {
      await usersApi.updateRoles(Number(id), selectedRoleIds)
      navigate('/admin/users')
    } catch (err) {
      setSubmitError(err instanceof Error ? err.message : 'Failed to update roles')
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

      <ErrorBanner message={submitError || null} />

      <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <form onSubmit={handleSubmit}>
          {assignedError ? (
            <SectionError
              title="割り当て済みロール"
              message="現在の割り当てを取得できなかったため Save できません。再試行してください。"
              onRetry={() => setRefreshKey(k => k + 1)}
            />
          ) : allRolesError ? (
            <SectionError
              title="ロール一覧"
              onRetry={() => setRefreshKey(k => k + 1)}
            />
          ) : (
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
          )}
          <div className="mt-6 flex items-center justify-end gap-2">
            <AdminCancelButton to="/admin/users" />
            <button type="submit"
              disabled={!!assignedError}
              className="rounded-lg bg-[#6366f1] px-4 py-2 text-sm font-medium text-white shadow-md shadow-indigo-500/20 transition hover:bg-[#5558e8] disabled:opacity-50 disabled:cursor-not-allowed">
              Save
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
