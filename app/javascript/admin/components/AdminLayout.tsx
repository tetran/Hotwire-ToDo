import { Outlet, useNavigate } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'
import { useSidebarState } from '../hooks/useSidebarState'
import { AdminSidebar } from './AdminSidebar'
import { AdminSidebarBackdrop } from './AdminSidebarBackdrop'
import { AdminHeader } from './AdminHeader'

export const AdminLayout = () => {
  const { user, logout, can } = useAuth()
  const navigate = useNavigate()
  const { isDesktop, isDesktopExpanded, isMobileOpen, toggleDesktop, toggleMobile, closeMobile } =
    useSidebarState()

  const handleLogout = async () => {
    try {
      await logout()
    } catch {
      // Session may already be expired; proceed to login regardless
    }
    navigate('/admin/login')
  }

  return (
    <div className="flex min-h-screen bg-surface">
      <AdminSidebarBackdrop isOpen={isMobileOpen} isDesktop={isDesktop} onClose={closeMobile} />
      <AdminSidebar
        isDesktop={isDesktop}
        isDesktopExpanded={isDesktopExpanded}
        isMobileOpen={isMobileOpen}
        onToggleDesktop={toggleDesktop}
        onCloseMobile={closeMobile}
        user={user}
        logout={handleLogout}
        can={can}
      />
      <div className="flex min-w-0 flex-1 flex-col">
        <AdminHeader isMobileOpen={isMobileOpen} onMobileToggle={toggleMobile} />
        <main className="flex-1 overflow-y-auto p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
