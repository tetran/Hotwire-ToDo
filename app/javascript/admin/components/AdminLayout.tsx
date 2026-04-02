import { Link, Outlet, useLocation, useNavigate } from 'react-router-dom'
import { Action, ResourceType } from '../lib/api'
import { useAuth } from '../contexts/AuthContext'
import Avatar from './Avatar'

type NavItem = {
  to: string
  label: string
  exact?: boolean
  icon: React.ReactNode
  requiredCapability?: { resource: ResourceType; action: Action }
}

const navSections: { label: string; items: NavItem[] }[] = [
  {
    label: 'NAVIGATION',
    items: [
      {
        to: '/admin',
        label: 'Dashboard',
        exact: true,
        icon: (
          <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 013 19.875v-6.75zM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V8.625zM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V4.125z" />
          </svg>
        ),
      },
      {
        to: '/admin/users',
        label: 'Users',
        requiredCapability: { resource: 'User', action: 'read' },
        icon: (
          <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" />
          </svg>
        ),
      },
      {
        to: '/admin/roles',
        label: 'Roles',
        icon: (
          <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z" />
          </svg>
        ),
      },
      {
        to: '/admin/permissions',
        label: 'Permissions',
        icon: (
          <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 5.25a3 3 0 013 3m3 0a6 6 0 01-7.029 5.912c-.563-.097-1.159.026-1.563.43L10.5 17.25H8.25v2.25H6v2.25H2.25v-2.818c0-.597.237-1.17.659-1.591l6.499-6.499c.404-.404.527-1 .43-1.563A6 6 0 1121.75 8.25z" />
          </svg>
        ),
      },
    ],
  },
  {
    label: 'AI INFRASTRUCTURE',
    items: [
      {
        to: '/admin/llm-providers',
        label: 'LLM Providers',
        requiredCapability: { resource: 'LlmProvider', action: 'read' },
        icon: (
          <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M8.25 3v1.5M4.5 8.25H3m18 0h-1.5M4.5 12H3m18 0h-1.5m-15 3.75H3m18 0h-1.5M8.25 19.5V21M12 3v1.5m0 15V21m3.75-18v1.5m0 15V21m-9-1.5h10.5a2.25 2.25 0 002.25-2.25V6.75a2.25 2.25 0 00-2.25-2.25H6.75A2.25 2.25 0 004.5 6.75v10.5a2.25 2.25 0 002.25 2.25zm.75-12h9v9h-9v-9z" />
          </svg>
        ),
      },
      {
        to: '/admin/prompt-sets',
        label: 'Prompt Sets',
        requiredCapability: { resource: 'LlmProvider', action: 'read' },
        icon: (
          <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" />
          </svg>
        ),
      },
      {
        to: '/admin/suggestion-configs',
        label: 'Suggestion Configs',
        requiredCapability: { resource: 'LlmProvider', action: 'read' },
        icon: (
          <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M10.5 6h9.75M10.5 6a1.5 1.5 0 11-3 0m3 0a1.5 1.5 0 10-3 0M3.75 6H7.5m3 12h9.75m-9.75 0a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m-3.75 0H7.5m9-6h3.75m-3.75 0a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m-9.75 0h9.75" />
          </svg>
        ),
      },
    ],
  },
]

export const AdminLayout = () => {
  const { user, logout, can } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()

  const handleLogout = async () => {
    try {
      await logout()
    } catch {
      // Session may already be expired; proceed to login regardless
    }
    navigate('/admin/login')
  }

  const isActive = (item: NavItem) => {
    if (item.exact) return location.pathname === item.to
    return location.pathname.startsWith(item.to)
  }

  return (
    <div className="flex min-h-screen bg-[#f8f9fc]">
      {/* Sidebar */}
      <nav className="flex w-[220px] shrink-0 flex-col border-r border-[#1e2130] bg-[#0f1117]">
        {/* Logo */}
        <div className="flex items-center gap-3 border-b border-[#1e2130] px-4 py-5">
          <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-[#6366f1] shadow-md shadow-indigo-500/30">
            <svg className="h-4 w-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M9 3H5a2 2 0 00-2 2v4m6-6h10a2 2 0 012 2v4M9 3v18m0 0h10a2 2 0 002-2v-4M9 21H5a2 2 0 01-2-2v-4m0 0h18" />
            </svg>
          </div>
          <div>
            <p className="text-sm font-bold leading-none text-white" style={{ fontFamily: 'Syne, sans-serif' }}>Hobo Admin</p>
            <p className="mt-0.5 text-[9px] tracking-[0.15em] text-slate-500" style={{ fontFamily: 'DM Mono, monospace' }}>CONTROL PANEL</p>
          </div>
        </div>

        {/* Navigation */}
        <div className="flex-1 overflow-y-auto py-4">
          {navSections.map((section) => (
            <div key={section.label} className="mb-4 px-3">
              <p className="mb-2 px-2 text-[9px] font-semibold tracking-[0.15em] text-slate-600" style={{ fontFamily: 'DM Mono, monospace' }}>
                {section.label}
              </p>
              <ul className="space-y-0.5">
                {section.items.filter((item) =>
                  !item.requiredCapability || can(item.requiredCapability.resource, item.requiredCapability.action)
                ).map((item) => {
                  const active = isActive(item)
                  return (
                    <li key={item.to}>
                      <Link
                        to={item.to}
                        className={`flex items-center gap-3 rounded-lg px-3 py-2 text-sm transition-colors ${
                          active
                            ? 'bg-[rgba(99,102,241,0.15)] text-[#6366f1]'
                            : 'text-slate-400 hover:bg-white/5 hover:text-slate-200'
                        }`}
                      >
                        <span className={active ? 'text-[#6366f1]' : 'text-slate-600'}>{item.icon}</span>
                        {item.label}
                      </Link>
                    </li>
                  )
                })}
              </ul>
            </div>
          ))}
        </div>

        {/* User footer */}
        <div className="border-t border-[#1e2130] px-3 py-4">
          <div className="flex items-center gap-3 rounded-lg px-2 py-2">
            <Avatar name={user?.name ?? user?.email ?? 'A'} size="sm" />
            <div className="min-w-0 flex-1">
              <p className="truncate text-xs font-medium text-slate-200">{user?.name ?? user?.email}</p>
              <p className="text-[10px] text-slate-500">Super Admin</p>
            </div>
          </div>
          <button
            onClick={handleLogout}
            className="mt-2 flex w-full items-center gap-2 rounded-lg px-2 py-2 text-xs text-slate-500 transition-colors hover:bg-white/5 hover:text-slate-300"
          >
            <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-6a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 007.5 21h6a2.25 2.25 0 002.25-2.25V15M12 9l-3 3m0 0l3 3m-3-3h12.75" />
            </svg>
            Logout
          </button>
        </div>
      </nav>

      {/* Main content */}
      <div className="flex min-w-0 flex-1 flex-col">
        {/* Top header */}
        <header className="flex h-14 shrink-0 items-center border-b border-slate-200 bg-white px-6">
          <div className="flex flex-1 items-center gap-2 text-sm text-slate-400">
            <span className="text-slate-300">/</span>
            <span className="font-medium text-slate-600">
              {navSections.flatMap(s => s.items).find(i => isActive(i))?.label ?? 'Admin'}
            </span>
          </div>
        </header>

        <main className="flex-1 overflow-y-auto p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
