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
  const header = (
    <>
      <div className="flex items-center justify-between">
        <p className="text-xs font-medium uppercase tracking-widest text-slate-400">{label}</p>
        <span className={`text-lg ${accent}`}>{icon}</span>
      </div>
      <p className="mt-3 text-3xl font-bold text-slate-800" style={{ fontFamily: 'Syne, sans-serif' }}>
        {value}
      </p>
    </>
  )

  if (to) {
    // hover:border-indigo-300 は ADMIN_UI §2 のトークン優先ルールに反する palette literal だが意図的に許容:
    // --color-accent (= #6366f1, ≒ indigo-500) は border として濃く selected 状態と誤認しやすく、
    // light shade トークン (--color-accent-soft 等) は admin で未定義のため。
    // 将来 light shade トークンが定義された時点で置き換える。
    return (
      <Link
        to={to}
        className="group block rounded-xl border border-slate-200 bg-white p-5 shadow-sm transition-colors hover:border-indigo-300 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent"
      >
        {header}
        {subtitle && (
          <p className="mt-1.5 text-xs text-slate-400">
            <span className="inline-block transition-transform group-hover:translate-x-0.5">{subtitle}</span>
          </p>
        )}
      </Link>
    )
  }

  return (
    <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
      {header}
      {subtitle && <p className="mt-1.5 text-xs text-slate-400">{subtitle}</p>}
    </div>
  )
}
