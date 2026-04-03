import { useEffect, useState } from 'react'
import { adminAccountsApi, User } from '../../lib/api'
import Avatar from '../../components/Avatar'
import Badge from '../../components/Badge'

export const AdminAccountsIndexPage = () => {
  const [accounts, setAccounts] = useState<User[]>([])
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')
  const [debouncedQuery, setDebouncedQuery] = useState('')

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedQuery(searchQuery), 300)
    return () => clearTimeout(timer)
  }, [searchQuery])

  useEffect(() => {
    const controller = new AbortController()
    setError('')
    setLoading(true)
    adminAccountsApi.list(debouncedQuery ? { q: debouncedQuery } : undefined, { signal: controller.signal })
      .then(data => {
        if (!controller.signal.aborted) setAccounts(data)
      })
      .catch(err => {
        if (!controller.signal.aborted) {
          setError(err instanceof Error ? err.message : 'Failed to load admin accounts')
        }
      })
      .finally(() => {
        if (!controller.signal.aborted) setLoading(false)
      })
    return () => controller.abort()
  }, [debouncedQuery])

  const handleDelete = async (id: number) => {
    if (!confirm('Are you sure you want to delete this admin account?')) return
    try {
      await adminAccountsApi.delete(id)
      setAccounts(accounts.filter(a => a.id !== id))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete admin account')
    }
  }

  if (error) return <p className="text-rose-500">{error}</p>

  return (
    <div className="space-y-5">
      {/* Page header */}
      <div className="flex items-end justify-between">
        <div>
          <p className="text-[10px] font-semibold tracking-[0.2em] text-slate-400" style={{ fontFamily: 'DM Mono, monospace' }}>ADMIN</p>
          <h1 className="text-2xl font-bold text-slate-800" style={{ fontFamily: 'Syne, sans-serif' }}>Admin Accounts</h1>
        </div>
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 rounded-lg border border-slate-200 bg-white px-3 py-2">
            <svg className="h-3.5 w-3.5 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 15.803 7.5 7.5 0 0016.803 15.803z" />
            </svg>
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search admin accounts..."
              className="text-xs text-slate-700 placeholder-slate-400 outline-none bg-transparent"
            />
          </div>
          <span
            className="rounded-lg bg-slate-300 px-4 py-2 text-sm font-medium text-white cursor-not-allowed"
            title="Coming soon"
          >
            New Admin Account
          </span>
        </div>
      </div>

      {/* Table */}
      <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr className="border-b border-slate-100">
              <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">ID</th>
              <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">User</th>
              <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Role</th>
              <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Created At</th>
              <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-50">
            {loading && accounts.length === 0 && (
              <tr>
                <td colSpan={5} className="px-5 py-10 text-center text-sm text-slate-400">
                  Loading...
                </td>
              </tr>
            )}
            {!loading && accounts.length === 0 && (
              <tr>
                <td colSpan={5} className="px-5 py-10 text-center text-sm text-slate-400">
                  No admin accounts found
                </td>
              </tr>
            )}
            {accounts.map(account => (
              <tr key={account.id} className="transition-colors hover:bg-slate-50/50">
                <td className="px-5 py-3.5 text-xs text-slate-400" style={{ fontFamily: 'DM Mono, monospace' }}>{account.id}</td>
                <td className="px-5 py-3.5">
                  <div className="flex items-center gap-3">
                    <Avatar name={account.name ?? account.email} size="sm" />
                    <div>
                      <p className="text-sm font-medium text-slate-700">{account.name}</p>
                      <p className="text-xs text-slate-400">{account.email}</p>
                    </div>
                  </div>
                </td>
                <td className="px-5 py-3.5">
                  <div className="flex flex-wrap gap-1">
                    {(account.roles ?? []).map(role => (
                      <Badge
                        key={role.id}
                        variant={role.name === 'admin' ? 'danger' : role.name === 'user_manager' ? 'warning' : 'info'}
                      >
                        {role.name}
                      </Badge>
                    ))}
                  </div>
                </td>
                <td className="px-5 py-3.5 text-xs text-slate-400">{new Date(account.created_at).toLocaleDateString()}</td>
                <td className="px-5 py-3.5">
                  <button
                    onClick={() => handleDelete(account.id)}
                    className="rounded-md border border-rose-200 px-2.5 py-1 text-xs font-medium text-rose-500 transition hover:bg-rose-50"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
