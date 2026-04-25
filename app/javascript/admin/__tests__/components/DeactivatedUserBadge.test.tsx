import { render, screen } from '@testing-library/react'
import { DeactivatedUserBadge } from '@admin/components/DeactivatedUserBadge'

describe('DeactivatedUserBadge', () => {
  it('renders Deactivated text', () => {
    render(<DeactivatedUserBadge />)
    expect(screen.getByText('Deactivated')).toBeInTheDocument()
  })

  it('has neutral slate styling', () => {
    render(<DeactivatedUserBadge />)
    const badge = screen.getByText('Deactivated')
    expect(badge).toHaveClass('bg-slate-500/15')
    expect(badge).toHaveClass('text-slate-400')
    expect(badge).toHaveClass('ring-slate-500/30')
  })
})
