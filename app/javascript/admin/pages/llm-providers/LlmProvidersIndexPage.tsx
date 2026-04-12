import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { llmProvidersApi, LlmProvider, type PaginationMeta } from '../../lib/api'
import Badge from '../../components/Badge'
import Pagination from '../../components/Pagination'
import { usePagination, useClampPage } from '../../hooks/usePagination'

const providerColors: Record<string, string> = {
  OpenAI: 'from-emerald-400 to-teal-500',
  Anthropic: 'from-orange-400 to-rose-500',
  Gemini: 'from-blue-400 to-indigo-500',
  'Google Gemini': 'from-blue-400 to-indigo-500',
}

function providerGradient(name: string): string {
  return providerColors[name] ?? 'from-indigo-400 to-purple-500'
}

export const LlmProvidersIndexPage = () => {
  const [providers, setProviders] = useState<LlmProvider[]>([])
  const [meta, setMeta] = useState<PaginationMeta | null>(null)
  const [error, setError] = useState('')

  const { page, perPage, setPage, setPerPage, clampPage } = usePagination()
  useClampPage(meta, clampPage)

  useEffect(() => {
    const controller = new AbortController()
    llmProvidersApi.list({ page, per_page: perPage }, { signal: controller.signal })
      .then(response => {
        if (!controller.signal.aborted) {
          setProviders(response.llm_providers)
          setMeta(response.meta)
        }
      })
      .catch(err => {
        if (!controller.signal.aborted) {
          setError(err instanceof Error ? err.message : 'Failed to load providers')
        }
      })
    return () => controller.abort()
  }, [page, perPage])

  if (error) return <p className="text-rose-500">{error}</p>

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div className="flex items-end justify-between">
        <div>
          <p className="text-[10px] font-semibold tracking-[0.2em] text-slate-400" style={{ fontFamily: 'DM Mono, monospace' }}>AI INFRASTRUCTURE</p>
          <h1 className="text-2xl font-bold text-slate-800" style={{ fontFamily: 'Syne, sans-serif' }}>LLM Providers</h1>
        </div>
      </div>

      {/* Provider cards */}
      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
        {providers.map(provider => (
          <div
            key={provider.id}
            data-testid="provider-card"
            className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm transition hover:shadow-md"
          >
            {/* Card header */}
            <div className="flex items-start justify-between">
              <div className="flex items-center gap-3">
                <div className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br ${providerGradient(provider.name)} text-lg font-bold text-white shadow-sm`}>
                  {provider.name[0]}
                </div>
                <div>
                  <p className="font-semibold text-slate-800" style={{ fontFamily: 'Syne, sans-serif' }}>{provider.name}</p>
                  <Badge variant={provider.active ? 'success' : 'neutral'}>
                    {provider.active ? 'Active' : 'Inactive'}
                  </Badge>
                </div>
              </div>
            </div>

            {/* Actions */}
            <div className="mt-4 flex items-center gap-2">
              <Link
                to={`/admin/llm-providers/${provider.id}/edit`}
                className="flex flex-1 items-center justify-center gap-1.5 rounded-lg bg-[#6366f1] px-3 py-2 text-xs font-medium text-white transition hover:bg-[#5558e8]"
              >
                <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M10.5 6h9.75M10.5 6a1.5 1.5 0 11-3 0m3 0a1.5 1.5 0 10-3 0M3.75 6H7.5m3 12h9.75m-9.75 0a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m-3.75 0H7.5m9-6h3.75m-3.75 0a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m-9.75 0h9.75" />
                </svg>
                Configure
              </Link>
              <Link
                to={`/admin/llm-providers/${provider.id}`}
                className="flex items-center justify-center gap-1.5 rounded-lg border border-slate-200 px-3 py-2 text-xs font-medium text-slate-600 transition hover:bg-slate-50"
              >
                Detail
              </Link>
              <Link
                to={`/admin/llm-providers/${provider.id}/models`}
                className="flex items-center justify-center gap-1.5 rounded-lg border border-slate-200 px-3 py-2 text-xs font-medium text-slate-600 transition hover:bg-slate-50"
              >
                Models
              </Link>
            </div>
          </div>
        ))}
      </div>

      {meta && (
        <Pagination
          meta={meta}
          page={page}
          perPage={perPage}
          onPageChange={setPage}
          onPerPageChange={setPerPage}
        />
      )}
    </div>
  )
}
