import * as Sentry from '@sentry/react'
import { DROPDOWN_PER_PAGE } from './api'

let sentryEnabled = false
const reportedResources = new Set<string>()

export const initSentry = (): void => {
  // belt-and-suspenders: never run real Sentry init in Vitest / unit test mode
  if (import.meta.env.MODE === 'test') return

  const meta = document.querySelector<HTMLMetaElement>('meta[name="sentry-dsn"]')
  const dsn = meta?.content ?? ''

  if (!dsn) {
    if (import.meta.env.MODE === 'production') {
      // eslint-disable-next-line no-console -- ops silent-failure signal
      console.warn('[sentry] DSN not set; truncation warnings will not be reported')
    }
    return
  }

  Sentry.init({ dsn, environment: import.meta.env.MODE })
  sentryEnabled = true
}

export interface ReportTruncationParams {
  resource: string
  fetched: number | undefined
  total_count: number | undefined
  per_page: number | undefined
}

export const reportTruncation = ({ resource, fetched, total_count, per_page }: ReportTruncationParams): void => {
  // Guard #1: Sentry not initialised
  if (!sentryEnabled) return

  // Guard #2: any value is non-finite (NaN, Infinity, undefined, null) — must be before numeric comparisons
  if (
    !Number.isFinite(fetched) ||
    !Number.isFinite(total_count) ||
    !Number.isFinite(per_page)
  ) return

  // Guard #3: only track "full dropdown fetch" calls
  if (per_page !== DROPDOWN_PER_PAGE) return

  // Guard #4: fetched less than the cap — not a truncation signal
  if ((fetched as number) < DROPDOWN_PER_PAGE) return

  // Guard #5: no truncation — all records fit
  if ((total_count as number) <= (fetched as number)) return

  // Guard #6: already reported this resource in this session (dedup — must be last)
  if (reportedResources.has(resource)) return

  // All guards passed — report and mark as done
  Sentry.captureMessage('Admin dropdown data truncated', {
    level: 'warning',
    tags: { resource },
    contexts: { pagination: { fetched, total_count, per_page } },
    fingerprint: ['admin-pagination-truncated', resource],
  })
  reportedResources.add(resource)
}
