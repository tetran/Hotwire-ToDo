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

  it('has accessible role of link', () => {
    renderComponent('/admin/admin-accounts', 'Admin Accounts')
    expect(screen.getByRole('link', { name: /Admin Accounts/i })).toBeInTheDocument()
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

  it('exposes "Back to {label}" as the accessible name via aria-label', () => {
    renderComponent('/admin/users', 'Users')
    expect(screen.getByRole('link', { name: 'Back to Users' })).toBeInTheDocument()
  })
})
