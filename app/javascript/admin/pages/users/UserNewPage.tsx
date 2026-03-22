import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { usersApi } from '../../lib/api'

export const UserNewPage = () => {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [name, setName] = useState('')
  const [password, setPassword] = useState('')
  const [passwordConfirmation, setPasswordConfirmation] = useState('')
  const [error, setError] = useState('')

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    if (password !== passwordConfirmation) {
      setError('Password confirmation does not match')
      return
    }
    try {
      await usersApi.create({ email, name, password })
      navigate('/admin/users')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create user')
    }
  }

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div className="flex items-end justify-between">
        <div>
          <p className="text-[10px] font-semibold tracking-[0.2em] text-slate-400"
             style={{ fontFamily: 'DM Mono, monospace' }}>MANAGEMENT</p>
          <h1 className="text-2xl font-bold text-slate-800"
              style={{ fontFamily: 'Syne, sans-serif' }}>New User</h1>
        </div>
      </div>

      {error && (
        <div className="rounded-lg border border-rose-500/30 bg-rose-500/10 px-4 py-3 text-sm text-rose-400">
          {error}
        </div>
      )}

      <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <form onSubmit={handleSubmit}>
          <div className="space-y-4">
            <div className="space-y-1">
              <label className="text-xs font-medium text-slate-600">Email</label>
              <input type="email" value={email} onChange={e => setEmail(e.target.value)} required
                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none transition focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/30" />
            </div>
            <div className="space-y-1">
              <label className="text-xs font-medium text-slate-600">Name</label>
              <input type="text" value={name} onChange={e => setName(e.target.value)} required
                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none transition focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/30" />
            </div>
            <div className="space-y-1">
              <label className="text-xs font-medium text-slate-600">Password</label>
              <input type="password" value={password} onChange={e => setPassword(e.target.value)} required
                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none transition focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/30" />
            </div>
            <div className="space-y-1">
              <label className="text-xs font-medium text-slate-600">Confirm Password</label>
              <input type="password" value={passwordConfirmation} onChange={e => setPasswordConfirmation(e.target.value)} required
                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none transition focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/30" />
            </div>
          </div>
          <div className="mt-6 flex items-center justify-end gap-2">
            <Link to="/admin/users"
              className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:bg-slate-50">
              Cancel
            </Link>
            <button type="submit"
              className="rounded-lg bg-[#6366f1] px-4 py-2 text-sm font-medium text-white shadow-md shadow-indigo-500/20 transition hover:bg-[#5558e8]">
              Create
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
