type Status = 'active' | 'deactivated' | 'all'

interface Props {
  value: Status
  onChange: (value: Status) => void
}

const OPTIONS: { label: string; value: Status }[] = [
  { label: 'Active', value: 'active' },
  { label: 'Deactivated', value: 'deactivated' },
  { label: 'All', value: 'all' },
]

export const UserStatusFilter = ({ value, onChange }: Props) => (
  <div className="inline-flex items-center rounded-lg border border-slate-200 bg-white p-0.5">
    {OPTIONS.map(option => (
      <button
        key={option.value}
        type="button"
        onClick={() => onChange(option.value)}
        className={`rounded-md px-3 py-1.5 text-xs font-medium transition-colors ${
          value === option.value
            ? 'bg-[#6366f1] text-white shadow-sm'
            : 'text-slate-600 hover:bg-slate-50'
        }`}
        aria-pressed={value === option.value}
      >
        {option.label}
      </button>
    ))}
  </div>
)
