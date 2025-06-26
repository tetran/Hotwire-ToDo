class AddGranularAdminPermissionsToExistingRoles < ActiveRecord::Migration[7.2]
  def up
    # Create new granular Admin permissions if they don't exist
    admin_read = Permission.find_or_create_by!(
      resource_type: 'Admin', 
      action: 'read'
    ) do |p|
      p.description = '管理画面の閲覧'
    end

    admin_write = Permission.find_or_create_by!(
      resource_type: 'Admin', 
      action: 'write'
    ) do |p|
      p.description = '管理画面での編集操作'
    end

    admin_delete = Permission.find_or_create_by!(
      resource_type: 'Admin', 
      action: 'delete'
    ) do |p|
      p.description = '管理画面での削除操作'
    end

    admin_manage = Permission.find_or_create_by!(
      resource_type: 'Admin', 
      action: 'manage'
    ) do |p|
      p.description = '管理画面の完全管理'
    end

    # Update existing roles to maintain backward compatibility
    
    # user_manager: should have Admin:read, write (but not delete)
    if user_manager_role = Role.find_by(name: 'user_manager', system_role: true)
      # Remove old Admin:manage if it exists
      old_admin_manage = user_manager_role.permissions.find_by(resource_type: 'Admin', action: 'manage')
      user_manager_role.permissions.delete(old_admin_manage) if old_admin_manage
      
      # Add new granular permissions
      user_manager_role.permissions << admin_read unless user_manager_role.permissions.include?(admin_read)
      user_manager_role.permissions << admin_write unless user_manager_role.permissions.include?(admin_write)
      
      puts "Updated user_manager role: Admin:read + Admin:write permissions"
    end

    # project_manager: should have Admin:read only (for viewing admin panels)
    if project_manager_role = Role.find_by(name: 'project_manager', system_role: true)
      # Remove old Admin:manage if it exists
      old_admin_manage = project_manager_role.permissions.find_by(resource_type: 'Admin', action: 'manage')
      project_manager_role.permissions.delete(old_admin_manage) if old_admin_manage
      
      # Add only read permission
      project_manager_role.permissions << admin_read unless project_manager_role.permissions.include?(admin_read)
      
      puts "Updated project_manager role: Admin:read permission only"
    end

    # user_viewer: should have Admin:read only (already correct from seeds)
    if user_viewer_role = Role.find_by(name: 'user_viewer', system_role: true)
      # Remove old Admin:manage if it exists
      old_admin_manage = user_viewer_role.permissions.find_by(resource_type: 'Admin', action: 'manage')
      user_viewer_role.permissions.delete(old_admin_manage) if old_admin_manage
      
      # Ensure read permission
      user_viewer_role.permissions << admin_read unless user_viewer_role.permissions.include?(admin_read)
      
      puts "Updated user_viewer role: Admin:read permission"
    end

    # admin: should have all permissions (ensure they have the new ones)
    if admin_role = Role.find_by(name: 'admin', system_role: true)
      admin_role.permissions << admin_read unless admin_role.permissions.include?(admin_read)
      admin_role.permissions << admin_write unless admin_role.permissions.include?(admin_write)
      admin_role.permissions << admin_delete unless admin_role.permissions.include?(admin_delete)
      admin_role.permissions << admin_manage unless admin_role.permissions.include?(admin_manage)
      
      puts "Updated admin role: all Admin permissions"
    end
  end

  def down
    # Revert to old Admin:manage-only approach
    admin_manage = Permission.find_by(resource_type: 'Admin', action: 'manage')
    return unless admin_manage

    # user_manager: restore Admin:manage
    if user_manager_role = Role.find_by(name: 'user_manager', system_role: true)
      # Remove granular permissions
      user_manager_role.permissions.where(resource_type: 'Admin', action: ['read', 'write', 'delete']).destroy_all
      # Add back manage permission
      user_manager_role.permissions << admin_manage unless user_manager_role.permissions.include?(admin_manage)
    end

    # project_manager: restore Admin:manage  
    if project_manager_role = Role.find_by(name: 'project_manager', system_role: true)
      # Remove granular permissions
      project_manager_role.permissions.where(resource_type: 'Admin', action: ['read', 'write', 'delete']).destroy_all
      # Add back manage permission
      project_manager_role.permissions << admin_manage unless project_manager_role.permissions.include?(admin_manage)
    end

    # user_viewer: restore Admin:manage
    if user_viewer_role = Role.find_by(name: 'user_viewer', system_role: true)
      # Remove granular permissions  
      user_viewer_role.permissions.where(resource_type: 'Admin', action: ['read', 'write', 'delete']).destroy_all
      # Add back manage permission
      user_viewer_role.permissions << admin_manage unless user_viewer_role.permissions.include?(admin_manage)
    end

    # Remove the granular permissions if no roles use them
    %w[read write delete].each do |action|
      permission = Permission.find_by(resource_type: 'Admin', action: action)
      if permission && permission.roles.empty?
        permission.destroy
      end
    end
  end
end
