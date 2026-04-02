import { render, screen } from '@testing-library/react'
import Badge from '@admin/components/Badge'

describe('Badge', () => {
  it('renders children text', () => {
    render(<Badge>Active</Badge>)
    expect(screen.getByText('Active')).toBeInTheDocument()
  })

  it('applies neutral variant classes by default', () => {
    render(<Badge>Default</Badge>)
    const badge = screen.getByText('Default')
    expect(badge).toHaveClass('text-slate-400')
  })

  it('applies success variant classes', () => {
    render(<Badge variant="success">Success</Badge>)
    const badge = screen.getByText('Success')
    expect(badge).toHaveClass('text-emerald-400')
  })

  it('applies danger variant classes', () => {
    render(<Badge variant="danger">Error</Badge>)
    const badge = screen.getByText('Error')
    expect(badge).toHaveClass('text-rose-400')
  })

  it('applies info variant classes', () => {
    render(<Badge variant="info">Info</Badge>)
    const badge = screen.getByText('Info')
    expect(badge).toHaveClass('text-indigo-400')
  })

  it('applies warning variant classes', () => {
    render(<Badge variant="warning">Warning</Badge>)
    const badge = screen.getByText('Warning')
    expect(badge).toHaveClass('text-amber-400')
  })

  it('renders as an inline-flex span', () => {
    render(<Badge>Test</Badge>)
    const badge = screen.getByText('Test')
    expect(badge.tagName).toBe('SPAN')
    expect(badge).toHaveClass('inline-flex')
  })
})
