import { vi } from 'vitest'

/**
 * Build a `window.matchMedia` mock that responds to the desktop breakpoint query
 * (`(min-width: 768px)`) with the given `isDesktop` value. Other queries report `false`.
 *
 * Per-test override pattern (used by tests that need to fire `change` events):
 * `window.matchMedia = vi.fn().mockImplementation(...)` in `beforeEach`.
 */
export function makeMatchMedia(isDesktop: boolean) {
  return vi.fn().mockImplementation((query: string) => ({
    matches: query === '(min-width: 768px)' ? isDesktop : false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  }))
}
