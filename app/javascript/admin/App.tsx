import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { AuthProvider } from './contexts/AuthContext'
import { ProtectedRoute } from './components/ProtectedRoute'
import { AdminLayout } from './components/AdminLayout'
import { LoginPage } from './pages/LoginPage'
import { DashboardPage } from './pages/DashboardPage'
import { UsersIndexPage } from './pages/users/UsersIndexPage'
import { UserNewPage } from './pages/users/UserNewPage'
import { UserEditPage } from './pages/users/UserEditPage'
import { UserRolePage } from './pages/users/UserRolePage'
import { RolesIndexPage } from './pages/roles/RolesIndexPage'
import { RoleNewPage } from './pages/roles/RoleNewPage'
import { RoleEditPage } from './pages/roles/RoleEditPage'
import { RolePermissionPage } from './pages/roles/RolePermissionPage'
import { PermissionsIndexPage } from './pages/permissions/PermissionsIndexPage'
import { PermissionDetailPage } from './pages/permissions/PermissionDetailPage'
import { AdminAccountsIndexPage } from './pages/admin-accounts/AdminAccountsIndexPage'
import { AdminAccountNewPage } from './pages/admin-accounts/AdminAccountNewPage'
import { AdminAccountDetailPage } from './pages/admin-accounts/AdminAccountDetailPage'
import { AdminAccountEditPage } from './pages/admin-accounts/AdminAccountEditPage'
import { AdminAccountRolesEditPage } from './pages/admin-accounts/AdminAccountRolesEditPage'
import { LlmProvidersIndexPage } from './pages/llm-providers/LlmProvidersIndexPage'
import { LlmProviderDetailPage } from './pages/llm-providers/LlmProviderDetailPage'
import { LlmProviderEditPage } from './pages/llm-providers/LlmProviderEditPage'
import { LlmModelsIndexPage } from './pages/llm-providers/LlmModelsIndexPage'
import { LlmModelNewPage } from './pages/llm-providers/LlmModelNewPage'
import { LlmModelEditPage } from './pages/llm-providers/LlmModelEditPage'
import { PromptSetsIndexPage } from './pages/prompt-sets/PromptSetsIndexPage'
import { PromptSetNewPage } from './pages/prompt-sets/PromptSetNewPage'
import { PromptSetEditPage } from './pages/prompt-sets/PromptSetEditPage'
import { SuggestionConfigsIndexPage } from './pages/suggestion-configs/SuggestionConfigsIndexPage'
import { SuggestionConfigNewPage } from './pages/suggestion-configs/SuggestionConfigNewPage'
import { SuggestionConfigDetailPage } from './pages/suggestion-configs/SuggestionConfigDetailPage'
import { EventsIndexPage } from './pages/events/EventsIndexPage'

const App = () => (
  <BrowserRouter>
    <AuthProvider>
      <Routes>
        <Route path="/admin/login" element={<LoginPage />} />
        <Route path="/admin" element={<ProtectedRoute><AdminLayout /></ProtectedRoute>}>
          <Route index element={<DashboardPage />} />
          <Route path="admin-accounts" element={
            <ProtectedRoute requiredCapability={{ resource: 'Admin', action: 'read' }}>
              <AdminAccountsIndexPage />
            </ProtectedRoute>
          } />
          <Route path="admin-accounts/new" element={
            <ProtectedRoute requiredCapability={{ resource: 'User', action: 'write' }}>
              <AdminAccountNewPage />
            </ProtectedRoute>
          } />
          <Route path="admin-accounts/:id" element={
            <ProtectedRoute requiredCapability={{ resource: 'Admin', action: 'read' }}>
              <AdminAccountDetailPage />
            </ProtectedRoute>
          } />
          <Route path="admin-accounts/:id/edit" element={
            <ProtectedRoute requiredCapability={{ resource: 'User', action: 'write' }}>
              <AdminAccountEditPage />
            </ProtectedRoute>
          } />
          <Route path="admin-accounts/:id/roles" element={
            <ProtectedRoute requiredCapability={{ resource: 'User', action: 'write' }}>
              <AdminAccountRolesEditPage />
            </ProtectedRoute>
          } />
          <Route path="users" element={
            <ProtectedRoute requiredCapability={{ resource: 'User', action: 'read' }}>
              <UsersIndexPage />
            </ProtectedRoute>
          } />
          <Route path="users/new" element={
            <ProtectedRoute requiredCapability={{ resource: 'User', action: 'write' }}>
              <UserNewPage />
            </ProtectedRoute>
          } />
          <Route path="users/:id/edit" element={
            <ProtectedRoute requiredCapability={{ resource: 'User', action: 'write' }}>
              <UserEditPage />
            </ProtectedRoute>
          } />
          <Route path="users/:id/roles" element={
            <ProtectedRoute requiredCapability={{ resource: 'User', action: 'read' }}>
              <UserRolePage />
            </ProtectedRoute>
          } />
          <Route path="roles" element={
            <ProtectedRoute requireAdmin>
              <RolesIndexPage />
            </ProtectedRoute>
          } />
          <Route path="roles/new" element={
            <ProtectedRoute requireAdmin>
              <RoleNewPage />
            </ProtectedRoute>
          } />
          <Route path="roles/:id/edit" element={
            <ProtectedRoute requireAdmin>
              <RoleEditPage />
            </ProtectedRoute>
          } />
          <Route path="roles/:id/permissions" element={
            <ProtectedRoute requireAdmin>
              <RolePermissionPage />
            </ProtectedRoute>
          } />
          <Route path="permissions" element={
            <ProtectedRoute requireAdmin>
              <PermissionsIndexPage />
            </ProtectedRoute>
          } />
          <Route path="permissions/:id" element={
            <ProtectedRoute requireAdmin>
              <PermissionDetailPage />
            </ProtectedRoute>
          } />
          <Route path="llm-providers" element={
            <ProtectedRoute requiredCapability={{ resource: 'LlmProvider', action: 'read' }}>
              <LlmProvidersIndexPage />
            </ProtectedRoute>
          } />
          <Route path="llm-providers/:id" element={
            <ProtectedRoute requiredCapability={{ resource: 'LlmProvider', action: 'read' }}>
              <LlmProviderDetailPage />
            </ProtectedRoute>
          } />
          <Route path="llm-providers/:id/edit" element={
            <ProtectedRoute requiredCapability={{ resource: 'LlmProvider', action: 'write' }}>
              <LlmProviderEditPage />
            </ProtectedRoute>
          } />
          <Route path="llm-providers/:id/models" element={
            <ProtectedRoute requiredCapability={{ resource: 'LlmProvider', action: 'read' }}>
              <LlmModelsIndexPage />
            </ProtectedRoute>
          } />
          <Route path="llm-providers/:id/models/new" element={
            <ProtectedRoute requiredCapability={{ resource: 'LlmProvider', action: 'write' }}>
              <LlmModelNewPage />
            </ProtectedRoute>
          } />
          <Route path="llm-providers/:id/models/:modelId/edit" element={
            <ProtectedRoute requiredCapability={{ resource: 'LlmProvider', action: 'write' }}>
              <LlmModelEditPage />
            </ProtectedRoute>
          } />
          <Route path="prompt-sets" element={
            <ProtectedRoute requiredCapability={{ resource: 'LlmProvider', action: 'read' }}>
              <PromptSetsIndexPage />
            </ProtectedRoute>
          } />
          <Route path="prompt-sets/new" element={
            <ProtectedRoute requiredCapability={{ resource: 'LlmProvider', action: 'write' }}>
              <PromptSetNewPage />
            </ProtectedRoute>
          } />
          <Route path="prompt-sets/:id/edit" element={
            <ProtectedRoute requiredCapability={{ resource: 'LlmProvider', action: 'write' }}>
              <PromptSetEditPage />
            </ProtectedRoute>
          } />
          <Route path="suggestion-configs" element={
            <ProtectedRoute requiredCapability={{ resource: 'LlmProvider', action: 'read' }}>
              <SuggestionConfigsIndexPage />
            </ProtectedRoute>
          } />
          <Route path="suggestion-configs/new" element={
            <ProtectedRoute requiredCapability={{ resource: 'LlmProvider', action: 'write' }}>
              <SuggestionConfigNewPage />
            </ProtectedRoute>
          } />
          <Route path="suggestion-configs/:id" element={
            <ProtectedRoute requiredCapability={{ resource: 'LlmProvider', action: 'read' }}>
              <SuggestionConfigDetailPage />
            </ProtectedRoute>
          } />
          <Route path="events" element={
            <ProtectedRoute requiredCapability={{ resource: 'EventLog', action: 'read' }}>
              <EventsIndexPage />
            </ProtectedRoute>
          } />
        </Route>
      </Routes>
    </AuthProvider>
  </BrowserRouter>
)

export default App
