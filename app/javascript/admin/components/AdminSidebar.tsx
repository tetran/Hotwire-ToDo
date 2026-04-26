import { Link, useLocation } from 'react-router-dom'
import { Action, ResourceType } from '../lib/api'
import { navSections, type NavItem } from '../lib/navConfig'
import Avatar from './Avatar'

type NavItemProps = {
  item: NavItem
  collapsed: boolean
  active: boolean
}

function NavItem({ item, collapsed, active }: NavItemProps) {
  return (
    <li>
      <Link
        to={item.to}
        aria-label={collapsed ? item.label : undefined}
        className={`group relative flex items-center gap-3 rounded-lg px-3 py-2 text-sm transition-colors ${
          active
            ? 'bg-accent/15 text-accent'
            : 'text-slate-400 hover:bg-white/5 hover:text-slate-200'
        }`}
      >
        <span className={`shrink-0 ${active ? 'text-accent' : 'text-slate-600'}`}>
          {item.icon}
        </span>
        <span className={collapsed ? 'sr-only' : ''}>{item.label}</span>
        {collapsed && (
          <span
            role="tooltip"
            className="pointer-events-none absolute left-full ml-2 z-50 whitespace-nowrap rounded-md bg-slate-900 px-2 py-1 text-xs text-white opacity-0 group-hover:opacity-100 group-focus-within:opacity-100 transition-opacity"
          >
            {item.label}
          </span>
        )}
      </Link>
    </li>
  )
}

type AdminSidebarProps = {
  isDesktop: boolean
  isDesktopExpanded: boolean
  isMobileOpen: boolean
  onToggleDesktop: () => void
  onCloseMobile: () => void
  user: { name?: string; email?: string } | null
  logout: () => Promise<void>
  can: (resource: ResourceType, action: Action) => boolean
}

export function AdminSidebar({
  isDesktop,
  isDesktopExpanded,
  isMobileOpen,
  onToggleDesktop,
  onCloseMobile,
  user,
  logout,
  can,
}: AdminSidebarProps) {
  const location = useLocation()

  const collapsed = isDesktop && !isDesktopExpanded

  const isActive = (item: NavItem) => {
    if (item.exact) return location.pathname === item.to
    return location.pathname.startsWith(item.to)
  }

  // On desktop: sidebar is always rendered with width transition
  // On mobile: sidebar is a fixed drawer that slides in/out
  const sidebarWidth = isDesktop
    ? isDesktopExpanded
      ? 'w-[220px]'
      : 'w-16'
    : 'w-64'

  const mobileTransform = !isDesktop
    ? isMobileOpen
      ? 'translate-x-0'
      : '-translate-x-full'
    : ''

  const positionClasses = isDesktop
    ? 'relative shrink-0'
    : 'fixed inset-y-0 left-0 z-40'

  // Per-axis transitions: desktop animates width (220 ⇄ 64), mobile animates transform (slide).
  // motion-reduce honored by reduced-motion modifier.
  const transitionClasses = isDesktop
    ? 'transition-[width] duration-200 ease-out motion-reduce:transition-none'
    : 'transition-transform duration-300 ease-out motion-reduce:transition-none motion-reduce:transform-none'

  // Off-canvas drawer is still in DOM; mark inert so its focusable descendants are not tab-reachable.
  const offCanvas = !isDesktop && !isMobileOpen

  return (
    <nav
      id="admin-sidebar"
      aria-label="Admin navigation"
      inert={offCanvas}
      className={`flex flex-col border-r border-sidebar-border bg-sidebar ${sidebarWidth} ${positionClasses} ${mobileTransform} ${transitionClasses}`}
    >
      {/* Sidebar header: branding + desktop chevron toggle + mobile close button */}
      <div className="relative flex items-center gap-3 border-b border-sidebar-border px-4 py-5">
        <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-accent shadow-md shadow-indigo-500/30">
          <svg className="h-4 w-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M9 3H5a2 2 0 00-2 2v4m6-6h10a2 2 0 012 2v4M9 3v18m0 0h10a2 2 0 002-2v-4M9 21H5a2 2 0 01-2-2v-4m0 0h18" />
          </svg>
        </div>

        {!collapsed && (
          <div className="min-w-0 overflow-hidden transition-opacity duration-200">
            <p className="text-sm font-bold leading-none text-white" style={{ fontFamily: 'Syne, sans-serif' }}>Hobo Admin</p>
            <p className="mt-0.5 text-[9px] tracking-[0.15em] text-slate-500" style={{ fontFamily: 'DM Mono, monospace' }}>CONTROL PANEL</p>
          </div>
        )}

        {/* Desktop chevron toggle (hidden on mobile) */}
        {isDesktop && (
          <button
            type="button"
            onClick={onToggleDesktop}
            aria-label={isDesktopExpanded ? 'Collapse sidebar' : 'Expand sidebar'}
            aria-controls="admin-sidebar"
            aria-expanded={isDesktopExpanded}
            className="absolute -right-3 top-6 hidden h-6 w-6 items-center justify-center rounded-full border border-sidebar-border bg-sidebar text-slate-400 shadow-md shadow-black/40 hover:text-white hover:border-accent/60 transition-colors md:flex"
          >
            <svg
              className={`h-3.5 w-3.5 transition-transform duration-200 ${isDesktopExpanded ? '' : 'rotate-180'}`}
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={2}
            >
              <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
            </svg>
          </button>
        )}

        {/* Mobile in-drawer close button */}
        {!isDesktop && (
          <button
            type="button"
            onClick={onCloseMobile}
            aria-label="Close navigation"
            className="ml-auto flex h-7 w-7 items-center justify-center rounded-lg text-slate-400 hover:bg-white/5 hover:text-slate-200 transition-colors md:hidden"
          >
            <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        )}
      </div>

      {/* Navigation sections */}
      <div className="flex-1 overflow-y-auto py-4">
        {navSections.map((section) => {
          const visibleItems = section.items.filter(
            (item) => !item.requiredCapability || can(item.requiredCapability.resource, item.requiredCapability.action)
          )
          if (visibleItems.length === 0) return null
          return (
            <div key={section.label} className="mb-4 px-3">
              {!collapsed && (
                <p
                  className="mb-2 px-2 text-[9px] font-semibold tracking-[0.15em] text-slate-600"
                  style={{ fontFamily: 'DM Mono, monospace' }}
                >
                  {section.label}
                </p>
              )}
              <ul className="space-y-0.5">
                {visibleItems.map((item) => (
                  <NavItem
                    key={item.to}
                    item={item}
                    collapsed={collapsed}
                    active={isActive(item)}
                  />
                ))}
              </ul>
            </div>
          )
        })}
      </div>

      {/* User footer */}
      <div className="border-t border-sidebar-border px-3 py-4">
        {collapsed ? (
          <div className="flex flex-col items-center gap-2">
            <Avatar name={user?.name ?? user?.email ?? 'A'} size="sm" />
            <button
              onClick={logout}
              aria-label="Logout"
              className="flex h-8 w-8 items-center justify-center rounded-lg text-slate-500 transition-colors hover:bg-white/5 hover:text-slate-300"
            >
              <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-6a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 007.5 21h6a2.25 2.25 0 002.25-2.25V15M12 9l-3 3m0 0l3 3m-3-3h12.75" />
              </svg>
            </button>
          </div>
        ) : (
          <>
            <div className="flex items-center gap-3 rounded-lg px-2 py-2">
              <Avatar name={user?.name ?? user?.email ?? 'A'} size="sm" />
              <div className="min-w-0 flex-1">
                <p className="truncate text-xs font-medium text-slate-200">{user?.name ?? user?.email}</p>
                <p className="text-[10px] text-slate-500">Super Admin</p>
              </div>
            </div>
            <button
              onClick={logout}
              className="mt-2 flex w-full items-center gap-2 rounded-lg px-2 py-2 text-xs text-slate-500 transition-colors hover:bg-white/5 hover:text-slate-300"
            >
              <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-6a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 007.5 21h6a2.25 2.25 0 002.25-2.25V15M12 9l-3 3m0 0l3 3m-3-3h12.75" />
              </svg>
              Logout
            </button>
          </>
        )}
      </div>
    </nav>
  )
}
