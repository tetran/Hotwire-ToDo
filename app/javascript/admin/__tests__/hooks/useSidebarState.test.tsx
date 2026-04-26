import { act, renderHook } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { useSidebarState } from '../../hooks/useSidebarState'
import { makeMatchMedia } from '../helpers/matchMedia'

describe('useSidebarState', () => {
  beforeEach(() => {
    localStorage.clear()
    // Default: desktop viewport
    window.matchMedia = makeMatchMedia(true)
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  // Case 1: Default state when no localStorage entries.
  // Desktop expanded (additive — sidebar is in normal flow).
  // Mobile closed (off-canvas drawer should not obscure content by default).
  it('defaults to desktop=expanded, mobile=closed when localStorage has no entries', () => {
    const { result } = renderHook(() => useSidebarState())
    expect(result.current.isDesktopExpanded).toBe(true)
    expect(result.current.isMobileOpen).toBe(false)
  })

  // Case 2: Reads existing localStorage values
  it('reads existing localStorage values', () => {
    localStorage.setItem('admin.sidebar.desktop', 'collapsed')
    localStorage.setItem('admin.sidebar.mobile', 'closed')
    const { result } = renderHook(() => useSidebarState())
    expect(result.current.isDesktopExpanded).toBe(false)
    expect(result.current.isMobileOpen).toBe(false)
  })

  // Case 3: toggleDesktop flips state and writes the correct key
  it('toggleDesktop flips state and persists to localStorage', () => {
    const { result } = renderHook(() => useSidebarState())
    expect(result.current.isDesktopExpanded).toBe(true)

    act(() => result.current.toggleDesktop())

    expect(result.current.isDesktopExpanded).toBe(false)
    expect(localStorage.getItem('admin.sidebar.desktop')).toBe('collapsed')

    act(() => result.current.toggleDesktop())

    expect(result.current.isDesktopExpanded).toBe(true)
    expect(localStorage.getItem('admin.sidebar.desktop')).toBe('expanded')
  })

  // Case 4: toggleMobile flips state and writes the correct key
  it('toggleMobile flips state and persists to localStorage', () => {
    const { result } = renderHook(() => useSidebarState())
    expect(result.current.isMobileOpen).toBe(false)

    act(() => result.current.toggleMobile())

    expect(result.current.isMobileOpen).toBe(true)
    expect(localStorage.getItem('admin.sidebar.mobile')).toBe('open')

    act(() => result.current.toggleMobile())

    expect(result.current.isMobileOpen).toBe(false)
    expect(localStorage.getItem('admin.sidebar.mobile')).toBe('closed')
  })

  // Case 5: localStorage write failure is swallowed; in-memory state still flips
  it('swallows localStorage write errors and still flips in-memory state', () => {
    vi.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {
      throw new Error('QuotaExceededError')
    })

    const { result } = renderHook(() => useSidebarState())
    act(() => result.current.toggleDesktop())

    expect(result.current.isDesktopExpanded).toBe(false)
  })

  // Case 6: matchMedia change false→true (mobile→desktop) closes mobile in memory
  it('closes mobile in memory when viewport crosses to desktop', () => {
    // Pre-seed mobile=open so we can observe the in-memory close on viewport crossing.
    localStorage.setItem('admin.sidebar.mobile', 'open')

    // Capture the addEventListener calls so we can fire the change event
    const listeners: Array<(e: MediaQueryListEvent) => void> = []
    window.matchMedia = vi.fn().mockImplementation((query: string) => ({
      matches: false,
      media: query,
      onchange: null,
      addListener: vi.fn(),
      removeListener: vi.fn(),
      addEventListener: vi.fn().mockImplementation(
        (_event: string, handler: (e: MediaQueryListEvent) => void) => {
          listeners.push(handler)
        }
      ),
      removeEventListener: vi.fn(),
      dispatchEvent: vi.fn(),
    }))

    const { result } = renderHook(() => useSidebarState())
    expect(result.current.isMobileOpen).toBe(true)

    // Simulate crossing to desktop
    act(() => {
      listeners.forEach((fn) =>
        fn({ matches: true } as MediaQueryListEvent)
      )
    })

    expect(result.current.isMobileOpen).toBe(false)
    expect(result.current.isDesktop).toBe(true)
  })

  // Case 7 (S1): mobile→desktop transition does NOT mutate admin.sidebar.mobile in localStorage
  it('does not write admin.sidebar.mobile when crossing mobile→desktop', () => {
    const listeners: Array<(e: MediaQueryListEvent) => void> = []
    window.matchMedia = vi.fn().mockImplementation((query: string) => ({
      matches: false,
      media: query,
      onchange: null,
      addListener: vi.fn(),
      removeListener: vi.fn(),
      addEventListener: vi.fn().mockImplementation(
        (_event: string, handler: (e: MediaQueryListEvent) => void) => {
          listeners.push(handler)
        }
      ),
      removeEventListener: vi.fn(),
      dispatchEvent: vi.fn(),
    }))

    renderHook(() => useSidebarState())

    const setItemSpy = vi.spyOn(Storage.prototype, 'setItem')

    act(() => {
      listeners.forEach((fn) =>
        fn({ matches: true } as MediaQueryListEvent)
      )
    })

    const mobileWrites = setItemSpy.mock.calls.filter(
      ([key]) => key === 'admin.sidebar.mobile'
    )
    expect(mobileWrites).toHaveLength(0)
  })

  // Case 8: Esc keydown when isMobileOpen && !isDesktop calls closeMobile
  it('closes mobile drawer on Esc key when mobile is open', () => {
    window.matchMedia = makeMatchMedia(false)
    localStorage.setItem('admin.sidebar.mobile', 'open')

    const { result } = renderHook(() => useSidebarState())
    expect(result.current.isMobileOpen).toBe(true)

    act(() => {
      document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }))
    })

    expect(result.current.isMobileOpen).toBe(false)
  })

  // Case 9 (S1): Esc keydown on desktop is a no-op (does not toggle desktop expanded state)
  it('Esc key on desktop does not change isDesktopExpanded', () => {
    window.matchMedia = makeMatchMedia(true)

    const { result } = renderHook(() => useSidebarState())
    const before = result.current.isDesktopExpanded

    act(() => {
      document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }))
    })

    expect(result.current.isDesktopExpanded).toBe(before)
  })

  // Case 11 (H2): desktop→mobile transition rehydrates isMobileOpen from localStorage
  it('rehydrates isMobileOpen from localStorage on desktop→mobile transition', () => {
    // Start desktop, with mobile previously saved as 'open'
    localStorage.setItem('admin.sidebar.mobile', 'open')

    const listeners: Array<(e: MediaQueryListEvent) => void> = []
    window.matchMedia = vi.fn().mockImplementation((query: string) => ({
      matches: true,
      media: query,
      onchange: null,
      addListener: vi.fn(),
      removeListener: vi.fn(),
      addEventListener: vi.fn().mockImplementation(
        (_event: string, handler: (e: MediaQueryListEvent) => void) => {
          listeners.push(handler)
        }
      ),
      removeEventListener: vi.fn(),
      dispatchEvent: vi.fn(),
    }))

    const { result } = renderHook(() => useSidebarState())
    expect(result.current.isDesktop).toBe(true)

    // Simulate crossing to mobile
    act(() => {
      listeners.forEach((fn) => fn({ matches: false } as MediaQueryListEvent))
    })

    expect(result.current.isDesktop).toBe(false)
    expect(result.current.isMobileOpen).toBe(true)
  })

  // Case 10 (S1): Unmount removes the keydown listener
  it('removes keydown listener on unmount', () => {
    const removeSpy = vi.spyOn(document, 'removeEventListener')

    const { unmount } = renderHook(() => useSidebarState())
    unmount()

    const keydownRemovals = removeSpy.mock.calls.filter(
      ([event]) => event === 'keydown'
    )
    expect(keydownRemovals.length).toBeGreaterThanOrEqual(1)
  })
})
