import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

// Mock @sentry/react: keep real exports, spy on init + captureMessage
vi.mock('@sentry/react', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@sentry/react')>()
  return {
    ...actual,
    init: vi.fn(),
    captureMessage: vi.fn(),
  }
})

// Helper to dynamically import a fresh module instance each test
const loadSentry = () => import('@admin/lib/sentry')

describe('initSentry', () => {
  const originalHead = document.head.innerHTML

  beforeEach(() => {
    vi.resetModules()
    vi.clearAllMocks()
    document.head.innerHTML = originalHead
  })

  afterEach(() => {
    document.head.innerHTML = originalHead
    vi.unstubAllEnvs()
    vi.restoreAllMocks()
  })

  it('does NOT call Sentry.init when MODE=test (Vitest default)', async () => {
    // Vitest sets import.meta.env.MODE = 'test' by default
    document.head.innerHTML = '<meta name="sentry-dsn" content="https://dsn@sentry.io/1">'
    const { initSentry } = await loadSentry()
    const Sentry = await import('@sentry/react')

    initSentry()

    expect(Sentry.init).not.toHaveBeenCalled()
  })

  it('does NOT call Sentry.init when DSN is empty (non-production)', async () => {
    vi.stubEnv('MODE', 'development')
    document.head.innerHTML = '<meta name="sentry-dsn" content="">'
    const { initSentry } = await loadSentry()
    const Sentry = await import('@sentry/react')

    initSentry()

    expect(Sentry.init).not.toHaveBeenCalled()
  })

  it('emits console.warn in production when DSN is empty', async () => {
    vi.stubEnv('MODE', 'production')
    document.head.innerHTML = '<meta name="sentry-dsn" content="">'
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
    const { initSentry } = await loadSentry()

    initSentry()

    expect(warn).toHaveBeenCalledWith('[sentry] DSN not set; truncation warnings will not be reported')
  })

  it('does NOT emit console.warn in development when DSN is empty', async () => {
    vi.stubEnv('MODE', 'development')
    document.head.innerHTML = '<meta name="sentry-dsn" content="">'
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
    const { initSentry } = await loadSentry()

    initSentry()

    expect(warn).not.toHaveBeenCalled()
  })

  it('calls Sentry.init with dsn and environment when DSN is set (non-test mode)', async () => {
    vi.stubEnv('MODE', 'production')
    const dsn = 'https://key@sentry.io/123'
    document.head.innerHTML = `<meta name="sentry-dsn" content="${dsn}">`
    const { initSentry } = await loadSentry()
    const Sentry = await import('@sentry/react')

    initSentry()

    expect(Sentry.init).toHaveBeenCalledWith({ dsn, environment: 'production' })
  })
})

describe('reportTruncation', () => {
  const originalHead = document.head.innerHTML
  const dsn = 'https://key@sentry.io/123'

  // Each test gets a fresh module with sentryEnabled = true (production DSN set)
  const setupEnabled = async () => {
    vi.resetModules()
    vi.clearAllMocks()
    vi.stubEnv('MODE', 'production')
    document.head.innerHTML = `<meta name="sentry-dsn" content="${dsn}">`
    const { initSentry, reportTruncation } = await loadSentry()
    const Sentry = await import('@sentry/react')
    initSentry()
    return { reportTruncation, Sentry }
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  afterEach(() => {
    document.head.innerHTML = originalHead
    vi.unstubAllEnvs()
    vi.restoreAllMocks()
  })

  it('fires captureMessage with correct payload on truncation', async () => {
    const { reportTruncation, Sentry } = await setupEnabled()

    reportTruncation({ resource: 'roles', fetched: 100, total_count: 150, per_page: 100 })

    expect(Sentry.captureMessage).toHaveBeenCalledWith('Admin dropdown data truncated', {
      level: 'warning',
      tags: { resource: 'roles' },
      contexts: { pagination: { fetched: 100, total_count: 150, per_page: 100 } },
      fingerprint: ['admin-pagination-truncated', 'roles'],
    })
  })

  it('is no-op when total_count === fetched (no truncation)', async () => {
    const { reportTruncation, Sentry } = await setupEnabled()

    reportTruncation({ resource: 'roles', fetched: 100, total_count: 100, per_page: 100 })

    expect(Sentry.captureMessage).not.toHaveBeenCalled()
  })

  it('is no-op when per_page !== 100', async () => {
    const { reportTruncation, Sentry } = await setupEnabled()

    reportTruncation({ resource: 'roles', fetched: 20, total_count: 150, per_page: 20 })

    expect(Sentry.captureMessage).not.toHaveBeenCalled()
  })

  it('is no-op when fetched < per_page (cap not reached)', async () => {
    const { reportTruncation, Sentry } = await setupEnabled()

    reportTruncation({ resource: 'roles', fetched: 50, total_count: 150, per_page: 100 })

    expect(Sentry.captureMessage).not.toHaveBeenCalled()
  })

  it('deduplicates: 2nd call for same resource is no-op', async () => {
    const { reportTruncation, Sentry } = await setupEnabled()

    reportTruncation({ resource: 'roles', fetched: 100, total_count: 150, per_page: 100 })
    reportTruncation({ resource: 'roles', fetched: 100, total_count: 150, per_page: 100 })

    expect(Sentry.captureMessage).toHaveBeenCalledTimes(1)
  })

  it('allows different resources independently', async () => {
    const { reportTruncation, Sentry } = await setupEnabled()

    reportTruncation({ resource: 'roles', fetched: 100, total_count: 150, per_page: 100 })
    reportTruncation({ resource: 'permissions', fetched: 100, total_count: 200, per_page: 100 })

    expect(Sentry.captureMessage).toHaveBeenCalledTimes(2)
  })

  it('is no-op when sentryEnabled is false (no initSentry called)', async () => {
    vi.resetModules()
    // Do NOT call initSentry — leave sentryEnabled = false
    const { reportTruncation } = await loadSentry()
    const Sentry = await import('@sentry/react')

    reportTruncation({ resource: 'roles', fetched: 100, total_count: 150, per_page: 100 })

    expect(Sentry.captureMessage).not.toHaveBeenCalled()
  })

  // Guard #2: non-finite values
  const nonFiniteValues = [undefined, NaN, Infinity] as const

  describe.each([
    ['fetched', (v: number | undefined) => ({ resource: 'roles', fetched: v, total_count: 150, per_page: 100 as number | undefined })],
    ['total_count', (v: number | undefined) => ({ resource: 'roles', fetched: 100, total_count: v, per_page: 100 as number | undefined })],
    ['per_page', (v: number | undefined) => ({ resource: 'roles', fetched: 100, total_count: 150, per_page: v })],
  ])('non-finite %s', (_field, makeParams) => {
    it.each(nonFiniteValues)('is no-op when value is %s', async (val) => {
      const { reportTruncation, Sentry } = await setupEnabled()

      reportTruncation(makeParams(val) as Parameters<typeof reportTruncation>[0])

      expect(Sentry.captureMessage).not.toHaveBeenCalled()
    })
  })

  // Ordering invariant: non-finite input must NOT consume dedup budget
  it('ordering invariant: non-finite call does not consume dedup slot, valid call fires', async () => {
    const { reportTruncation, Sentry } = await setupEnabled()

    // First call: non-finite fetched — should be no-op (guard #2 fires before guard #6)
    reportTruncation({ resource: 'roles', fetched: NaN, total_count: 150, per_page: 100 })
    expect(Sentry.captureMessage).not.toHaveBeenCalled()

    // Second call: valid — dedup slot must still be free, so this should fire
    reportTruncation({ resource: 'roles', fetched: 100, total_count: 150, per_page: 100 })
    expect(Sentry.captureMessage).toHaveBeenCalledTimes(1)
  })
})
