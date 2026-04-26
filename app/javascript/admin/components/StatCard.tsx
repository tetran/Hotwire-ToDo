import { Link } from 'react-router-dom'

type StatCardProps = {
  label: string
  value: number | string
  icon: React.ReactNode
  accent?: string
  subtitle?: string
  to?: string
}

export default function StatCard({ label, value, icon, accent = 'text-indigo-400', subtitle, to }: StatCardProps) {
  const inner = (
    <>
      <div className="flex items-center justify-between">
        <p className="text-xs font-medium uppercase tracking-widest text-slate-400">{label}</p>
        <span className={`text-lg ${accent}`}>{icon}</span>
      </div>
      <p className="mt-3 text-3xl font-bold text-slate-800" style={{ fontFamily: 'Syne, sans-serif' }}>
        {value}
      </p>
      {subtitle && (
        <p className="mt-1.5 text-xs text-slate-400">
          <span className="inline-block transition-transform group-hover:translate-x-0.5">{subtitle}</span>
        </p>
      )}
    </>
  )

  if (to) {
    return (
      <Link
        to={to}
        className="group block rounded-xl border border-slate-200 bg-white p-5 shadow-sm transition-colors hover:border-indigo-300 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent"
      >
        {inner}
      </Link>
    )
  }

  return (
    <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
      {inner}
    </div>
  )
}
