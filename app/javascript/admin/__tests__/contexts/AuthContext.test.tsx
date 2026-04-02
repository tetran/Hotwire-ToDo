import { render, screen, act, waitFor } from '@testing-library/react'
import { AuthProvider, useAuth } from '@admin/contexts/AuthContext'
import { api, CAPABILITIES_STALE_EVENT, Capabilities } from '@admin/lib/api'

vi.mock('@admin/lib/api', async () => {
  const actual = await vi.importActual('@admin/lib/api')
  return {
    ...actual,
    api: {
      session: {
        current: vi.fn(),
        create: vi.fn(),
        destroy: vi.fn(),
      },
    },
  }
})

const mockSessionCurrent = vi.mocked(api.session.current)

const makeCapabilities = (overrides: Partial<Record<string, Partial<Record<string, boolean>>>> = {}): Capabilities => {
  const defaults = { read: false, write: false, delete: false, manage: false }
  return {
    User: { ...defaults, ...overrides.User },
    Project: { ...defaults, ...overrides.Project },
    Task: { ...defaults, ...overrides.Task },
    Comment: { ...defaults, ...overrides.Comment },
    Admin: { ...defaults, ...overrides.Admin },
    LlmProvider: { ...defaults, ...overrides.LlmProvider },
  }
}

const TestConsumer = () => {
  const { user, loading, refreshing, can } = useAuth()
  return (
    <div>
      <span data-testid="loading">{String(loading)}</span>
      <span data-testid="refreshing">{String(refreshing)}</span>
      <span data-testid="user">{user?.email ?? 'none'}</span>
      <span data-testid="can-user-read">{String(can('User', 'read'))}</span>
    </div>
  )
}

describe('AuthContext capability refresh', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('refreshes capabilities when capabilities-stale event is dispatched', async () => {
    const initialCaps = makeCapabilities({ User: { read: false } })
    const updatedCaps = makeCapabilities({ User: { read: true } })

    mockSessionCurrent
      .mockResolvedValueOnce({ user: { id: 1, email: 'admin@test.com', name: 'Admin', is_admin: true, capabilities: initialCaps } })
      .mockResolvedValueOnce({ user: { id: 1, email: 'admin@test.com', name: 'Admin', is_admin: true, capabilities: updatedCaps } })

    render(<AuthProvider><TestConsumer /></AuthProvider>)

    await waitFor(() => {
      expect(screen.getByTestId('loading').textContent).toBe('false')
    })
    expect(screen.getByTestId('can-user-read').textContent).toBe('false')

    await act(async () => {
      window.dispatchEvent(new Event(CAPABILITIES_STALE_EVENT))
    })

    await waitFor(() => {
      expect(screen.getByTestId('can-user-read').textContent).toBe('true')
    })
    expect(mockSessionCurrent).toHaveBeenCalledTimes(2)
  })

  it('sets refreshing to true during capability refresh', async () => {
    let resolveRefresh: (value: unknown) => void
    const refreshPromise = new Promise(resolve => { resolveRefresh = resolve })

    mockSessionCurrent
      .mockResolvedValueOnce({ user: { id: 1, email: 'admin@test.com', name: 'Admin', is_admin: true, capabilities: makeCapabilities() } })
      .mockReturnValueOnce(refreshPromise as ReturnType<typeof api.session.current>)

    render(<AuthProvider><TestConsumer /></AuthProvider>)

    await waitFor(() => {
      expect(screen.getByTestId('loading').textContent).toBe('false')
    })
    expect(screen.getByTestId('refreshing').textContent).toBe('false')

    act(() => {
      window.dispatchEvent(new Event(CAPABILITIES_STALE_EVENT))
    })

    await waitFor(() => {
      expect(screen.getByTestId('refreshing').textContent).toBe('true')
    })

    await act(async () => {
      resolveRefresh!({ user: { id: 1, email: 'admin@test.com', name: 'Admin', is_admin: true, capabilities: makeCapabilities() } })
    })

    await waitFor(() => {
      expect(screen.getByTestId('refreshing').textContent).toBe('false')
    })
  })

  it('silently handles errors during capability refresh', async () => {
    mockSessionCurrent
      .mockResolvedValueOnce({ user: { id: 1, email: 'admin@test.com', name: 'Admin', is_admin: true, capabilities: makeCapabilities() } })
      .mockRejectedValueOnce(new Error('Network error'))

    render(<AuthProvider><TestConsumer /></AuthProvider>)

    await waitFor(() => {
      expect(screen.getByTestId('loading').textContent).toBe('false')
    })

    // Should not throw
    await act(async () => {
      window.dispatchEvent(new Event(CAPABILITIES_STALE_EVENT))
    })

    await waitFor(() => {
      expect(screen.getByTestId('refreshing').textContent).toBe('false')
    })
    // User should remain unchanged
    expect(screen.getByTestId('user').textContent).toBe('admin@test.com')
  })

  it('cleans up event listener on unmount', async () => {
    mockSessionCurrent
      .mockResolvedValueOnce({ user: { id: 1, email: 'admin@test.com', name: 'Admin', is_admin: true, capabilities: makeCapabilities() } })

    const { unmount } = render(<AuthProvider><TestConsumer /></AuthProvider>)

    await waitFor(() => {
      expect(screen.getByTestId('loading').textContent).toBe('false')
    })

    unmount()

    // Dispatch after unmount should not cause errors or additional calls
    window.dispatchEvent(new Event(CAPABILITIES_STALE_EVENT))
    await new Promise(resolve => setTimeout(resolve, 50))

    // Only the initial mount call
    expect(mockSessionCurrent).toHaveBeenCalledTimes(1)
  })
})
