type AdminSidebarBackdropProps = {
  isOpen: boolean
  isDesktop: boolean
  onClose: () => void
}

export function AdminSidebarBackdrop({ isOpen, isDesktop, onClose }: AdminSidebarBackdropProps) {
  if (!isOpen || isDesktop) return null

  return (
    <div
      data-testid="admin-sidebar-backdrop"
      className="fixed inset-0 z-30 bg-black/40 transition-opacity duration-200 motion-reduce:transition-none"
      aria-hidden="true"
      onClick={onClose}
    />
  )
}
