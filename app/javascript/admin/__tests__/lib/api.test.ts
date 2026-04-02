import { api, resetRedirectGuard } from '@admin/lib/api'

describe('apiRequest 401 handling', () => {
  const originalLocation = window.location

  beforeEach(() => {
    resetRedirectGuard()
    Object.defineProperty(window, 'location', {
      writable: true,
      value: { ...originalLocation, href: '' },
    })
    vi.spyOn(document, 'querySelector').mockReturnValue({
      content: 'test-csrf-token',
    } as HTMLMetaElement)
  })

  afterEach(() => {
    Object.defineProperty(window, 'location', {
      writable: true,
      value: originalLocation,
    })
    vi.restoreAllMocks()
    globalThis.fetch = originalFetch
  })

  const originalFetch = globalThis.fetch

  const mockFetch = (status: number, body: unknown = {}) => {
    globalThis.fetch = vi.fn().mockResolvedValue({
      ok: status >= 200 && status < 300,
      status,
      json: () => Promise.resolve(body),
    })
  }

  it('redirects to /admin/login on 401 for non-session endpoints', async () => {
    mockFetch(401, { error: 'Unauthorized' })

    const promise = api.get('/users')

    // Give the async function time to execute
    await vi.waitFor(() => {
      expect(window.location.href).toBe('/admin/login')
    })

    // The promise should never resolve
    const result = await Promise.race([
      promise.then(() => 'resolved').catch(() => 'rejected'),
      new Promise(resolve => setTimeout(() => resolve('pending'), 50)),
    ])
    expect(result).toBe('pending')
  })

  it('does NOT redirect on 401 for GET /session (AuthProvider mount)', async () => {
    mockFetch(401, { error: 'Unauthorized' })

    await expect(api.session.current()).rejects.toThrow('Unauthorized')
    expect(window.location.href).not.toBe('/admin/login')
  })

  it('does NOT redirect on 401 for POST /session (login failure)', async () => {
    mockFetch(401, { error: 'Unauthorized' })

    await expect(
      api.session.create({ email: 'a@b.com', password: 'wrong' })
    ).rejects.toThrow('Unauthorized')
    expect(window.location.href).not.toBe('/admin/login')
  })

  it('does NOT redirect on 401 for DELETE /session (logout)', async () => {
    mockFetch(401, { error: 'Unauthorized' })

    await expect(api.session.destroy()).rejects.toThrow('Unauthorized')
    expect(window.location.href).not.toBe('/admin/login')
  })

  it('sets window.location.href only once for concurrent 401 responses', async () => {
    mockFetch(401, { error: 'Unauthorized' })

    // Fire multiple requests concurrently
    api.get('/users')
    api.get('/roles')
    api.get('/permissions')

    await vi.waitFor(() => {
      expect(window.location.href).toBe('/admin/login')
    })

    // fetch was called 3 times but location.href was set only once
    // (subsequent calls return pending promise without setting href again)
    const hrefSetter = vi.fn()
    Object.defineProperty(window, 'location', {
      writable: true,
      value: new Proxy({ href: '/admin/login' }, {
        set: (target, prop, value) => {
          if (prop === 'href') hrefSetter(value)
          target[prop as keyof typeof target] = value as never
          return true
        },
      }),
    })

    // Fire more requests after guard is set
    api.get('/dashboard')
    await new Promise(resolve => setTimeout(resolve, 50))

    // href should not be set again because guard is already active
    expect(hrefSetter).not.toHaveBeenCalled()
  })

  it('returns data normally for 200 responses', async () => {
    mockFetch(200, { id: 1, name: 'Test' })

    const result = await api.get<{ id: number; name: string }>('/users')
    expect(result).toEqual({ id: 1, name: 'Test' })
    expect(window.location.href).not.toBe('/admin/login')
  })

  it('returns undefined for 204 responses', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue({
      ok: true,
      status: 204,
      json: () => Promise.resolve(undefined),
    })

    const result = await api.delete('/users/1')
    expect(result).toBeUndefined()
  })

  it('throws error for non-401 error responses', async () => {
    mockFetch(403, { error: 'Forbidden' })

    await expect(api.get('/users')).rejects.toThrow('Forbidden')
    expect(window.location.href).not.toBe('/admin/login')
  })
})
