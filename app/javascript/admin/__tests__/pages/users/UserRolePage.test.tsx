import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { UserRolePage } from '@admin/pages/users/UserRolePage'
import * as api from '@admin/lib/api'

vi.mock('@admin/lib/api', async () => {
  const actual = await vi.importActual('@admin/lib/api')
  return {
    ...actual,
    rolesApi: {
      list: vi.fn(),
    },
    usersApi: {
      getRoles: vi.fn(),
      updateRoles: vi.fn(),
    },
  }
})

vi.mock('@admin/lib/sentry', () => ({
  reportTruncation: vi.fn(),
}))

const mockRolesList = vi.mocked(api.rolesApi.list)
const mockGetRoles = vi.mocked(api.usersApi.getRoles)
const mockUpdateRoles = vi.mocked(api.usersApi.updateRoles)

const mockNavigate = vi.fn()
vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom')
  return {
    ...actual,
    useNavigate: () => mockNavigate,
  }
})

const mockRoles: api.Role[] = [
  { id: 1, name: 'admin', description: 'Administrator', system_role: true, created_at: '2026-01-01T00:00:00Z', updated_at: '2026-01-01T00:00:00Z' },
  { id: 2, name: 'editor', description: null, system_role: false, created_at: '2026-01-01T00:00:00Z', updated_at: '2026-01-01T00:00:00Z' },
]

const mockRolesResponse: api.RoleListResponse = {
  roles: mockRoles,
  meta: { page: 1, per_page: 100, total_count: 2, total_pages: 1 },
}

const renderPage = () =>
  render(
    <MemoryRouter initialEntries={['/admin/users/1/roles']}>
      <Routes>
        <Route path="/admin/users/:id/roles" element={<UserRolePage />} />
      </Routes>
    </MemoryRouter>
  )

describe('UserRolePage — partial failure', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('shows SectionError for allRoles when rolesApi.list fails, Save button remains enabled (sanity: allRolesError does not disable Save)', async () => {
    mockRolesList.mockRejectedValue(new Error('503 Service Unavailable'))
    mockGetRoles.mockResolvedValue([])
    renderPage()

    await waitFor(() => {
      const alert = screen.getByRole('status')
      expect(alert).toHaveTextContent(/ロール一覧/)
    })
    // allRolesError: Save stays enabled per spec (options-list failure does not block submit)
    expect(screen.getByRole('button', { name: 'Save' })).toBeEnabled()
  })

  it('shows SectionError for assignedRoles when usersApi.getRoles fails, Save button is disabled', async () => {
    mockRolesList.mockResolvedValue(mockRolesResponse)
    mockGetRoles.mockRejectedValue(new Error('500 Internal Server Error'))
    renderPage()

    await waitFor(() => {
      const alert = screen.getByRole('status')
      expect(alert).toHaveTextContent(/割り当て済みロール/)
    })
    // assignedError: Save must be disabled to prevent silent data-loss
    expect(screen.getByRole('button', { name: 'Save' })).toBeDisabled()
  })

  it('shows assignedError SectionError when both fetches fail (priority over allRolesError) so user sees the "Save できません" reason, Save disabled', async () => {
    mockRolesList.mockRejectedValue(new Error('Network error'))
    mockGetRoles.mockRejectedValue(new Error('Network error'))
    renderPage()

    await waitFor(() => {
      const alert = screen.getByRole('status')
      // assignedError SectionError takes priority — user sees the explanatory message
      expect(alert).toHaveTextContent(/割り当て済みロール/)
      expect(alert).toHaveTextContent(/Save できません/)
    })
    // allRolesError SectionError is suppressed when assignedError is also set (single render)
    expect(screen.queryByText(/^ロール一覧$/)).not.toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Save' })).toBeDisabled()
  })

  it('mixed error scenario: allRolesError fetch fails → SectionError + Save enabled → submit → submitError in ErrorBanner', async () => {
    // Uses allRolesError path so Save remains enabled and submit can be tested
    mockRolesList.mockRejectedValue(new Error('503 Service Unavailable'))
    mockGetRoles.mockResolvedValue([])
    mockUpdateRoles.mockRejectedValue(new Error('Failed to update roles'))
    renderPage()

    // Wait for SectionError to appear
    await waitFor(() => {
      expect(screen.getByRole('status')).toHaveTextContent(/ロール一覧/)
    })

    // Save button is enabled (allRolesError does not disable Save)
    const saveButton = screen.getByRole('button', { name: 'Save' })
    expect(saveButton).toBeEnabled()

    // Submit the form — triggers submit error
    fireEvent.click(saveButton)

    await waitFor(() => {
      expect(screen.getByText('Failed to update roles')).toBeInTheDocument()
    })

    // SectionError (fetch) and ErrorBanner (submit) can coexist
    expect(screen.getByRole('status')).toHaveTextContent(/ロール一覧/)
    expect(screen.getByText('Failed to update roles')).toBeInTheDocument()
  })
})
