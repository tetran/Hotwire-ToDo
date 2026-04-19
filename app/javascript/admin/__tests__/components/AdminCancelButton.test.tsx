import { render, screen, fireEvent } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { AdminCancelButton } from '@admin/components/AdminCancelButton'

const mockNavigate = vi.fn()
vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom')
  return {
    ...actual,
    useNavigate: () => mockNavigate,
  }
})

const renderComponent = (to: string) =>
  render(
    <MemoryRouter>
      <AdminCancelButton to={to} />
    </MemoryRouter>
  )

describe('AdminCancelButton', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders the fixed label "Cancel"', () => {
    renderComponent('/admin/users')
    expect(screen.getByText('Cancel')).toBeInTheDocument()
  })

  it('has accessible role of button', () => {
    renderComponent('/admin/users')
    expect(screen.getByRole('button', { name: 'Cancel' })).toBeInTheDocument()
  })

  it('has type="button" attribute to prevent form submit', () => {
    renderComponent('/admin/users')
    const button = screen.getByRole('button', { name: 'Cancel' })
    expect(button).toHaveAttribute('type', 'button')
  })

  it('calls navigate(to) when clicked', () => {
    renderComponent('/admin/roles')
    fireEvent.click(screen.getByRole('button', { name: 'Cancel' }))
    expect(mockNavigate).toHaveBeenCalledWith('/admin/roles')
  })
})
