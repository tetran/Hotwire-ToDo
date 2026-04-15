import type { ReactNode } from 'react'

interface AdminPageHeaderProps {
  eyebrow: string
  title: string
  action?: ReactNode
}

export const AdminPageHeader = ({ eyebrow, title, action }: AdminPageHeaderProps) => (
  <div className="flex items-end justify-between">
    <div>
      <p
        className="text-[10px] font-semibold tracking-[0.2em] text-slate-400"
        style={{ fontFamily: 'DM Mono, monospace' }}
      >
        {eyebrow}
      </p>
      <h1
        className="text-2xl font-bold text-slate-800"
        style={{ fontFamily: 'Syne, sans-serif' }}
      >
        {title}
      </h1>
    </div>
    {action}
  </div>
)
