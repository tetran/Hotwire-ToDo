import { Route } from 'react-router-dom'
import { RolesIndexPage } from '../pages/roles/RolesIndexPage'
import { RoleNewPage } from '../pages/roles/RoleNewPage'
import { RoleEditPage } from '../pages/roles/RoleEditPage'
import { RolePermissionPage } from '../pages/roles/RolePermissionPage'
import { PermissionsIndexPage } from '../pages/permissions/PermissionsIndexPage'
import { PermissionDetailPage } from '../pages/permissions/PermissionDetailPage'

export const roleRoutes = (
  <>
    <Route path="/admin/roles" element={<RolesIndexPage />} />
    <Route path="/admin/roles/new" element={<RoleNewPage />} />
    <Route path="/admin/roles/:id/edit" element={<RoleEditPage />} />
    <Route path="/admin/roles/:id/permissions" element={<RolePermissionPage />} />
    <Route path="/admin/permissions" element={<PermissionsIndexPage />} />
    <Route path="/admin/permissions/:id" element={<PermissionDetailPage />} />
  </>
)
