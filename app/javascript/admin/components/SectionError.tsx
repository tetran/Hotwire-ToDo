type SectionErrorProps = {
  title: string
  message?: string
  onRetry?: () => void
  layout?: 'inline' | 'stacked'
}

export function SectionError({
  title,
  message,
  onRetry,
  layout = 'inline',
}: SectionErrorProps) {
  const defaultMessage = `${title}を取得できませんでした。時間を置いて再度お試しください`
  const displayMessage = message ?? defaultMessage

  return (
    <div
      role="status"
      data-layout={layout}
      className="rounded-xl border border-rose-500/30 bg-rose-500/10 px-5 py-4"
    >
      <div
        className={
          layout === 'stacked'
            ? 'flex flex-col gap-2'
            : 'flex items-start gap-2'
        }
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          strokeWidth={1.5}
          stroke="currentColor"
          className="mt-0.5 h-4 w-4 shrink-0 text-rose-400"
          aria-hidden="true"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z"
          />
        </svg>
        <div className={layout === 'stacked' ? '' : 'flex-1'}>
          <p className="font-semibold text-rose-400">{title}</p>
          <p className="text-sm text-rose-400/80">{displayMessage}</p>
          {onRetry && (
            <button
              type="button"
              onClick={onRetry}
              className="mt-2 rounded-md border border-rose-400/30 px-3 py-1 text-xs font-medium text-rose-400 transition hover:bg-rose-500/10"
            >
              再試行
            </button>
          )}
        </div>
      </div>
    </div>
  )
}
