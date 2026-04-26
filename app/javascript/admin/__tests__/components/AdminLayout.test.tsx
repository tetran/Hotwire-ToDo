import { fireEvent, render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { AdminLayout } from '../../components/AdminLayout'
import { navSections } from '../../lib/navConfig'

// Mock useAuth
const mockCan = vi.fn()
vi.mock('../../contexts/AuthContext', () => ({
  useAuth: () => ({
    user: { name: 'Test Admin', email: 'admin@example.com' },
    logout: vi.fn(),
    can: mockCan,
  }),
}))

// matchMedia helper
function makeMatchMedia(isDesktop: boolean) {
  return vi.fn().mockImplementation((query: string) => ({
    matches: query === '(min-width: 768px)' ? isDesktop : false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  }))
}

describe('navSections', () => {
  it('has three sections: NAVIGATION, ADMIN, AI INFRASTRUCTURE', () => {
    expect(navSections.map((s) => s.label)).toEqual([
      'NAVIGATION',
      'ADMIN',
      'AI INFRASTRUCTURE',
    ])
  })

  it('NAVIGATION contains Dashboard, Event Logs, System Info, and Users', () => {
    const nav = navSections.find((s) => s.label === 'NAVIGATION')!
    expect(nav.items.map((i) => i.label)).toEqual(['Dashboard', 'Event Logs', 'System Info', 'Users'])
  })

  it('ADMIN contains Admin Accounts, Roles, and Permissions', () => {
    const admin = navSections.find((s) => s.label === 'ADMIN')!
    expect(admin.items.map((i) => i.label)).toEqual([
      'Admin Accounts',
      'Roles',
      'Permissions',
    ])
  })

  it('Dashboard has no requiredCapability', () => {
    const dashboard = navSections[0].items.find((i) => i.label === 'Dashboard')!
    expect(dashboard.requiredCapability).toBeUndefined()
  })

  it('Users requires User:read', () => {
    const users = navSections[0].items.find((i) => i.label === 'Users')!
    expect(users.requiredCapability).toEqual({ resource: 'User', action: 'read' })
  })

  it('all ADMIN section items require Admin:read', () => {
    const admin = navSections.find((s) => s.label === 'ADMIN')!
    for (const item of admin.items) {
      expect(item.requiredCapability).toEqual({ resource: 'Admin', action: 'read' })
    }
  })
})

describe('AdminLayout', () => {
  const renderLayout = () =>
    render(
      <MemoryRouter initialEntries={['/admin']}>
        <AdminLayout />
      </MemoryRouter>
    )

  beforeEach(() => {
    localStorage.clear()
    // Default to desktop
    window.matchMedia = makeMatchMedia(true)
  })

  afterEach(() => {
    mockCan.mockReset()
    vi.restoreAllMocks()
  })

  it('hides section header when all items are filtered out', () => {
    // Only grant User:read — ADMIN section should be hidden
    mockCan.mockImplementation(
      (resource: string, action: string) =>
        resource === 'User' && action === 'read'
    )

    renderLayout()

    expect(screen.getByText('NAVIGATION')).toBeInTheDocument()
    expect(screen.queryByText('ADMIN')).not.toBeInTheDocument()
  })

  it('shows ADMIN section when user has Admin:read', () => {
    mockCan.mockImplementation(
      (resource: string, action: string) =>
        (resource === 'Admin' && action === 'read') ||
        (resource === 'User' && action === 'read')
    )

    renderLayout()

    expect(screen.getByText('NAVIGATION')).toBeInTheDocument()
    expect(screen.getByText('ADMIN')).toBeInTheDocument()
    expect(screen.getByText('Admin Accounts')).toBeInTheDocument()
    expect(screen.getByText('Roles')).toBeInTheDocument()
    expect(screen.getByText('Permissions')).toBeInTheDocument()
  })

  it('hides Users when user lacks User:read', () => {
    mockCan.mockImplementation(
      (resource: string, action: string) =>
        resource === 'Admin' && action === 'read'
    )

    renderLayout()

    expect(screen.queryByText('Users')).not.toBeInTheDocument()
    expect(screen.getByText('Admin Accounts')).toBeInTheDocument()
  })

  // New case: clicking desktop toggle flips expanded state
  it('clicking desktop toggle button changes aria-expanded', () => {
    mockCan.mockReturnValue(true)

    renderLayout()

    // Initially expanded (localStorage empty = default expanded)
    const toggleButton = screen.getByRole('button', { name: 'Collapse sidebar' })
    expect(toggleButton).toHaveAttribute('aria-expanded', 'true')

    fireEvent.click(toggleButton)

    // After click: collapsed
    expect(screen.getByRole('button', { name: 'Expand sidebar' })).toBeInTheDocument()
  })

  // New case: hamburger is present on mobile viewport
  it('hamburger button is present in DOM (md:hidden controls visual display)', () => {
    // Even on desktop matchMedia mock, the hamburger exists in DOM — md:hidden is CSS-only
    mockCan.mockReturnValue(true)

    renderLayout()

    const hamburger = screen.getByRole('button', { name: 'Open navigation menu' })
    expect(hamburger).toBeInTheDocument()
  })

  // New case: backdrop click closes mobile drawer
  it('backdrop click closes mobile drawer', () => {
    // Set mobile viewport and pre-open mobile drawer
    window.matchMedia = makeMatchMedia(false)
    localStorage.setItem('admin.sidebar.mobile', 'open')
    mockCan.mockReturnValue(true)

    renderLayout()

    // Backdrop should be present (mobile + open)
    const backdrop = document.querySelector('[data-testid="admin-sidebar-backdrop"]') as HTMLElement
    expect(backdrop).toBeInTheDocument()

    fireEvent.click(backdrop)

    // After click, backdrop should be gone (isMobileOpen = false)
    expect(document.querySelector('[data-testid="admin-sidebar-backdrop"]')).toBeNull()
  })
})
