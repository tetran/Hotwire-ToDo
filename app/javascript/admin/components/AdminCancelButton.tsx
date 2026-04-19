import { useNavigate } from 'react-router-dom'

interface AdminCancelButtonProps {
  to: string
}

export const AdminCancelButton = ({ to }: AdminCancelButtonProps) => {
  const navigate = useNavigate()
  return (
    <button
      type="button"
      onClick={() => navigate(to)}
      className="rounded-md border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:bg-slate-50"
    >
      Cancel
    </button>
  )
}
