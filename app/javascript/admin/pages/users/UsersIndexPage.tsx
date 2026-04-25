import { useEffect, useRef, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { usersApi, User, type PaginationMeta } from '../../lib/api'
import Avatar from '../../components/Avatar'
import Pagination from '../../components/Pagination'
import { usePagination, useClampPage } from '../../hooks/usePagination'
import { DeactivatedUserBadge } from '../../components/DeactivatedUserBadge'
import { UserStatusFilter } from '../../components/UserStatusFilter'
import { DeactivateConfirmModal } from '../../components/DeactivateConfirmModal'
import { ReactivateConfirmModal } from '../../components/ReactivateConfirmModal'

type Status = 'active' | 'deactivated' | 'all'

export const UsersIndexPage = () => {
  const [searchParams, setSearchParams] = useSearchParams()

  const statusFromUrl = (searchParams.get('status') ?? 'active') as Status
  const [status, setStatus] = useState<Status>(statusFromUrl)

  const [users, setUsers] = useState<User[]>([])
  const [meta, setMeta] = useState<PaginationMeta | null>(null)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')
  const [debouncedQuery, setDebouncedQuery] = useState('')

  const [deactivatingUser, setDeactivatingUser] = useState<User | null>(null)
  const [reactivatingUser, setReactivatingUser] = useState<User | null>(null)

  const { page, perPage, setPage, setPerPage, resetPage, clampPage } = usePagination()
  useClampPage(meta, clampPage)

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedQuery(searchQuery), 300)
    return () => clearTimeout(timer)
  }, [searchQuery])

  const prevDebouncedQueryRef = useRef(debouncedQuery)
  useEffect(() => {
    if (prevDebouncedQueryRef.current !== debouncedQuery) {
      prevDebouncedQueryRef.current = debouncedQuery
      resetPage()
    }
  }, [debouncedQuery, resetPage])

  // Sync status → URL
  useEffect(() => {
    setSearchParams(prev => {
      const next = new URLSearchParams(prev)
      next.set('status', status)
      return next
    }, { replace: true })
    resetPage()
  }, [status, setSearchParams, resetPage])

  useEffect(() => {
    const controller = new AbortController()
    setError('')
    setLoading(true)
    usersApi.list(
      { q: debouncedQuery || undefined, status, page, per_page: perPage },
      { signal: controller.signal }
    )
      .then(response => {
        if (!controller.signal.aborted) {
          setUsers(response.users)
          setMeta(response.meta)
        }
      })
      .catch(err => {
        if (!controller.signal.aborted) {
          setError(err instanceof Error ? err.message : 'Failed to load users')
        }
      })
      .finally(() => {
        if (!controller.signal.aborted) setLoading(false)
      })
    return () => controller.abort()
  }, [debouncedQuery, status, page, perPage])

  const handleStatusChange = (next: Status) => {
    setStatus(next)
  }

  const handleDeactivate = async (reason: string) => {
    if (!deactivatingUser) return
    await usersApi.deactivate(deactivatingUser.id, reason || undefined)
    setDeactivatingUser(null)
    // Refresh list
    setUsers(prev => prev.filter(u => u.id !== deactivatingUser.id))
  }

  const handleReactivate = async (newEmail?: string) => {
    if (!reactivatingUser) return
    await usersApi.reactivate(reactivatingUser.id, newEmail)
    setReactivatingUser(null)
    // Refresh list
    setUsers(prev => prev.filter(u => u.id !== reactivatingUser.id))
  }

  const isDeactivated = (user: User) => Boolean(user.deactivated_at)

  if (error) return <p className="text-rose-500">{error}</p>

  return (
    <div className="space-y-5">
      {/* Page header */}
      <div className="flex items-end justify-between">
        <div>
          <p className="text-[10px] font-semibold tracking-[0.2em] text-slate-400" style={{ fontFamily: 'DM Mono, monospace' }}>MANAGEMENT</p>
          <h1 className="text-2xl font-bold text-slate-800" style={{ fontFamily: 'Syne, sans-serif' }}>Users</h1>
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
              placeholder="Search users..."
              className="text-xs text-slate-700 placeholder-slate-400 outline-none bg-transparent"
            />
          </div>
        </div>
      </div>

      {/* Status filter */}
      <UserStatusFilter value={status} onChange={handleStatusChange} />

      {/* Table */}
      <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr className="border-b border-slate-100">
              <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">ID</th>
              <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">User</th>
              <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Created At</th>
              <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-50">
            {loading && users.length === 0 && (
              <tr>
                <td colSpan={4} className="px-5 py-10 text-center text-sm text-slate-400">
                  Loading...
                </td>
              </tr>
            )}
            {!loading && users.length === 0 && (
              <tr>
                <td colSpan={4} className="px-5 py-10 text-center text-sm text-slate-400">
                  No users found
                </td>
              </tr>
            )}
            {users.map(user => (
              <tr key={user.id} className="transition-colors hover:bg-slate-50/50">
                <td className="px-5 py-3.5 text-xs text-slate-400" style={{ fontFamily: 'DM Mono, monospace' }}>{user.id}</td>
                <td className="px-5 py-3.5">
                  <div className="flex items-center gap-3">
                    <Avatar name={user.name ?? user.email} size="sm" />
                    <div>
                      <div className="flex items-center gap-2">
                        <p className="text-sm font-medium text-slate-700">{user.name}</p>
                        {isDeactivated(user) && <DeactivatedUserBadge />}
                      </div>
                      <p className="text-xs text-slate-400">{user.email}</p>
                    </div>
                  </div>
                </td>
                <td className="px-5 py-3.5 text-xs text-slate-400">{new Date(user.created_at).toLocaleDateString()}</td>
                <td className="px-5 py-3.5">
                  <div className="flex items-center gap-2">
                    {isDeactivated(user) ? (
                      <>
                        <button
                          onClick={() => setReactivatingUser(user)}
                          className="rounded-lg bg-emerald-600 px-2.5 py-1 text-xs font-medium text-white transition hover:bg-emerald-700"
                        >
                          Reactivate
                        </button>
                        <Link
                          to={`/admin/users/${user.id}/edit`}
                          className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:bg-slate-50"
                        >
                          View
                        </Link>
                      </>
                    ) : (
                      <>
                        <Link
                          to={`/admin/users/${user.id}/edit`}
                          className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:bg-slate-50"
                        >
                          Edit
                        </Link>
                        <button
                          onClick={() => setDeactivatingUser(user)}
                          className="rounded-md border border-rose-200 px-2.5 py-1 text-xs font-medium text-rose-500 transition hover:bg-rose-50"
                        >
                          Deactivate
                        </button>
                      </>
                    )}
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

      {deactivatingUser && (
        <DeactivateConfirmModal
          userName={deactivatingUser.name ?? deactivatingUser.email}
          onConfirm={handleDeactivate}
          onClose={() => setDeactivatingUser(null)}
        />
      )}

      {reactivatingUser && (
        <ReactivateConfirmModal
          userName={reactivatingUser.name ?? reactivatingUser.email}
          onConfirm={handleReactivate}
          onClose={() => setReactivatingUser(null)}
        />
      )}
    </div>
  )
}
