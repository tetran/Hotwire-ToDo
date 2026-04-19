import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { AdminBackLink } from '@admin/components/AdminBackLink'

const renderComponent = (to: string, label: string) =>
  render(
    <MemoryRouter>
      <AdminBackLink to={to} label={label} />
    </MemoryRouter>
  )

describe('AdminBackLink', () => {
  it('renders the label text', () => {
    renderComponent('/admin/users', 'Users')
    expect(screen.getByText('Users')).toBeInTheDocument()
  })

  it('renders as a link with the correct href', () => {
    renderComponent('/admin/users', 'Users')
    const link = screen.getByRole('link')
    expect(link).toHaveAttribute('href', '/admin/users')
  })

  it('exposes the accessible name "Back to {label}" via aria-label', () => {
    renderComponent('/admin/admin-accounts', 'Admin Accounts')
    expect(screen.getByRole('link', { name: 'Back to Admin Accounts' })).toBeInTheDocument()
  })

  it('renders the back arrow with aria-hidden', () => {
    const { container } = renderComponent('/admin/users', 'Users')
    const arrow = container.querySelector('[aria-hidden="true"]')
    expect(arrow).toBeInTheDocument()
    expect(arrow?.textContent).toBe('←')
  })

  it('includes hover color class for indigo', () => {
    renderComponent('/admin/users', 'Users')
    const link = screen.getByRole('link')
    expect(link.className).toContain('hover:text-[#6366f1]')
  })
})
