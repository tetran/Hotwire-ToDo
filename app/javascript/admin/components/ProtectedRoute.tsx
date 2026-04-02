import { Navigate } from 'react-router-dom'
import { Action, ResourceType } from '../lib/api'
import { useAuth } from '../contexts/AuthContext'

interface ProtectedRouteProps {
  children: React.ReactNode
  requiredCapability?: { resource: ResourceType; action: Action }
  requireAdmin?: boolean
}

export const ProtectedRoute = ({ children, requiredCapability, requireAdmin }: ProtectedRouteProps) => {
  const { user, loading, refreshing, can, isAdmin } = useAuth()

  if (loading || refreshing) return <div>Loading...</div>
  if (!user) return <Navigate to="/admin/login" replace />

  if (requireAdmin && !isAdmin) return <Navigate to="/admin" replace />
  if (requiredCapability && !can(requiredCapability.resource, requiredCapability.action)) {
    return <Navigate to="/admin" replace />
  }

  return <>{children}</>
}
