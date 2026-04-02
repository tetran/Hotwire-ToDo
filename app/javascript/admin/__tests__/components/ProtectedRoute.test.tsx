import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { ProtectedRoute } from '@admin/components/ProtectedRoute'
import * as AuthContextModule from '@admin/contexts/AuthContext'

vi.mock('@admin/contexts/AuthContext')
const mockUseAuth = vi.mocked(AuthContextModule.useAuth)

const renderWithRouter = (ui: React.ReactElement, initialRoute = '/admin/users') =>
  render(<MemoryRouter initialEntries={[initialRoute]}>{ui}</MemoryRouter>)

const baseAuth = {
  user: { id: 1, email: 'admin@test.com', name: 'Admin', is_admin: true, capabilities: {} },
  loading: false,
  refreshing: false,
  login: vi.fn(),
  logout: vi.fn(),
  can: vi.fn().mockReturnValue(true),
  isAdmin: true,
} as unknown as ReturnType<typeof AuthContextModule.useAuth>

describe('ProtectedRoute', () => {
  it('shows loading when refreshing capabilities', () => {
    mockUseAuth.mockReturnValue({ ...baseAuth, refreshing: true, can: vi.fn().mockReturnValue(false) })

    renderWithRouter(
      <ProtectedRoute requiredCapability={{ resource: 'User', action: 'read' }}>
        <div>Protected Content</div>
      </ProtectedRoute>
    )

    expect(screen.getByText('Loading...')).toBeInTheDocument()
    expect(screen.queryByText('Protected Content')).not.toBeInTheDocument()
  })

  it('renders children when not refreshing and capability is met', () => {
    mockUseAuth.mockReturnValue({ ...baseAuth, refreshing: false, can: vi.fn().mockReturnValue(true) })

    renderWithRouter(
      <ProtectedRoute requiredCapability={{ resource: 'User', action: 'read' }}>
        <div>Protected Content</div>
      </ProtectedRoute>
    )

    expect(screen.getByText('Protected Content')).toBeInTheDocument()
  })
})
