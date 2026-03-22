export type ResourceType = 'User' | 'Project' | 'Task' | 'Comment' | 'Admin' | 'LlmProvider'
export type Action = 'read' | 'write' | 'delete' | 'manage'
export type Capabilities = Record<ResourceType, Record<Action, boolean>>

export interface SessionUser {
  id: number
  email: string
  name: string
  is_admin: boolean
  capabilities: Capabilities
}

export interface User {
  id: number
  email: string
  name: string
  created_at: string
  updated_at: string
  roles?: { id: number; name: string }[]
}

export interface Permission {
  id: number
  resource_type: string
  action: string
  description: string | null
  roles?: { id: number; name: string; description: string | null; system_role: boolean }[]
}

export interface Role {
  id: number
  name: string
  description: string | null
  system_role: boolean
  created_at: string
  updated_at: string
  permissions?: Permission[]
}

export interface CreateRoleInput {
  name: string
  description?: string
}

export interface UpdateRoleInput {
  name?: string
  description?: string
}

export interface DashboardStats {
  users_count: number
  roles_count: number
  llm_providers_count: number
  llm_models_count: number
}

export interface DashboardUser {
  id: number
  name: string
  email: string
  created_at: string
}

export interface DashboardData {
  status: string
  stats: DashboardStats
  recent_users: DashboardUser[]
}

export interface CreateUserInput {
  email: string
  name: string
  password: string
}

export interface UpdateUserInput {
  email: string
  name: string
}

const getCsrfToken = (): string => {
  const meta = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')
  return meta?.content ?? ''
}

const apiRequest = async <T>(
  path: string,
  options: RequestInit = {}
): Promise<T> => {
  const response = await fetch(`/api/v1/admin${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': getCsrfToken(),
      ...options.headers,
    },
  })

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: 'Unknown error' }))
    throw new Error(error.error ?? `HTTP ${response.status}`)
  }

  if (response.status === 204) return undefined as T

  return response.json() as Promise<T>
}

export const api = {
  get: <T>(path: string) => apiRequest<T>(path),
  post: <T>(path: string, body: unknown) =>
    apiRequest<T>(path, { method: 'POST', body: JSON.stringify(body) }),
  patch: <T>(path: string, body: unknown) =>
    apiRequest<T>(path, { method: 'PATCH', body: JSON.stringify(body) }),
  delete: <T>(path: string) => apiRequest<T>(path, { method: 'DELETE' }),

  session: {
    current: () => api.get<{ user: SessionUser }>('/session'),
    create: (credentials: { email: string; password: string; totp_code?: string }) =>
      api.post<{ user: SessionUser; totp_required?: boolean; csrf_token?: string }>('/session', credentials),
    destroy: () => api.delete<void>('/session'),
  },
}

export const usersApi = {
  list: () => api.get<User[]>('/users'),
  get: (id: number) => api.get<User>(`/users/${id}`),
  create: (data: CreateUserInput) => api.post<User>('/users', { user: data }),
  update: (id: number, data: UpdateUserInput) => api.patch<User>(`/users/${id}`, data),
  delete: (id: number) => api.delete<void>(`/users/${id}`),
  getRoles: (id: number) => api.get<Role[]>(`/users/${id}/roles`),
  updateRoles: (id: number, roleIds: number[]) => api.patch<Role[]>(`/users/${id}/roles`, { role_ids: roleIds }),
}

export const rolesApi = {
  list: () => api.get<Role[]>('/roles'),
  get: (id: number) => api.get<Role>(`/roles/${id}`),
  create: (data: CreateRoleInput) => api.post<Role>('/roles', { role: data }),
  update: (id: number, data: UpdateRoleInput) => api.patch<Role>(`/roles/${id}`, { role: data }),
  delete: (id: number) => api.delete<void>(`/roles/${id}`),
  getPermissions: (id: number) => api.get<Permission[]>(`/roles/${id}/permissions`),
  updatePermissions: (id: number, permissionIds: number[]) =>
    api.patch<Permission[]>(`/roles/${id}/permissions`, { permission_ids: permissionIds }),
}

export const permissionsApi = {
  list: () => api.get<Permission[]>('/permissions'),
  get: (id: number) => api.get<Permission>(`/permissions/${id}`),
}

export const dashboardApi = {
  get: () => api.get<DashboardData>(''),
}

export interface LlmProvider {
  id: number
  name: string
  api_endpoint: string | null
  organization_id: string | null
  active: boolean
  created_at: string
  updated_at: string
}

export interface LlmModel {
  id: number
  llm_provider_id: number
  name: string
  display_name: string
  active: boolean
  default_model: boolean
  created_at: string
  updated_at: string
}

export interface UpdateLlmProviderInput {
  name?: string
  api_endpoint?: string
  organization_id?: string
  active?: boolean
  api_key?: string
}

export interface CreateLlmModelInput {
  name: string
  display_name: string
  active?: boolean
  default_model?: boolean
}

export interface UpdateLlmModelInput {
  name?: string
  display_name?: string
  active?: boolean
  default_model?: boolean
}

export const llmProvidersApi = {
  list: () => api.get<LlmProvider[]>('/llm_providers'),
  get: (id: number) => api.get<LlmProvider>(`/llm_providers/${id}`),
  update: (id: number, data: UpdateLlmProviderInput) => api.patch<LlmProvider>(`/llm_providers/${id}`, data),
  getAvailableModels: (id: number) => api.get<{ models: string[] }>(`/llm_providers/${id}/available_models`),
}

export const llmModelsApi = {
  list: (providerId: number) => api.get<LlmModel[]>(`/llm_providers/${providerId}/llm_models`),
  get: (providerId: number, id: number) => api.get<LlmModel>(`/llm_providers/${providerId}/llm_models/${id}`),
  create: (providerId: number, data: CreateLlmModelInput) =>
    api.post<LlmModel>(`/llm_providers/${providerId}/llm_models`, data),
  update: (providerId: number, id: number, data: UpdateLlmModelInput) =>
    api.patch<LlmModel>(`/llm_providers/${providerId}/llm_models/${id}`, data),
  delete: (providerId: number, id: number) =>
    api.delete<void>(`/llm_providers/${providerId}/llm_models/${id}`),
}
