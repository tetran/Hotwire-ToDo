import { useCallback, useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { llmModelsApi, LlmModel, type PaginationMeta } from '../../lib/api'
import Badge from '../../components/Badge'
import Pagination from '../../components/Pagination'
import { usePagination, useClampPage } from '../../hooks/usePagination'

export const LlmModelsIndexPage = () => {
  const { id } = useParams<{ id: string }>()
  const providerId = Number(id)

  const [models, setModels] = useState<LlmModel[]>([])
  const [meta, setMeta] = useState<PaginationMeta | null>(null)
  const [error, setError] = useState('')

  const { page, perPage, setPage, setPerPage, clampPage } = usePagination()
  useClampPage(meta, clampPage)

  const loadModels = useCallback(() => {
    llmModelsApi.list(providerId, { page, per_page: perPage })
      .then(response => {
        setModels(response.llm_models)
        setMeta(response.meta)
      })
      .catch(err => setError(err instanceof Error ? err.message : 'Failed to load models'))
  }, [providerId, page, perPage])

  useEffect(() => {
    loadModels()
  }, [loadModels])

  const handleDelete = async (modelId: number) => {
    if (!window.confirm('Are you sure you want to delete this model?')) return
    try {
      await llmModelsApi.delete(providerId, modelId)
      loadModels()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete model')
    }
  }

  if (error) {
    return (
    <div className="rounded-lg border border-rose-500/30 bg-rose-500/10 px-4 py-3 text-sm text-rose-400">
      {error}
    </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div className="flex items-end justify-between">
        <div>
          <p className="text-[10px] font-semibold tracking-[0.2em] text-slate-400" style={{ fontFamily: 'DM Mono, monospace' }}>AI INFRASTRUCTURE</p>
          <h1 className="text-2xl font-bold text-slate-800" style={{ fontFamily: 'Syne, sans-serif' }}>LLM Models</h1>
        </div>
        <div className="flex items-center gap-2">
          <Link
            to={`/admin/llm-providers/${providerId}/models/new`}
            className="rounded-lg bg-[#6366f1] px-4 py-2 text-sm font-medium text-white shadow-md shadow-indigo-500/20 transition hover:bg-[#5558e8]"
          >
            New Model
          </Link>
          <Link
            to={`/admin/llm-providers/${providerId}`}
            className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:bg-slate-50"
          >
            Back
          </Link>
        </div>
      </div>

      {/* Table */}
      <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr className="border-b border-slate-100">
              <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">ID</th>
              <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Name</th>
              <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Display Name</th>
              <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Active</th>
              <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Default</th>
              <th scope="col" className="px-5 py-3.5 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-50">
            {models.map(model => (
              <tr key={model.id} className="transition-colors hover:bg-slate-50/50">
                <td className="px-5 py-3.5 text-sm text-slate-700" style={{ fontFamily: 'DM Mono, monospace' }}>{model.id}</td>
                <td className="px-5 py-3.5 text-sm text-slate-700">{model.name}</td>
                <td className="px-5 py-3.5 text-sm text-slate-700">{model.display_name}</td>
                <td className="px-5 py-3.5 text-sm text-slate-700">
                  {model.active
                    ? <Badge variant="success">Active</Badge>
                    : <Badge variant="neutral">Inactive</Badge>
                  }
                </td>
                <td className="px-5 py-3.5 text-sm text-slate-700">
                  {model.default_model
                    ? <Badge variant="info">Default</Badge>
                    : <Badge variant="neutral">-</Badge>
                  }
                </td>
                <td className="px-5 py-3.5 text-sm text-slate-700">
                  <div className="flex items-center gap-2">
                    <Link
                      to={`/admin/llm-providers/${providerId}/models/${model.id}/edit`}
                      className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:bg-slate-50"
                    >
                      Edit
                    </Link>
                    <button
                      onClick={() => handleDelete(model.id)}
                      className="rounded-md border border-rose-200 px-2.5 py-1 text-xs font-medium text-rose-500 transition hover:bg-rose-50"
                    >
                      Delete
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
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
