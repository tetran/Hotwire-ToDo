type BadgeVariant = 'success' | 'danger' | 'info' | 'neutral' | 'warning'

type BadgeProps = {
  variant?: BadgeVariant
  children: React.ReactNode
}

const variantClasses: Record<BadgeVariant, string> = {
  success: 'bg-emerald-500/15 text-emerald-400 ring-1 ring-emerald-500/30',
  danger: 'bg-rose-500/15 text-rose-400 ring-1 ring-rose-500/30',
  info: 'bg-indigo-500/15 text-indigo-400 ring-1 ring-indigo-500/30',
  neutral: 'bg-slate-500/15 text-slate-400 ring-1 ring-slate-500/30',
  warning: 'bg-amber-500/15 text-amber-400 ring-1 ring-amber-500/30',
}

export default function Badge({ variant = 'neutral', children }: BadgeProps) {
  return (
    <span
      className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${variantClasses[variant]}`}
    >
      {children}
    </span>
  )
}
