import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { RolePermissionPage } from '@admin/pages/roles/RolePermissionPage'
import * as api from '@admin/lib/api'

vi.mock('@admin/lib/api', async () => {
  const actual = await vi.importActual('@admin/lib/api')
  return {
    ...actual,
    permissionsApi: {
      list: vi.fn(),
    },
    rolesApi: {
      getPermissions: vi.fn(),
      updatePermissions: vi.fn(),
    },
  }
})

vi.mock('@admin/lib/sentry', () => ({
  reportTruncation: vi.fn(),
}))

vi.mock('@admin/components/AdminPageHeader', () => ({
  AdminPageHeader: ({ title }: { title: string }) => <h1>{title}</h1>,
}))

const mockPermissionsList = vi.mocked(api.permissionsApi.list)
const mockGetPermissions = vi.mocked(api.rolesApi.getPermissions)
const mockUpdatePermissions = vi.mocked(api.rolesApi.updatePermissions)

const mockNavigate = vi.fn()
vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom')
  return {
    ...actual,
    useNavigate: () => mockNavigate,
  }
})

const mockPermissions: api.Permission[] = [
  { id: 1, resource_type: 'User', action: 'read', description: null },
  { id: 2, resource_type: 'User', action: 'write', description: null },
]

const mockPermissionsResponse: api.PermissionListResponse = {
  permissions: mockPermissions,
  meta: { page: 1, per_page: 100, total_count: 2, total_pages: 1 },
}

const renderPage = () =>
  render(
    <MemoryRouter initialEntries={['/admin/roles/1/permissions']}>
      <Routes>
        <Route path="/admin/roles/:id/permissions" element={<RolePermissionPage />} />
      </Routes>
    </MemoryRouter>
  )

describe('RolePermissionPage — partial failure', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('shows SectionError for permissionsError when permissionsApi.list fails, Save button remains enabled (sanity: permissionsError does not disable Save)', async () => {
    mockPermissionsList.mockRejectedValue(new Error('503 Service Unavailable'))
    mockGetPermissions.mockResolvedValue([])
    renderPage()

    await waitFor(() => {
      const alert = screen.getByRole('status')
      expect(alert).toHaveTextContent(/パーミッション一覧/)
    })
    // permissionsError: Save stays enabled per spec (options-list failure does not block submit)
    expect(screen.getByRole('button', { name: 'Save Permissions' })).toBeEnabled()
  })

  it('shows SectionError for assignedError when rolesApi.getPermissions fails, Save button is disabled', async () => {
    mockPermissionsList.mockResolvedValue(mockPermissionsResponse)
    mockGetPermissions.mockRejectedValue(new Error('500 Internal Server Error'))
    renderPage()

    await waitFor(() => {
      const alert = screen.getByRole('status')
      expect(alert).toHaveTextContent(/割り当て済みパーミッション/)
    })
    // assignedError: Save must be disabled to prevent silent data-loss
    expect(screen.getByRole('button', { name: 'Save Permissions' })).toBeDisabled()
  })

  it('shows assignedError SectionError when both fetches fail (priority over permissionsError) so user sees the "Save できません" reason, Save disabled', async () => {
    mockPermissionsList.mockRejectedValue(new Error('Network error'))
    mockGetPermissions.mockRejectedValue(new Error('Network error'))
    renderPage()

    await waitFor(() => {
      const alert = screen.getByRole('status')
      // assignedError SectionError takes priority — user sees the explanatory message
      expect(alert).toHaveTextContent(/割り当て済みパーミッション/)
      expect(alert).toHaveTextContent(/Save できません/)
    })
    // permissionsError SectionError is suppressed when assignedError is also set (single render)
    expect(screen.queryByText(/^パーミッション一覧$/)).not.toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Save Permissions' })).toBeDisabled()
  })

  it('mixed error scenario: permissionsError fetch fails → SectionError + Save enabled → submit → ErrorBanner shown', async () => {
    // Uses permissionsError path so Save remains enabled and submit can be tested
    mockPermissionsList.mockRejectedValue(new Error('503 Service Unavailable'))
    mockGetPermissions.mockResolvedValue([])
    mockUpdatePermissions.mockRejectedValue(new Error('Failed to update permissions'))
    renderPage()

    // Wait for SectionError
    await waitFor(() => {
      expect(screen.getByRole('status')).toHaveTextContent(/パーミッション一覧/)
    })

    // Save button is enabled (permissionsError does not disable Save)
    const saveButton = screen.getByRole('button', { name: 'Save Permissions' })
    expect(saveButton).toBeEnabled()

    // Submit the form → submit error in ErrorBanner
    fireEvent.click(saveButton)

    await waitFor(() => {
      expect(screen.getByText('Failed to update permissions')).toBeInTheDocument()
    })

    // SectionError (fetch) and ErrorBanner (submit) coexist
    expect(screen.getByRole('status')).toHaveTextContent(/パーミッション一覧/)
    expect(screen.getByText('Failed to update permissions')).toBeInTheDocument()
  })
})
