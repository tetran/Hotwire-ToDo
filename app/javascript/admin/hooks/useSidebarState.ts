import { useCallback, useEffect, useState } from 'react'

function detectIsDesktop(): boolean {
  return typeof window !== 'undefined'
    ? window.matchMedia('(min-width: 768px)').matches
    : false
}

const KEY_DESKTOP = 'admin.sidebar.desktop' // 'expanded' | 'collapsed'
const KEY_MOBILE = 'admin.sidebar.mobile' // 'open' | 'closed'

function readStorage(key: string, defaultValue: boolean): boolean {
  if (typeof window === 'undefined') return defaultValue
  try {
    const raw = localStorage.getItem(key)
    if (raw === null) return defaultValue
    if (key === KEY_DESKTOP) return raw === 'expanded'
    return raw === 'open'
  } catch {
    return defaultValue
  }
}

function writeStorage(key: string, value: boolean): void {
  if (typeof window === 'undefined') return
  try {
    if (key === KEY_DESKTOP) {
      localStorage.setItem(key, value ? 'expanded' : 'collapsed')
    } else {
      localStorage.setItem(key, value ? 'open' : 'closed')
    }
  } catch {
    // Safari Private Mode or storage quota: degrade silently
  }
}

export interface UseSidebarStateResult {
  isDesktop: boolean
  isDesktopExpanded: boolean
  isMobileOpen: boolean
  toggleDesktop: () => void
  toggleMobile: () => void
  closeMobile: () => void
}

export function useSidebarState(): UseSidebarStateResult {
  const [isDesktop, setIsDesktop] = useState<boolean>(detectIsDesktop)
  const [isDesktopExpanded, setIsDesktopExpanded] = useState<boolean>(() =>
    readStorage(KEY_DESKTOP, true)
  )
  // Mobile defaults to closed: the drawer is off-canvas and would obscure content if open by default.
  const [isMobileOpen, setIsMobileOpen] = useState<boolean>(() =>
    readStorage(KEY_MOBILE, false)
  )

  // Subscribe to viewport changes
  useEffect(() => {
    if (typeof window === 'undefined') return

    const mql = window.matchMedia('(min-width: 768px)')

    const handleChange = (e: MediaQueryListEvent) => {
      const nowDesktop = e.matches
      setIsDesktop(nowDesktop)
      if (nowDesktop) {
        // Mobile→desktop: force-close mobile drawer in memory only.
        // Do NOT write to localStorage — preserves the user's last explicit mobile choice.
        setIsMobileOpen(false)
      } else {
        // Desktop→mobile: rehydrate mobile state from localStorage so a live resize
        // restores the user's previously chosen state instead of always landing closed.
        setIsMobileOpen(readStorage(KEY_MOBILE, false))
      }
    }

    mql.addEventListener('change', handleChange)
    return () => {
      mql.removeEventListener('change', handleChange)
    }
  }, [])

  const toggleDesktop = useCallback(() => {
    setIsDesktopExpanded((prev) => {
      const next = !prev
      writeStorage(KEY_DESKTOP, next)
      return next
    })
  }, [])

  const toggleMobile = useCallback(() => {
    setIsMobileOpen((prev) => {
      const next = !prev
      writeStorage(KEY_MOBILE, next)
      return next
    })
  }, [])

  const closeMobile = useCallback(() => {
    setIsMobileOpen(false)
    writeStorage(KEY_MOBILE, false)
  }, [])

  // Esc key closes mobile drawer (no-op on desktop)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isMobileOpen && !isDesktop) {
        closeMobile()
      }
    }

    document.addEventListener('keydown', handleKeyDown)
    return () => {
      document.removeEventListener('keydown', handleKeyDown)
    }
  }, [isMobileOpen, isDesktop, closeMobile])

  return { isDesktop, isDesktopExpanded, isMobileOpen, toggleDesktop, toggleMobile, closeMobile }
}
