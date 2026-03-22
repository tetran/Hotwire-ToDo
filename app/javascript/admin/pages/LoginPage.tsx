import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'

export const LoginPage = () => {
  const { login } = useAuth()
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [totpCode, setTotpCode] = useState('')
  const [totpRequired, setTotpRequired] = useState(false)
  const [error, setError] = useState('')

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    try {
      const result = await login(email, password, totpRequired ? totpCode : undefined)
      if (result.totpRequired) {
        setTotpRequired(true)
      } else {
        navigate('/admin')
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Login failed')
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-[#0f1117]">
      <div className="w-full max-w-sm px-4">
        {/* Logo */}
        <div className="mb-8 flex flex-col items-center gap-3">
          <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-[#6366f1] shadow-lg shadow-indigo-500/30">
            <svg className="h-6 w-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M9 3H5a2 2 0 00-2 2v4m6-6h10a2 2 0 012 2v4M9 3v18m0 0h10a2 2 0 002-2v-4M9 21H5a2 2 0 01-2-2v-4m0 0h18" />
            </svg>
          </div>
          <div className="text-center">
            <p className="font-bold text-white text-xl" style={{ fontFamily: 'Syne, sans-serif' }}>Hobo Admin</p>
            <p className="text-[10px] tracking-[0.2em] text-slate-500" style={{ fontFamily: 'DM Mono, monospace' }}>CONTROL PANEL</p>
          </div>
        </div>

        {/* Card */}
        <div className="rounded-2xl border border-[#1e2130] bg-[#161b27] p-8 shadow-2xl">
          <h1 className="mb-6 text-lg font-semibold text-white" style={{ fontFamily: 'Syne, sans-serif' }}>
            {totpRequired ? 'Two-Factor Auth' : 'Admin Login'}
          </h1>

          {error && (
            <div
              role="alert"
              data-testid="error-message"
              className="mb-4 rounded-lg border border-rose-500/30 bg-rose-500/10 px-4 py-3 text-sm text-rose-400"
            >
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            {!totpRequired ? (
              <>
                <div className="space-y-1.5">
                  <label className="text-xs font-medium text-slate-400">Email</label>
                  <input
                    type="email"
                    value={email}
                    onChange={e => setEmail(e.target.value)}
                    required
                    className="w-full rounded-lg border border-[#1e2130] bg-[#0f1117] px-3 py-2.5 text-sm text-white placeholder-slate-600 outline-none ring-0 transition focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/50"
                    placeholder="admin@example.com"
                  />
                </div>
                <div className="space-y-1.5">
                  <label className="text-xs font-medium text-slate-400">Password</label>
                  <input
                    type="password"
                    value={password}
                    onChange={e => setPassword(e.target.value)}
                    required
                    className="w-full rounded-lg border border-[#1e2130] bg-[#0f1117] px-3 py-2.5 text-sm text-white placeholder-slate-600 outline-none ring-0 transition focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/50"
                    placeholder="••••••••"
                  />
                </div>
              </>
            ) : (
              <div className="space-y-1.5">
                <label className="text-xs font-medium text-slate-400">TOTP Code</label>
                <input
                  type="text"
                  value={totpCode}
                  onChange={e => setTotpCode(e.target.value)}
                  required
                  className="w-full rounded-lg border border-[#1e2130] bg-[#0f1117] px-3 py-2.5 text-center text-sm tracking-[0.3em] text-white placeholder-slate-600 outline-none focus:border-[#6366f1] focus:ring-1 focus:ring-[#6366f1]/50"
                  placeholder="000000"
                  maxLength={6}
                />
              </div>
            )}
            <button
              type="submit"
              className="mt-2 w-full rounded-lg bg-[#6366f1] px-4 py-2.5 text-sm font-semibold text-white shadow-lg shadow-indigo-500/20 transition hover:bg-[#5558e8] active:scale-[0.98]"
            >
              {totpRequired ? 'Verify' : 'Login'}
            </button>
          </form>
        </div>
      </div>
    </div>
  )
}
