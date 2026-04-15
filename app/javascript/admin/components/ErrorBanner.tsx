interface ErrorBannerProps {
  message: string | null
}

export const ErrorBanner = ({ message }: ErrorBannerProps) => {
  if (!message) return null
  return (
    <div className="rounded-lg border border-rose-500/30 bg-rose-500/10 px-4 py-3 text-sm text-rose-400">
      {message}
    </div>
  )
}
