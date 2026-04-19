import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { llmProvidersApi, LlmProvider, DROPDOWN_PER_PAGE } from '../../lib/api'
import { reportTruncation } from '../../lib/sentry'
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
    const controller = new AbortController()
    llmProvidersApi.list({ per_page: DROPDOWN_PER_PAGE }, { signal: controller.signal })
      .then(response => {
        if (!controller.signal.aborted) {
          setProviders(response.llm_providers)
          reportTruncation({
            resource: 'llm_providers',
            fetched: response.llm_providers.length,
            total_count: response.meta.total_count,
            per_page: response.meta.per_page,
          })
        }
      })
      .catch(err => {
        if (!controller.signal.aborted) {
          setError(err instanceof Error ? err.message : 'Failed to load providers')
        }
      })
    return () => controller.abort()
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
      </div>

      {/* Provider cards */}
      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
        {providers.map(provider => (
          <Link
            key={provider.id}
            to={`/admin/llm-providers/${provider.id}`}
            data-testid="provider-card"
            className="block rounded-xl border border-slate-200 bg-white p-5 shadow-sm transition hover:shadow-md"
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

            {/* Model count */}
            <div className="mt-3 text-xs text-slate-400">
              {provider.llm_models_count} model(s)
            </div>
          </Link>
        ))}
      </div>
    </div>
  )
}
