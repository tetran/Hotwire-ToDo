import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { adminAccountsApi, type AdminAccountDetail, type ResourceType, type Action } from '../../lib/api'
import { useAuth } from '../../contexts/AuthContext'
import Avatar from '../../components/Avatar'
import Badge from '../../components/Badge'

const RESOURCE_TYPES: ResourceType[] = ['User', 'Project', 'Task', 'Comment', 'Admin', 'LlmProvider']
const ACTIONS: Action[] = ['read', 'write', 'delete', 'manage']

const roleBadgeVariant = (name: string) => {
  if (name === 'admin') return 'danger' as const
  if (name === 'user_manager') return 'warning' as const
  return 'info' as const
}

export const AdminAccountDetailPage = () => {
  const { id } = useParams<{ id: string }>()
  const { can } = useAuth()
  const [account, setAccount] = useState<AdminAccountDetail | null>(null)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)
  const canWrite = can('User', 'write')

  useEffect(() => {
    const fetchAccount = async () => {
      try {
        const data = await adminAccountsApi.get(Number(id))
        setAccount(data)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load admin account')
      } finally {
        setLoading(false)
      }
    }
    fetchAccount()
  }, [id])

  if (loading) return <p>Loading...</p>

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div className="flex items-end justify-between">
        <div>
          <p className="text-[10px] font-semibold tracking-[0.2em] text-slate-400"
             style={{ fontFamily: 'DM Mono, monospace' }}>ADMIN</p>
          <h1 className="text-2xl font-bold text-slate-800"
              style={{ fontFamily: 'Syne, sans-serif' }}>Admin Account Detail</h1>
        </div>
        {canWrite && account && (
          <Link
            to={`/admin/admin-accounts/${account.id}/roles`}
            className="rounded-lg bg-[#6366f1] px-4 py-2 text-sm font-medium text-white shadow-md shadow-indigo-500/20 transition hover:bg-[#5558e8]"
          >
            Edit Roles
          </Link>
        )}
      </div>

      {error && <p className="text-rose-500">{error}</p>}

      {account && (
        <>
          {/* Account info */}
          <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
            <div className="flex items-center gap-4">
              <Avatar name={account.name ?? account.email} size="lg" />
              <div>
                <p className="text-lg font-semibold text-slate-800">{account.name}</p>
                <p className="text-sm text-slate-400">{account.email}</p>
                <p className="mt-1 text-xs text-slate-400">
                  Created: {new Date(account.created_at).toLocaleDateString()}
                </p>
              </div>
            </div>
          </div>

          {/* Roles */}
          <div>
            <h2 className="mb-3 text-sm font-semibold text-slate-600">Assigned Roles</h2>
            <div className="flex flex-wrap gap-2">
              {account.roles.map(role => (
                <Badge key={role.id} variant={roleBadgeVariant(role.name)}>
                  {role.name}
                  {role.system_role && ' (system)'}
                </Badge>
              ))}
            </div>
          </div>

          {/* Permission Matrix */}
          <div>
            <h2 className="mb-3 text-sm font-semibold text-slate-600">Permission Matrix</h2>
            <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr className="border-b border-slate-100">
                    <th className="px-5 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Resource</th>
                    {ACTIONS.map(action => (
                      <th key={action} className="px-5 py-3 text-center text-xs font-semibold uppercase tracking-wider text-slate-400">
                        {action}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {RESOURCE_TYPES.map(rt => (
                    <tr key={rt} className="border-b border-slate-50 last:border-0">
                      <td className="px-5 py-3 text-sm font-medium text-slate-700">{rt}</td>
                      {ACTIONS.map(action => (
                        <td key={action} className="px-5 py-3 text-center">
                          {account.permission_matrix[rt][action] ? (
                            <span className="text-emerald-500">&#10003;</span>
                          ) : (
                            <span className="text-slate-300">&mdash;</span>
                          )}
                        </td>
                      ))}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </>
      )}

      <div>
        <Link
          to="/admin/admin-accounts"
          className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:bg-slate-50"
        >
          Back to list
        </Link>
      </div>
    </div>
  )
}
