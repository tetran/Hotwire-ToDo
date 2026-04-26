import { fireEvent, render } from '@testing-library/react'
import { AdminSidebarBackdrop } from '../../components/AdminSidebarBackdrop'

describe('AdminSidebarBackdrop', () => {
  it('renders nothing when isOpen is false', () => {
    const { container } = render(
      <AdminSidebarBackdrop isOpen={false} isDesktop={false} onClose={vi.fn()} />
    )
    expect(container.firstChild).toBeNull()
  })

  it('renders nothing when isDesktop is true (desktop mode)', () => {
    const { container } = render(
      <AdminSidebarBackdrop isOpen={true} isDesktop={true} onClose={vi.fn()} />
    )
    expect(container.firstChild).toBeNull()
  })

  it('calls onClose when backdrop is clicked', () => {
    const onClose = vi.fn()
    render(<AdminSidebarBackdrop isOpen={true} isDesktop={false} onClose={onClose} />)

    const backdrop = document.querySelector('[aria-hidden="true"]') as HTMLElement
    fireEvent.click(backdrop)

    expect(onClose).toHaveBeenCalledTimes(1)
  })
})
