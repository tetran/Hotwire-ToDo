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

let isRedirectingToLogin = false

export const resetRedirectGuard = () => {
  isRedirectingToLogin = false
}

// Dispatched on 403 to signal that cached capabilities may be stale.
// Note: A 403 does not always mean stale cache — the user may genuinely lack
// the permission. The cooldown prevents excessive refresh attempts.
export const CAPABILITIES_STALE_EVENT = 'capabilities-stale'
const CAPABILITIES_STALE_COOLDOWN_MS = 5000
let lastCapabilitiesStaleDispatch = 0

export const resetCapabilitiesStaleCooldown = () => {
  lastCapabilitiesStaleDispatch = 0
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
    // Suppress redirect for GET/POST /session (session check and login)
    // to avoid redirect loops. DELETE /session (logout) should still redirect.
    const method = (options.method ?? 'GET').toUpperCase()
    const isSessionAuthEndpoint = path.startsWith('/session') && (method === 'GET' || method === 'POST')
    if (response.status === 401 && !isSessionAuthEndpoint) {
      if (!isRedirectingToLogin) {
        isRedirectingToLogin = true
        window.location.href = '/admin/login'
      }
      return new Promise(() => {}) as T
    }
    if (response.status === 403) {
      const now = Date.now()
      if (now - lastCapabilitiesStaleDispatch > CAPABILITIES_STALE_COOLDOWN_MS) {
        lastCapabilitiesStaleDispatch = now
        window.dispatchEvent(new Event(CAPABILITIES_STALE_EVENT))
      }
    }
    const error = await response.json().catch(() => ({ error: 'Unknown error' }))
    throw new Error(error.error ?? `HTTP ${response.status}`)
  }

  if (response.status === 204) return undefined as T

  return response.json() as Promise<T>
}

export const api = {
  get: <T>(path: string, options?: { signal?: AbortSignal }) =>
    apiRequest<T>(path, options),
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
  list: (params?: { q?: string }, options?: { signal?: AbortSignal }) => {
    const query = new URLSearchParams()
    if (params?.q) query.set('q', params.q)
    const qs = query.toString()
    return api.get<User[]>(qs ? `/users?${qs}` : '/users', options)
  },
  get: (id: number) => api.get<User>(`/users/${id}`),
  create: (data: CreateUserInput) => api.post<User>('/users', { user: data }),
  update: (id: number, data: UpdateUserInput) => api.patch<User>(`/users/${id}`, { user: data }),
  delete: (id: number) => api.delete<void>(`/users/${id}`),
  getRoles: (id: number) => api.get<Role[]>(`/users/${id}/roles`),
  updateRoles: (id: number, roleIds: number[]) => api.patch<Role[]>(`/users/${id}/roles`, { role_ids: roleIds }),
}

export interface CreateAdminAccountInput {
  email: string
  name: string
  password: string
  role_ids: number[]
}

export type PermissionMatrix = Record<ResourceType, Record<Action, boolean>>

export interface AdminAccountDetail extends User {
  roles: { id: number; name: string; description: string | null; system_role: boolean }[]
  permission_matrix: PermissionMatrix
}

export const adminAccountsApi = {
  list: (params?: { q?: string }, options?: { signal?: AbortSignal }) => {
    const query = new URLSearchParams()
    if (params?.q) query.set('q', params.q)
    const qs = query.toString()
    return api.get<User[]>(qs ? `/admin_accounts?${qs}` : '/admin_accounts', options)
  },
  get: (id: number) => api.get<AdminAccountDetail>(`/admin_accounts/${id}`),
  create: (data: CreateAdminAccountInput) =>
    api.post<User>('/admin_accounts', { admin_account: data }),
  delete: (id: number) => api.delete<void>(`/admin_accounts/${id}`),
  revoke: (id: number) => api.post<void>(`/admin_accounts/${id}/revocation`),
  getRoles: (id: number) => api.get<Role[]>(`/admin_accounts/${id}/roles`),
  updateRoles: (id: number, roleIds: number[]) =>
    api.patch<Role[]>(`/admin_accounts/${id}/roles`, { role_ids: roleIds }),
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

export interface AvailableModel {
  id: string
  name: string
  display_name?: string
}

export const llmProvidersApi = {
  list: () => api.get<LlmProvider[]>('/llm_providers'),
  get: (id: number) => api.get<LlmProvider>(`/llm_providers/${id}`),
  update: (id: number, data: UpdateLlmProviderInput) => api.patch<LlmProvider>(`/llm_providers/${id}`, { llm_provider: data }),
  getAvailableModels: (id: number) => api.get<AvailableModel[]>(`/llm_providers/${id}/available_models`),
}

export interface Prompt {
  id: number
  role: 'system' | 'user'
  body: string
  position: number
}

export interface PromptSet {
  id: number
  name: string
  active: boolean
  created_at: string
  updated_at: string
  prompts: Prompt[]
  in_use?: boolean
}

export interface PromptInput {
  id?: number
  role: 'system' | 'user'
  body: string
  position: number
  _destroy?: boolean
}

export interface CreatePromptSetInput {
  name: string
  active?: boolean
  prompts_attributes: PromptInput[]
}

export interface UpdatePromptSetInput {
  name?: string
  active?: boolean
  prompts_attributes?: PromptInput[]
}

export interface SuggestionConfigEntry {
  id: number
  weight: number
  llm_model_id: number
  prompt_set_id: number
  llm_model: { id: number; name: string; display_name: string }
  prompt_set: { id: number; name: string }
}

export interface SuggestionConfig {
  id: number
  active: boolean
  created_at: string
  updated_at: string
  entries: SuggestionConfigEntry[]
}

export interface EntryInput {
  id?: number
  llm_model_id: number
  prompt_set_id: number
  weight: number
  _destroy?: boolean
}

export interface CreateSuggestionConfigInput {
  entries_attributes: Omit<EntryInput, 'id' | '_destroy'>[]
}

export interface UpdateSuggestionConfigInput {
  entries_attributes: EntryInput[]
}

export const llmModelsApi = {
  list: (providerId: number) => api.get<LlmModel[]>(`/llm_providers/${providerId}/llm_models`),
  get: (providerId: number, id: number) => api.get<LlmModel>(`/llm_providers/${providerId}/llm_models/${id}`),
  create: (providerId: number, data: CreateLlmModelInput) =>
    api.post<LlmModel>(`/llm_providers/${providerId}/llm_models`, { llm_model: data }),
  update: (providerId: number, id: number, data: UpdateLlmModelInput) =>
    api.patch<LlmModel>(`/llm_providers/${providerId}/llm_models/${id}`, { llm_model: data }),
  delete: (providerId: number, id: number) =>
    api.delete<void>(`/llm_providers/${providerId}/llm_models/${id}`),
}

export const promptSetsApi = {
  list: () => api.get<PromptSet[]>('/prompt_sets'),
  get: (id: number) => api.get<PromptSet>(`/prompt_sets/${id}`),
  create: (data: CreatePromptSetInput) => api.post<PromptSet>('/prompt_sets', { prompt_set: data }),
  update: (id: number, data: UpdatePromptSetInput) => api.patch<PromptSet>(`/prompt_sets/${id}`, { prompt_set: data }),
}

export const suggestionConfigsApi = {
  list: () => api.get<SuggestionConfig[]>('/suggestion_configs'),
  get: (id: number) => api.get<SuggestionConfig>(`/suggestion_configs/${id}`),
  create: (data: CreateSuggestionConfigInput) =>
    api.post<SuggestionConfig>('/suggestion_configs', { suggestion_config: data }),
  update: (id: number, data: UpdateSuggestionConfigInput) =>
    api.patch<SuggestionConfig>(`/suggestion_configs/${id}`, { suggestion_config: data }),
}
