import { useEffect, useState } from 'react'
import { systemInfoApi, SystemInfoData } from '../lib/api'

export const SystemInfoPage = () => {
  const [data, setData] = useState<SystemInfoData | null>(null)
  const [error, setError] = useState('')

  useEffect(() => {
    systemInfoApi
      .get()
      .then((info) => setData(info))
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed to load system info'))
  }, [])

  if (error) return <p className="text-rose-500">{error}</p>
  if (!data) return <p className="text-slate-400">Loading...</p>

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div>
        <p className="text-[10px] font-semibold tracking-[0.2em] text-slate-400" style={{ fontFamily: 'DM Mono, monospace' }}>SYSTEM</p>
        <h1 className="text-2xl font-bold text-slate-800" style={{ fontFamily: 'Syne, sans-serif' }}>System Info</h1>
        <p className="mt-0.5 text-xs text-slate-400">Runtime environment details</p>
      </div>

      {/* Runtime */}
      <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
        <div className="border-b border-slate-100 px-5 py-4">
          <h2 className="text-sm font-semibold text-slate-700" style={{ fontFamily: 'Syne, sans-serif' }}>Runtime</h2>
        </div>
        <dl className="divide-y divide-slate-50">
          <div className="flex items-center justify-between px-5 py-3">
            <dt className="text-xs text-slate-500" style={{ fontFamily: 'DM Mono, monospace' }}>ruby_version</dt>
            <dd className="text-xs font-medium text-slate-800">{data.ruby_version}</dd>
          </div>
          <div className="flex items-center justify-between px-5 py-3">
            <dt className="text-xs text-slate-500" style={{ fontFamily: 'DM Mono, monospace' }}>rails_version</dt>
            <dd className="text-xs font-medium text-slate-800">{data.rails_version}</dd>
          </div>
          <div className="flex items-center justify-between px-5 py-3">
            <dt className="text-xs text-slate-500" style={{ fontFamily: 'DM Mono, monospace' }}>environment</dt>
            <dd className="text-xs font-medium text-slate-800">{data.environment}</dd>
          </div>
          <div className="flex items-center justify-between px-5 py-3">
            <dt className="text-xs text-slate-500" style={{ fontFamily: 'DM Mono, monospace' }}>memory_mb</dt>
            <dd className="text-xs font-medium text-slate-800">
              {data.runtime.memory_mb != null ? data.runtime.memory_mb.toFixed(1) : '—'}
            </dd>
          </div>
          <div className="flex items-center justify-between px-5 py-3">
            <dt className="text-xs text-slate-500" style={{ fontFamily: 'DM Mono, monospace' }}>uptime_seconds</dt>
            <dd className="text-xs font-medium text-slate-800">{data.runtime.uptime_seconds}</dd>
          </div>
        </dl>
      </div>

      {/* Database */}
      <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
        <div className="border-b border-slate-100 px-5 py-4">
          <h2 className="text-sm font-semibold text-slate-700" style={{ fontFamily: 'Syne, sans-serif' }}>Database</h2>
        </div>
        <dl className="divide-y divide-slate-50">
          <div className="flex items-center justify-between px-5 py-3">
            <dt className="text-xs text-slate-500" style={{ fontFamily: 'DM Mono, monospace' }}>adapter</dt>
            <dd className="text-xs font-medium text-slate-800">{data.database.adapter}</dd>
          </div>
          <div className="flex items-center justify-between px-5 py-3">
            <dt className="text-xs text-slate-500" style={{ fontFamily: 'DM Mono, monospace' }}>version</dt>
            <dd className="text-xs font-medium text-slate-800">{data.database.version ?? '—'}</dd>
          </div>
        </dl>
      </div>

      {/* Connection Pool */}
      <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
        <div className="border-b border-slate-100 px-5 py-4">
          <h2 className="text-sm font-semibold text-slate-700" style={{ fontFamily: 'Syne, sans-serif' }}>Connection Pool</h2>
        </div>
        <dl className="divide-y divide-slate-50">
          <div className="flex items-center justify-between px-5 py-3">
            <dt className="text-xs text-slate-500" style={{ fontFamily: 'DM Mono, monospace' }}>size</dt>
            <dd className="text-xs font-medium text-slate-800">{data.runtime.pool.size}</dd>
          </div>
          <div className="flex items-center justify-between px-5 py-3">
            <dt className="text-xs text-slate-500" style={{ fontFamily: 'DM Mono, monospace' }}>connections</dt>
            <dd className="text-xs font-medium text-slate-800">{data.runtime.pool.connections}</dd>
          </div>
          <div className="flex items-center justify-between px-5 py-3">
            <dt className="text-xs text-slate-500" style={{ fontFamily: 'DM Mono, monospace' }}>busy</dt>
            <dd className="text-xs font-medium text-slate-800">{data.runtime.pool.busy}</dd>
          </div>
          <div className="flex items-center justify-between px-5 py-3">
            <dt className="text-xs text-slate-500" style={{ fontFamily: 'DM Mono, monospace' }}>idle</dt>
            <dd className="text-xs font-medium text-slate-800">{data.runtime.pool.idle}</dd>
          </div>
          <div className="flex items-center justify-between px-5 py-3">
            <dt className="text-xs text-slate-500" style={{ fontFamily: 'DM Mono, monospace' }}>waiting</dt>
            <dd className="text-xs font-medium text-slate-800">{data.runtime.pool.waiting}</dd>
          </div>
        </dl>
      </div>
    </div>
  )
}
