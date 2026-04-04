import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { AdminAccountEditPage } from '@admin/pages/admin-accounts/AdminAccountEditPage'
import * as api from '@admin/lib/api'

vi.mock('@admin/lib/api', async () => {
  const actual = await vi.importActual('@admin/lib/api')
  return {
    ...actual,
    adminAccountsApi: {
      get: vi.fn(),
      update: vi.fn(),
    },
  }
})

const mockGet = vi.mocked(api.adminAccountsApi.get)
const mockUpdate = vi.mocked(api.adminAccountsApi.update)

const mockNavigate = vi.fn()
vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom')
  return {
    ...actual,
    useNavigate: () => mockNavigate,
  }
})

const renderPage = () =>
  render(
    <MemoryRouter initialEntries={['/admin/admin-accounts/1/edit']}>
      <Routes>
        <Route path="/admin/admin-accounts/:id/edit" element={<AdminAccountEditPage />} />
      </Routes>
    </MemoryRouter>
  )

const accountDetail = {
  id: 1,
  email: 'admin@example.com',
  name: 'Admin User',
  created_at: '2026-01-01T00:00:00Z',
  updated_at: '2026-01-01T00:00:00Z',
  last_sign_in_at: null,
  roles: [{ id: 1, name: 'admin', description: null, system_role: true }],
  permission_matrix: {},
} as unknown as api.AdminAccountDetail

describe('AdminAccountEditPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGet.mockResolvedValue(accountDetail)
  })

  it('renders loading state initially', () => {
    mockGet.mockReturnValue(new Promise(() => {}))
    renderPage()
    expect(screen.getByText('Loading...')).toBeInTheDocument()
  })

  it('renders form with pre-filled data', async () => {
    renderPage()
    await waitFor(() => {
      expect(screen.getByDisplayValue('admin@example.com')).toBeInTheDocument()
      expect(screen.getByDisplayValue('Admin User')).toBeInTheDocument()
    })
  })

  it('navigates to list on successful update', async () => {
    mockUpdate.mockResolvedValue({ ...accountDetail, name: 'Updated Name' })
    renderPage()

    await waitFor(() => {
      expect(screen.getByDisplayValue('Admin User')).toBeInTheDocument()
    })

    const nameInput = screen.getByDisplayValue('Admin User')
    fireEvent.change(nameInput, { target: { value: 'Updated Name' } })
    fireEvent.click(screen.getByRole('button', { name: 'Update' }))

    await waitFor(() => {
      expect(mockUpdate).toHaveBeenCalledWith(1, { email: 'admin@example.com', name: 'Updated Name' })
      expect(mockNavigate).toHaveBeenCalledWith('/admin/admin-accounts')
    })
  })

  it('displays server validation error', async () => {
    mockUpdate.mockRejectedValue(new Error('Email has already been taken'))
    renderPage()

    await waitFor(() => {
      expect(screen.getByDisplayValue('Admin User')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByRole('button', { name: 'Update' }))

    await waitFor(() => {
      expect(screen.getByText('Email has already been taken')).toBeInTheDocument()
    })
  })

  it('displays fetch error', async () => {
    mockGet.mockRejectedValue(new Error('Failed to load admin account'))
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('Failed to load admin account')).toBeInTheDocument()
    })
  })
})
