import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { rolesApi } from '../../lib/api'
import { AdminPageHeader } from '../../components/AdminPageHeader'
import { ErrorBanner } from '../../components/ErrorBanner'
import { AdminCancelButton } from '../../components/AdminCancelButton'

export const RoleNewPage = () => {
  const navigate = useNavigate()
  const [name, setName] = useState('')
  const [description, setDescription] = useState('')
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setSubmitting(true)
    try {
      await rolesApi.create({ name, description: description || undefined })
      navigate('/admin/roles')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create role')
      setSubmitting(false)
    }
  }

  return (
    <div className="space-y-6">
      {/* Page header */}
      <AdminPageHeader eyebrow="MANAGEMENT" title="New Role" />

      <ErrorBanner message={error || null} />

      {/* Form card */}
      <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <form onSubmit={handleSubmit}>
          <div className="space-y-4">
            <div className="space-y-1">
              <label className="text-xs font-medium text-slate-600">Name</label>
              <input
                type="text"
                value={name}
                onChange={e => setName(e.target.value)}
                required
                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none transition focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/30"
              />
            </div>
            <div className="space-y-1">
              <label className="text-xs font-medium text-slate-600">Description</label>
              <textarea
                value={description}
                onChange={e => setDescription(e.target.value)}
                rows={3}
                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none transition focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/30"
              />
            </div>
          </div>
          <div className="mt-6 flex items-center justify-end gap-3">
            <AdminCancelButton to="/admin/roles" />
            <button
              type="submit"
              disabled={submitting}
              className="rounded-lg bg-[#6366f1] px-4 py-2 text-sm font-medium text-white shadow-md shadow-indigo-500/20 transition hover:bg-[#5558e8]"
            >
              {submitting ? 'Creating...' : 'Create Role'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
