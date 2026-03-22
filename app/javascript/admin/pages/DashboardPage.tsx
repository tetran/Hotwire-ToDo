import { useEffect, useState } from 'react'
import { dashboardApi, llmProvidersApi, DashboardData, LlmProvider } from '../lib/api'
import StatCard from '../components/StatCard'
import Avatar from '../components/Avatar'
import Badge from '../components/Badge'

export const DashboardPage = () => {
  const [data, setData] = useState<DashboardData | null>(null)
  const [providers, setProviders] = useState<LlmProvider[]>([])
  const [error, setError] = useState('')

  useEffect(() => {
    Promise.all([
      dashboardApi.get(),
      llmProvidersApi.list(),
    ])
      .then(([dashData, provData]) => {
        setData(dashData)
        setProviders(provData)
      })
      .catch(err => setError(err instanceof Error ? err.message : 'Failed to load dashboard'))
  }, [])

  if (error) return <p className="text-rose-500">{error}</p>
  if (!data) return <p className="text-slate-400">Loading...</p>

  const now = new Date()
  const dateLabel = now.toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div className="flex items-end justify-between">
        <div>
          <p className="text-[10px] font-semibold tracking-[0.2em] text-slate-400" style={{ fontFamily: 'DM Mono, monospace' }}>OVERVIEW</p>
          <h1 className="text-2xl font-bold text-slate-800" style={{ fontFamily: 'Syne, sans-serif' }}>Dashboard</h1>
          <p className="mt-0.5 text-xs text-slate-400">{dateLabel}</p>
        </div>
        <button className="rounded-lg bg-[#6366f1] px-4 py-2 text-sm font-medium text-white shadow-md shadow-indigo-500/20 transition hover:bg-[#5558e8]">
          + Invite User
        </button>
      </div>

      {/* Stat cards */}
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <StatCard
          label="Total Users"
          value={data.stats?.users_count ?? 0}
          subtitle="View all users →"
          accent="text-indigo-400"
          icon={
            <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" />
            </svg>
          }
        />
        <StatCard
          label="Active Roles"
          value={data.stats?.roles_count ?? 0}
          subtitle={`${data.stats?.roles_count ?? 0} Roles Defined`}
          accent="text-purple-400"
          icon={
            <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z" />
            </svg>
          }
        />
        <StatCard
          label="LLM Providers"
          value={data.stats?.llm_providers_count ?? 0}
          subtitle={`${data.stats?.llm_models_count ?? 0} Models Available`}
          accent="text-cyan-400"
          icon={
            <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M8.25 3v1.5M4.5 8.25H3m18 0h-1.5M4.5 12H3m18 0h-1.5m-15 3.75H3m18 0h-1.5M8.25 19.5V21M12 3v1.5m0 15V21m3.75-18v1.5m0 15V21m-9-1.5h10.5a2.25 2.25 0 002.25-2.25V6.75a2.25 2.25 0 00-2.25-2.25H6.75A2.25 2.25 0 004.5 6.75v10.5a2.25 2.25 0 002.25 2.25zm.75-12h9v9h-9v-9z" />
            </svg>
          }
        />
        <StatCard
          label="LLM Models"
          value={data.stats?.llm_models_count ?? 0}
          subtitle="View all models →"
          accent="text-emerald-400"
          icon={
            <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M9.75 3.104v5.714a2.25 2.25 0 01-.659 1.591L5 14.5M9.75 3.104c-.251.023-.501.05-.75.082m.75-.082a24.301 24.301 0 014.5 0m0 0v5.714c0 .597.237 1.17.659 1.591L19.8 15.3M14.25 3.104c.251.023.501.05.75.082M19.8 15.3l-1.57.393A9.065 9.065 0 0112 15a9.065 9.065 0 00-6.23-.693L5 14.5m14.8.8l1.402 1.402c1.232 1.232.65 3.318-1.067 3.611A48.309 48.309 0 0112 21c-2.773 0-5.491-.235-8.135-.687-1.718-.293-2.3-2.379-1.067-3.61L5 14.5" />
            </svg>
          }
        />
      </div>

      {/* Bottom section */}
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
        {/* Recent users table */}
        <div className="lg:col-span-2 rounded-xl border border-slate-200 bg-white shadow-sm">
          <div className="flex items-center justify-between border-b border-slate-100 px-5 py-4">
            <h2 className="text-sm font-semibold text-slate-700" style={{ fontFamily: 'Syne, sans-serif' }}>Recent Users</h2>
            <a href="/admin/users" className="text-xs text-[#6366f1] hover:underline">View all</a>
          </div>
          <div className="divide-y divide-slate-50">
            {(data.recent_users ?? []).map((u) => (
              <div key={u.id} className="flex items-center gap-3 px-5 py-3">
                <Avatar name={u.name ?? u.email} size="sm" />
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-medium text-slate-700">{u.name}</p>
                  <p className="truncate text-xs text-slate-400">{u.email}</p>
                </div>
                <Badge variant="info">User</Badge>
                <span className="text-xs text-slate-400 shrink-0">
                  {new Date(u.created_at).toLocaleDateString()}
                </span>
              </div>
            ))}
            {(data.recent_users ?? []).length === 0 && (
              <p className="px-5 py-4 text-sm text-slate-400">No users yet.</p>
            )}
          </div>
        </div>

        {/* System status panel */}
        <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
          <div className="flex items-center justify-between border-b border-slate-100 px-5 py-4">
            <h2 className="text-sm font-semibold text-slate-700" style={{ fontFamily: 'Syne, sans-serif' }}>System Status</h2>
            <a href="/admin/llm-providers" className="text-xs text-[#6366f1] hover:underline">Manage</a>
          </div>
          <div className="divide-y divide-slate-50">
            {providers.map((provider) => (
              <div key={provider.id} className="flex items-center justify-between px-5 py-3">
                <div className="flex items-center gap-2.5">
                  <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-md bg-[#6366f1]/10 text-xs font-bold text-[#6366f1]">
                    {provider.name[0]}
                  </div>
                  <span className="text-xs font-medium text-slate-600">{provider.name}</span>
                </div>
                <Badge variant={provider.active ? 'success' : 'neutral'}>
                  {provider.active ? 'Active' : 'Inactive'}
                </Badge>
              </div>
            ))}
            {providers.length === 0 && (
              <p className="px-5 py-4 text-sm text-slate-400">No providers configured.</p>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
