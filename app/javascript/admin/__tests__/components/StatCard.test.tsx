import { render, screen, within } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import StatCard from '@admin/components/StatCard'

const renderCard = (props: Parameters<typeof StatCard>[0]) =>
  render(
    <MemoryRouter>
      <StatCard {...props} />
    </MemoryRouter>
  )

const baseProps = {
  label: 'Total Users',
  value: 10,
  icon: <span data-testid="stat-icon">i</span>,
}

describe('StatCard', () => {
  it('renders as a non-link <div> when `to` is not provided', () => {
    renderCard({ ...baseProps, subtitle: '3 Roles Defined' })
    expect(screen.queryByRole('link')).toBeNull()
    expect(screen.getByText('Total Users')).toBeInTheDocument()
    expect(screen.getByText('10')).toBeInTheDocument()
    expect(screen.getByText('3 Roles Defined')).toBeInTheDocument()
  })

  it('renders as a <Link> with the correct href when `to` is provided', () => {
    renderCard({ ...baseProps, subtitle: 'View all users →', to: '/admin/users' })
    const link = screen.getByRole('link')
    expect(link).toHaveAttribute('href', '/admin/users')
    expect(within(link).getByText('Total Users')).toBeInTheDocument()
    expect(within(link).getByText('10')).toBeInTheDocument()
    expect(within(link).getByText('View all users →')).toBeInTheDocument()
    expect(within(link).getByTestId('stat-icon')).toBeInTheDocument()
  })

  it('applies hover transition classes when `to` is provided', () => {
    renderCard({ ...baseProps, subtitle: 'View all users →', to: '/admin/users' })
    const link = screen.getByRole('link')
    expect(link.className).toContain('transition-colors')
    expect(link.className).toContain('hover:border-indigo-300')
    expect(link.className).toContain('focus-visible:ring-accent')
  })

  it('does not apply hover transition classes when `to` is omitted', () => {
    const { container } = renderCard({ ...baseProps, subtitle: '3 Roles Defined' })
    const wrapper = container.firstChild as HTMLElement
    expect(wrapper.className).not.toContain('hover:border-indigo-300')
    expect(wrapper.className).not.toContain('transition-colors')
  })
})
