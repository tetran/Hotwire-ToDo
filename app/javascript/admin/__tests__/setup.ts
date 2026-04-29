import '@testing-library/jest-dom/vitest'

// window.matchMedia polyfill for jsdom (jsdom does not implement matchMedia).
// Individual tests can override per-test with:
//   beforeEach(() => { window.matchMedia = vi.fn().mockImplementation(query => ({ matches: false, ... })) })
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation((query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
})
