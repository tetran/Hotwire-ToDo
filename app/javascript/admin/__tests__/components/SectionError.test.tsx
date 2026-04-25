import { render, screen, fireEvent } from '@testing-library/react'
import { SectionError } from '@admin/components/SectionError'

describe('SectionError', () => {
  it('renders default message when only title is provided', () => {
    render(<SectionError title="モデル一覧" />)
    expect(screen.getByText('モデル一覧')).toBeInTheDocument()
    expect(
      screen.getByText(
        'モデル一覧を取得できませんでした。時間を置いて再度お試しください'
      )
    ).toBeInTheDocument()
  })

  it('renders explicit message overriding the default', () => {
    render(<SectionError title="モデル一覧" message="サーバーエラーが発生しました" />)
    expect(
      screen.getByText('サーバーエラーが発生しました')
    ).toBeInTheDocument()
    expect(
      screen.queryByText(
        'モデル一覧を取得できませんでした。時間を置いて再度お試しください'
      )
    ).not.toBeInTheDocument()
  })

  it('shows retry button when onRetry is provided', () => {
    render(<SectionError title="モデル一覧" onRetry={() => {}} />)
    expect(screen.getByRole('button', { name: '再試行' })).toBeInTheDocument()
  })

  it('does not show retry button when onRetry is not provided', () => {
    render(<SectionError title="モデル一覧" />)
    expect(screen.queryByRole('button', { name: '再試行' })).not.toBeInTheDocument()
  })

  it('calls onRetry callback when retry button is clicked', () => {
    const onRetry = vi.fn()
    render(<SectionError title="モデル一覧" onRetry={onRetry} />)
    fireEvent.click(screen.getByRole('button', { name: '再試行' }))
    expect(onRetry).toHaveBeenCalledTimes(1)
  })

  it('sets data-layout="stacked" on root element when layout="stacked"', () => {
    const { container } = render(<SectionError title="モデル一覧" layout="stacked" />)
    expect(container.firstChild).toHaveAttribute('data-layout', 'stacked')
  })

  it('sets data-layout="inline" on root element when layout="inline"', () => {
    const { container } = render(<SectionError title="モデル一覧" layout="inline" />)
    expect(container.firstChild).toHaveAttribute('data-layout', 'inline')
  })

  it('defaults to layout="inline" when layout prop is omitted', () => {
    const { container } = render(<SectionError title="モデル一覧" />)
    expect(container.firstChild).toHaveAttribute('data-layout', 'inline')
  })

  it('has role="status" on root element (implicit polite aria-live, non-interrupting)', () => {
    render(<SectionError title="モデル一覧" />)
    expect(screen.getByRole('status')).toBeInTheDocument()
  })

  it('does not set explicit aria-live (role="status" provides implicit polite)', () => {
    render(<SectionError title="モデル一覧" />)
    const status = screen.getByRole('status')
    expect(status).not.toHaveAttribute('aria-live')
  })

  it('applies danger container classes', () => {
    render(<SectionError title="モデル一覧" />)
    const status = screen.getByRole('status')
    expect(status).toHaveClass('rounded-xl')
    expect(status).toHaveClass('border-rose-500/30')
    expect(status).toHaveClass('bg-rose-500/10')
  })

  it('applies semibold rose-400 class to title', () => {
    render(<SectionError title="モデル一覧" />)
    const title = screen.getByText('モデル一覧')
    expect(title).toHaveClass('font-semibold')
    expect(title).toHaveClass('text-rose-400')
  })

  it('applies text-sm rose-400/80 class to message', () => {
    render(<SectionError title="モデル一覧" />)
    const message = screen.getByText(
      'モデル一覧を取得できませんでした。時間を置いて再度お試しください'
    )
    expect(message).toHaveClass('text-sm')
    expect(message).toHaveClass('text-rose-400/80')
  })
})
