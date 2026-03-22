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
import { LlmProvidersIndexPage } from './pages/llm-providers/LlmProvidersIndexPage'
import { LlmProviderDetailPage } from './pages/llm-providers/LlmProviderDetailPage'
import { LlmProviderEditPage } from './pages/llm-providers/LlmProviderEditPage'
import { LlmModelsIndexPage } from './pages/llm-providers/LlmModelsIndexPage'
import { LlmModelNewPage } from './pages/llm-providers/LlmModelNewPage'
import { LlmModelEditPage } from './pages/llm-providers/LlmModelEditPage'

const App = () => (
  <BrowserRouter>
    <AuthProvider>
      <Routes>
        <Route path="/admin/login" element={<LoginPage />} />
        <Route path="/admin" element={<ProtectedRoute><AdminLayout /></ProtectedRoute>}>
          <Route index element={<DashboardPage />} />
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
        </Route>
      </Routes>
    </AuthProvider>
  </BrowserRouter>
)

export default App
