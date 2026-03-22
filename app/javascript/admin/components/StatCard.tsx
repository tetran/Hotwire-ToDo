type StatCardProps = {
  label: string
  value: number | string
  icon: React.ReactNode
  accent?: string
  subtitle?: string
}

export default function StatCard({ label, value, icon, accent = 'text-indigo-400', subtitle }: StatCardProps) {
  return (
    <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="flex items-center justify-between">
        <p className="text-xs font-medium uppercase tracking-widest text-slate-400">{label}</p>
        <span className={`text-lg ${accent}`}>{icon}</span>
      </div>
      <p className="mt-3 text-3xl font-bold text-slate-800" style={{ fontFamily: 'Syne, sans-serif' }}>
        {value}
      </p>
      {subtitle && (
        <p className="mt-1.5 text-xs text-slate-400">{subtitle}</p>
      )}
    </div>
  )
}
