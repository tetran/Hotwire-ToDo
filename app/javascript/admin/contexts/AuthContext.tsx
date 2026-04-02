import { createContext, useCallback, useContext, useEffect, useState } from 'react'
import { Action, CAPABILITIES_STALE_EVENT, ResourceType, SessionUser, api } from '../lib/api'

interface AuthContextType {
  user: SessionUser | null
  loading: boolean
  refreshing: boolean
  login: (email: string, password: string, totpCode?: string) => Promise<{ totpRequired?: boolean }>
  logout: () => Promise<void>
  can: (resource: ResourceType, action: Action) => boolean
  isAdmin: boolean
}

const AuthContext = createContext<AuthContextType | null>(null)

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const [user, setUser] = useState<SessionUser | null>(null)
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)

  useEffect(() => {
    api.session.current()
      .then(({ user }) => setUser(user))
      .catch(() => setUser(null))
      .finally(() => setLoading(false))
  }, [])

  useEffect(() => {
    const handleCapabilitiesStale = () => {
      setRefreshing(true)
      api.session.current()
        .then(({ user }) => setUser(user))
        .catch(() => {})
        .finally(() => setRefreshing(false))
    }
    window.addEventListener(CAPABILITIES_STALE_EVENT, handleCapabilitiesStale)
    return () => window.removeEventListener(CAPABILITIES_STALE_EVENT, handleCapabilitiesStale)
  }, [])

  const login = async (email: string, password: string, totpCode?: string) => {
    const result = await api.session.create({ email, password, totp_code: totpCode })
    if (!result.totp_required) {
      setUser(result.user)
      if (result.csrf_token) {
        const meta = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')
        if (meta) meta.content = result.csrf_token
      }
    }
    return { totpRequired: result.totp_required }
  }

  const logout = async () => {
    await api.session.destroy()
    setUser(null)
  }

  const can = useCallback(
    (resource: ResourceType, action: Action): boolean =>
      user?.capabilities?.[resource]?.[action] ?? false,
    [user]
  )

  const isAdmin = user?.is_admin ?? false

  return (
    <AuthContext.Provider value={{ user, loading, refreshing, login, logout, can, isAdmin }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
