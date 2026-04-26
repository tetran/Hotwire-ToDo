import { useLocation } from 'react-router-dom'
import { navSections } from '../lib/navConfig'

type AdminHeaderProps = {
  isMobileOpen: boolean
  onMobileToggle: () => void
}

export function AdminHeader({ isMobileOpen, onMobileToggle }: AdminHeaderProps) {
  const location = useLocation()

  const isActive = (to: string, exact?: boolean) => {
    if (exact) return location.pathname === to
    return location.pathname.startsWith(to)
  }

  const activeLabel =
    navSections.flatMap((s) => s.items).find((i) => isActive(i.to, i.exact))?.label ?? 'Admin'

  return (
    <header className="flex h-14 shrink-0 items-center border-b border-slate-200 bg-white px-4 md:px-6">
      {/* Hamburger button — mobile only */}
      <button
        type="button"
        onClick={onMobileToggle}
        aria-label={isMobileOpen ? 'Close navigation menu' : 'Open navigation menu'}
        aria-controls="admin-sidebar"
        aria-expanded={isMobileOpen}
        className="mr-3 flex h-8 w-8 items-center justify-center rounded-lg text-slate-500 transition-colors hover:bg-slate-100 hover:text-slate-700 md:hidden"
      >
        <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M4 6h16M4 12h16M4 18h16" />
        </svg>
      </button>

      {/* Breadcrumb-style page label */}
      <div className="flex flex-1 items-center gap-2 text-sm text-slate-400">
        <span className="text-slate-300">/</span>
        <span className="font-medium text-slate-600">{activeLabel}</span>
      </div>
    </header>
  )
}
