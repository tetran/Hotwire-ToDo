import { render, screen, waitFor, fireEvent, within } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { UsersIndexPage } from '@admin/pages/users/UsersIndexPage'
import * as api from '@admin/lib/api'

vi.mock('@admin/lib/api', async () => {
  const actual = await vi.importActual('@admin/lib/api')
  return {
    ...actual,
    usersApi: {
      list: vi.fn(),
      deactivate: vi.fn(),
      reactivate: vi.fn(),
    },
  }
})

const mockList = vi.mocked(api.usersApi.list)
const mockDeactivate = vi.mocked(api.usersApi.deactivate)
const mockReactivate = vi.mocked(api.usersApi.reactivate)

const activeUser: api.User = {
  id: 1,
  email: 'alice@example.com',
  name: 'Alice',
  created_at: '2026-01-01T00:00:00Z',
  updated_at: '2026-01-01T00:00:00Z',
  deactivated_at: null,
}

const deactivatedUser: api.User = {
  id: 2,
  email: 'deactivated_bob@example.com',
  name: 'Bob',
  created_at: '2026-01-01T00:00:00Z',
  updated_at: '2026-01-01T00:00:00Z',
  deactivated_at: '2026-04-01T00:00:00Z',
  deactivation_reason: 'Requested by user',
  original_email: 'bob@example.com',
}

const makeMeta = (count = 1): api.PaginationMeta => ({
  page: 1,
  per_page: 25,
  total_count: count,
  total_pages: 1,
})

const renderPage = (initialUrl = '/admin/users') =>
  render(
    <MemoryRouter initialEntries={[initialUrl]}>
      <Routes>
        <Route path="/admin/users" element={<UsersIndexPage />} />
      </Routes>
    </MemoryRouter>
  )

describe('UsersIndexPage — status filter', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('defaults to active status and passes status=active to API', async () => {
    mockList.mockResolvedValue({ users: [activeUser], meta: makeMeta(1) })
    renderPage()
    await waitFor(() => {
      expect(mockList).toHaveBeenCalledWith(
        expect.objectContaining({ status: 'active' }),
        expect.anything()
      )
    })
  })

  it('passes status=deactivated when Deactivated filter is clicked', async () => {
    // Initial load with active users
    mockList.mockResolvedValue({ users: [activeUser], meta: makeMeta(1) })
    renderPage()
    await waitFor(() => expect(mockList).toHaveBeenCalled())

    // After filter click, return deactivated users
    mockList.mockResolvedValue({ users: [deactivatedUser], meta: makeMeta(1) })
    fireEvent.click(screen.getByRole('button', { name: 'Deactivated' }))

    await waitFor(() => {
      const calls = mockList.mock.calls
      expect(calls.some(c => c[0] && (c[0] as { status?: string }).status === 'deactivated')).toBe(true)
    })
  })

  it('passes status=all when All filter is clicked', async () => {
    mockList.mockResolvedValue({ users: [activeUser], meta: makeMeta(1) })
    renderPage()
    await waitFor(() => expect(mockList).toHaveBeenCalled())

    mockList.mockResolvedValue({ users: [activeUser, deactivatedUser], meta: makeMeta(2) })
    fireEvent.click(screen.getByRole('button', { name: 'All' }))

    await waitFor(() => {
      const calls = mockList.mock.calls
      expect(calls.some(c => c[0] && (c[0] as { status?: string }).status === 'all')).toBe(true)
    })
  })

  it('shows DeactivatedUserBadge for deactivated users', async () => {
    mockList.mockResolvedValue({ users: [deactivatedUser], meta: makeMeta(1) })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('Deactivated')).toBeInTheDocument()
    })
  })

  it('shows Reactivate and View actions for deactivated users, not Deactivate', async () => {
    mockList.mockResolvedValue({ users: [deactivatedUser], meta: makeMeta(1) })
    renderPage()

    await waitFor(() => screen.getByText('Bob'))
    expect(screen.getByRole('button', { name: 'Reactivate' })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'View' })).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Deactivate' })).not.toBeInTheDocument()
  })

  it('shows Edit and Deactivate actions for active users, not Reactivate', async () => {
    mockList.mockResolvedValue({ users: [activeUser], meta: makeMeta(1) })
    renderPage()

    await waitFor(() => screen.getByText('Alice'))
    expect(screen.getByRole('link', { name: 'Edit' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Deactivate' })).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Reactivate' })).not.toBeInTheDocument()
  })
})

describe('UsersIndexPage — Deactivate flow', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockList.mockResolvedValue({ users: [activeUser], meta: makeMeta(1) })
  })

  it('opens deactivate modal on Deactivate click', async () => {
    renderPage()
    await waitFor(() => screen.getByText('Alice'))

    // Click the table row Deactivate button
    fireEvent.click(screen.getByRole('button', { name: 'Deactivate' }))

    expect(screen.getByRole('dialog')).toBeInTheDocument()
    expect(screen.getByText(/Deactivate User/)).toBeInTheDocument()
  })

  it('calls usersApi.deactivate with reason and removes user from list on success', async () => {
    mockDeactivate.mockResolvedValue(undefined)
    renderPage()
    await waitFor(() => screen.getByText('Alice'))

    // Open modal
    fireEvent.click(screen.getByRole('button', { name: 'Deactivate' }))

    const dialog = screen.getByRole('dialog')
    const reasonInput = within(dialog).getByLabelText(/Reason/)
    fireEvent.change(reasonInput, { target: { value: 'Spam account' } })

    // Click the submit button inside the modal
    const submitBtn = within(dialog).getByRole('button', { name: 'Deactivate' })
    fireEvent.click(submitBtn)

    await waitFor(() => {
      expect(mockDeactivate).toHaveBeenCalledWith(1, 'Spam account')
      expect(screen.queryByText('Alice')).not.toBeInTheDocument()
    })
  })

  it('shows error when deactivate fails', async () => {
    mockDeactivate.mockRejectedValue(new Error('Server error'))
    renderPage()
    await waitFor(() => screen.getByText('Alice'))

    fireEvent.click(screen.getByRole('button', { name: 'Deactivate' }))
    const dialog = screen.getByRole('dialog')
    const submitBtn = within(dialog).getByRole('button', { name: 'Deactivate' })
    fireEvent.click(submitBtn)

    await waitFor(() => {
      expect(screen.getByText('Server error')).toBeInTheDocument()
    })
  })
})

describe('UsersIndexPage — Reactivate flow', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockList.mockResolvedValue({ users: [deactivatedUser], meta: makeMeta(1) })
  })

  it('opens reactivate modal on Reactivate click', async () => {
    renderPage()
    await waitFor(() => screen.getByText('Bob'))

    fireEvent.click(screen.getByRole('button', { name: 'Reactivate' }))

    expect(screen.getByRole('dialog')).toBeInTheDocument()
    expect(screen.getByText(/Reactivate User/)).toBeInTheDocument()
  })

  it('happy path: calls reactivate without newEmail and removes user from list on 204', async () => {
    mockReactivate.mockResolvedValue(undefined)
    renderPage()
    await waitFor(() => screen.getByText('Bob'))

    // Open modal
    fireEvent.click(screen.getByRole('button', { name: 'Reactivate' }))

    const dialog = screen.getByRole('dialog')
    // Click the modal submit button
    const submitBtn = within(dialog).getByRole('button', { name: 'Reactivate' })
    fireEvent.click(submitBtn)

    await waitFor(() => {
      expect(mockReactivate).toHaveBeenCalledWith(2, undefined)
      expect(screen.queryByText('Bob')).not.toBeInTheDocument()
    })
  })

  it('conflict path: 422 + original_email_conflict shows inline email input, 2nd call sends new_email', async () => {
    const conflictError = new api.ApiError('Unprocessable Entity', 422, {
      errors: ['Email has already been taken'],
      original_email_conflict: true,
    })
    mockReactivate
      .mockRejectedValueOnce(conflictError)
      .mockResolvedValueOnce(undefined)

    renderPage()
    await waitFor(() => screen.getByText('Bob'))

    // Open modal
    fireEvent.click(screen.getByRole('button', { name: 'Reactivate' }))

    const dialog = screen.getByRole('dialog')

    // 1st attempt — no email input initially
    expect(within(dialog).queryByLabelText(/New Email Address/)).not.toBeInTheDocument()
    const submitBtn = within(dialog).getByRole('button', { name: 'Reactivate' })
    fireEvent.click(submitBtn)

    // After 422 + original_email_conflict, inline email input appears
    await waitFor(() => {
      expect(within(dialog).getByLabelText(/New Email Address/)).toBeInTheDocument()
      expect(screen.getByText(/original email address is already in use/)).toBeInTheDocument()
    })

    // 2nd attempt with new email
    const emailInput = within(dialog).getByLabelText(/New Email Address/)
    fireEvent.change(emailInput, { target: { value: 'bob-new@example.com' } })
    const submitBtn2 = within(dialog).getByRole('button', { name: 'Reactivate' })
    fireEvent.click(submitBtn2)

    await waitFor(() => {
      expect(mockReactivate).toHaveBeenNthCalledWith(1, 2, undefined)
      expect(mockReactivate).toHaveBeenNthCalledWith(2, 2, 'bob-new@example.com')
      expect(screen.queryByText('Bob')).not.toBeInTheDocument()
    })
  })
})
