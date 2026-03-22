type AvatarProps = {
  name: string
  size?: 'sm' | 'md' | 'lg'
}

const gradients = [
  'from-indigo-500 to-purple-600',
  'from-cyan-500 to-blue-600',
  'from-emerald-500 to-teal-600',
  'from-orange-500 to-rose-600',
  'from-pink-500 to-fuchsia-600',
]

function gradientFor(name: string): string {
  const index = name.charCodeAt(0) % gradients.length
  return gradients[index]
}

const sizeClasses = {
  sm: 'w-7 h-7 text-xs',
  md: 'w-9 h-9 text-sm',
  lg: 'w-11 h-11 text-base',
}

export default function Avatar({ name, size = 'md' }: AvatarProps) {
  const initials = name
    .split(' ')
    .map((part) => part[0])
    .join('')
    .slice(0, 2)
    .toUpperCase()

  return (
    <div
      className={`flex items-center justify-center rounded-full bg-gradient-to-br ${gradientFor(name)} ${sizeClasses[size]} font-semibold text-white shrink-0`}
    >
      {initials}
    </div>
  )
}
