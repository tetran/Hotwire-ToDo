import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { AdminLayout, navSections } from '../../components/AdminLayout'

// Mock useAuth
const mockCan = vi.fn()
vi.mock('../../contexts/AuthContext', () => ({
  useAuth: () => ({
    user: { name: 'Test Admin', email: 'admin@example.com' },
    logout: vi.fn(),
    can: mockCan,
  }),
}))

describe('navSections', () => {
  it('has three sections: NAVIGATION, ADMIN, AI INFRASTRUCTURE', () => {
    expect(navSections.map((s) => s.label)).toEqual([
      'NAVIGATION',
      'ADMIN',
      'AI INFRASTRUCTURE',
    ])
  })

  it('NAVIGATION contains Dashboard, Event Logs, and Users', () => {
    const nav = navSections.find((s) => s.label === 'NAVIGATION')!
    expect(nav.items.map((i) => i.label)).toEqual(['Dashboard', 'Event Logs', 'Users'])
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

  afterEach(() => {
    mockCan.mockReset()
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
})
