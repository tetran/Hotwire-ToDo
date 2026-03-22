import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { llmProvidersApi, LlmProvider } from '../../lib/api'
import Badge from '../../components/Badge'

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
  const [error, setError] = useState('')

  useEffect(() => {
    llmProvidersApi.list()
      .then(setProviders)
      .catch(err => setError(err instanceof Error ? err.message : 'Failed to load providers'))
  }, [])

  if (error) return <p className="text-rose-500">{error}</p>

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div className="flex items-end justify-between">
        <div>
          <p className="text-[10px] font-semibold tracking-[0.2em] text-slate-400" style={{ fontFamily: 'DM Mono, monospace' }}>AI INFRASTRUCTURE</p>
          <h1 className="text-2xl font-bold text-slate-800" style={{ fontFamily: 'Syne, sans-serif' }}>LLM Providers</h1>
        </div>
        <button className="flex items-center gap-2 rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-600 shadow-sm transition hover:bg-slate-50">
          <svg className="h-4 w-4 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0l3.181 3.183a8.25 8.25 0 0013.803-3.7M4.031 9.865a8.25 8.25 0 0113.803-3.7l3.181 3.182m0-4.991v4.99" />
          </svg>
          Sync Available Models
        </button>
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

            {/* API info */}
            {provider.api_endpoint && (
              <p className="mt-3 truncate text-xs text-slate-400" style={{ fontFamily: 'DM Mono, monospace' }}>
                {provider.api_endpoint}
              </p>
            )}

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
    </div>
  )
}
