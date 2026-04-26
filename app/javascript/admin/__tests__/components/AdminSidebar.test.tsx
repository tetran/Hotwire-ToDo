import { fireEvent, render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { AdminSidebar } from '../../components/AdminSidebar'
import { makeMatchMedia } from '../helpers/matchMedia'

const defaultProps = {
  isDesktop: true,
  isDesktopExpanded: true,
  isMobileOpen: false,
  onToggleDesktop: vi.fn(),
  onCloseMobile: vi.fn(),
  user: { name: 'Test Admin', email: 'admin@example.com' },
  logout: vi.fn(),
  can: vi.fn().mockReturnValue(true),
}

const renderSidebar = (props: Partial<typeof defaultProps> = {}) =>
  render(
    <MemoryRouter initialEntries={['/admin']}>
      <AdminSidebar {...defaultProps} {...props} />
    </MemoryRouter>
  )

describe('AdminSidebar', () => {
  beforeEach(() => {
    window.matchMedia = makeMatchMedia(true)
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  // Case 1: Expanded mode renders visible labels for all nav items
  it('renders visible nav item labels when expanded', () => {
    renderSidebar({ isDesktop: true, isDesktopExpanded: true })

    expect(screen.getByText('Dashboard')).toBeInTheDocument()
    expect(screen.getByText('Users')).toBeInTheDocument()
    expect(screen.getByText('Admin Accounts')).toBeInTheDocument()

    // Labels should NOT have sr-only class (they should be visible)
    const dashboardLabel = screen.getByText('Dashboard')
    expect(dashboardLabel).not.toHaveClass('sr-only')
  })

  // Case 2: Collapsed mode applies sr-only to labels and aria-label on links
  it('applies sr-only to labels and aria-label on links when collapsed', () => {
    renderSidebar({ isDesktop: true, isDesktopExpanded: false })

    // The <span> label (not the tooltip) should have sr-only class.
    // getAllByText because the text appears in both the sr-only span and the tooltip span.
    const dashboardTextNodes = screen.getAllByText('Dashboard')
    const srOnlyNode = dashboardTextNodes.find((el) => el.classList.contains('sr-only'))
    expect(srOnlyNode).toBeTruthy()

    // Links have aria-label when collapsed
    const dashboardLink = screen.getByRole('link', { name: 'Dashboard' })
    expect(dashboardLink).toHaveAttribute('aria-label', 'Dashboard')
  })

  // Case 3: Visual tooltip span is rendered when collapsed (CSS handles opacity).
  // The span is aria-hidden — AT users get the link label via aria-label on the <Link>.
  it('renders visual tooltip spans when collapsed', () => {
    renderSidebar({ isDesktop: true, isDesktopExpanded: false })

    const visualTooltips = document.querySelectorAll('span[aria-hidden="true"].pointer-events-none')
    expect(visualTooltips.length).toBeGreaterThan(0)
    expect(visualTooltips[0]).toHaveTextContent('Dashboard')
  })

  // Case 4: Visual tooltip spans are in DOM regardless of focus (CSS group-focus-within shows them on Tab)
  it('visual tooltip spans are in DOM for keyboard navigation when collapsed', () => {
    renderSidebar({ isDesktop: true, isDesktopExpanded: false })

    const visualTooltips = document.querySelectorAll('span[aria-hidden="true"].pointer-events-none')
    expect(visualTooltips.length).toBeGreaterThan(0)
  })

  // Case 5: Clicking the desktop toggle button calls onToggleDesktop
  it('calls onToggleDesktop when chevron toggle button is clicked', () => {
    const onToggleDesktop = vi.fn()
    renderSidebar({ isDesktop: true, isDesktopExpanded: true, onToggleDesktop })

    const toggleButton = screen.getByRole('button', { name: 'Collapse sidebar' })
    fireEvent.click(toggleButton)

    expect(onToggleDesktop).toHaveBeenCalledTimes(1)
  })

  // Case 6 (B1): Mobile mode renders in-drawer close button; clicking calls onCloseMobile
  it('renders in-drawer close button on mobile and calls onCloseMobile on click', () => {
    const onCloseMobile = vi.fn()
    renderSidebar({ isDesktop: false, isMobileOpen: true, onCloseMobile })

    const closeButton = screen.getByRole('button', { name: 'Close navigation' })
    expect(closeButton).toBeInTheDocument()

    fireEvent.click(closeButton)
    expect(onCloseMobile).toHaveBeenCalledTimes(1)
  })
})
