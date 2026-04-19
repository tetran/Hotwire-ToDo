import { Link } from 'react-router-dom'

interface AdminBackLinkProps {
  to: string
  label: string
}

export const AdminBackLink = ({ to, label }: AdminBackLinkProps) => (
  <Link
    to={to}
    aria-label={`Back to ${label}`}
    className="group inline-flex items-center gap-1 text-xs font-medium text-slate-500 transition-colors hover:text-[#6366f1]"
  >
    <span className="inline-block transition-transform group-hover:-translate-x-0.5" aria-hidden="true">←</span>
    {label}
  </Link>
)
