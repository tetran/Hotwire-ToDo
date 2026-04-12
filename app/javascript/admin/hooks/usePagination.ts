import { useCallback, useEffect } from 'react'
import { useSearchParams } from 'react-router-dom'
import type { PaginationMeta } from '../lib/api'

export const PER_PAGE_OPTIONS = [25, 50, 100] as const
export type PerPageOption = typeof PER_PAGE_OPTIONS[number]

const DEFAULT_PER_PAGE: PerPageOption = 25

function isValidPerPage(n: number): n is PerPageOption {
  return (PER_PAGE_OPTIONS as readonly number[]).includes(n)
}

export interface UsePaginationResult {
  page: number
  perPage: PerPageOption
  setPage: (n: number) => void
  setPerPage: (n: number) => void
  resetPage: () => void
  clampPage: (meta: PaginationMeta) => void
}

export function usePagination(): UsePaginationResult {
  const [searchParams, setSearchParams] = useSearchParams()

  const page = Math.max(1, Number(searchParams.get('page')) || 1)
  const rawPerPage = Number(searchParams.get('per_page')) || DEFAULT_PER_PAGE
  const perPage: PerPageOption = isValidPerPage(rawPerPage) ? rawPerPage : DEFAULT_PER_PAGE

  const setPage = useCallback(
    (n: number) => {
      setSearchParams(
        prev => {
          const next = new URLSearchParams(prev)
          if (n <= 1) next.delete('page')
          else next.set('page', String(n))
          return next
        },
        { replace: true }
      )
    },
    [setSearchParams]
  )

  const setPerPage = useCallback(
    (n: number) => {
      const valid: PerPageOption = isValidPerPage(n) ? n : DEFAULT_PER_PAGE
      setSearchParams(
        prev => {
          const next = new URLSearchParams(prev)
          next.delete('page')
          if (valid === DEFAULT_PER_PAGE) next.delete('per_page')
          else next.set('per_page', String(valid))
          return next
        },
        { replace: true }
      )
    },
    [setSearchParams]
  )

  const resetPage = useCallback(() => {
    setSearchParams(
      prev => {
        const next = new URLSearchParams(prev)
        next.delete('page')
        return next
      },
      { replace: false }
    )
  }, [setSearchParams])

  const clampPage = useCallback(
    (meta: PaginationMeta) => {
      if (meta.total_pages > 0 && page > meta.total_pages) {
        setSearchParams(
          prev => {
            const next = new URLSearchParams(prev)
            if (meta.total_pages <= 1) next.delete('page')
            else next.set('page', String(meta.total_pages))
            return next
          },
          { replace: true }
        )
      }
    },
    [page, setSearchParams]
  )

  return { page, perPage, setPage, setPerPage, resetPage, clampPage }
}

export function useClampPage(meta: PaginationMeta | null, clampPage: (m: PaginationMeta) => void): void {
  useEffect(() => {
    if (meta) clampPage(meta)
  }, [meta, clampPage])
}
