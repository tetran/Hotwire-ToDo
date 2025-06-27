require "test_helper"

class SystemRolesPermissionsTest < ActiveSupport::TestCase
  def setup
    # Ensure seeds have been run
    unless Role.exists?(name: 'llm_admin')
      Rails.application.load_seed
    end
  end

  test "admin role has all permissions" do
    admin_role = Role.admin
    assert_not_nil admin_role
    
    # Admin should have all permissions
    expected_permissions = Permission.count
    assert_equal expected_permissions, admin_role.permissions.count
    
    # Check specific resource access
    assert admin_role.permissions.exists?(resource_type: 'User', action: 'manage')
    assert admin_role.permissions.exists?(resource_type: 'Admin', action: 'manage')
    assert admin_role.permissions.exists?(resource_type: 'Project', action: 'manage')
  end

  test "user_manager role has correct permissions" do
    user_manager_role = Role.user_manager
    assert_not_nil user_manager_role
    
    # Should have User read/write/delete and Admin read only
    expected_permissions = %w[User:read User:write User:delete Admin:read]
    actual_permissions = user_manager_role.permissions.map { |p| "#{p.resource_type}:#{p.action}" }
    
    assert_equal expected_permissions.sort, actual_permissions.sort
    
    # Should NOT have User:manage or Admin:write
    assert_not user_manager_role.permissions.exists?(resource_type: 'User', action: 'manage')
    assert_not user_manager_role.permissions.exists?(resource_type: 'Admin', action: 'write')
  end

  test "user_viewer role has correct permissions" do
    user_viewer_role = Role.user_viewer
    assert_not_nil user_viewer_role
    
    # Should have only User read and Admin read
    expected_permissions = %w[User:read Admin:read]
    actual_permissions = user_viewer_role.permissions.map { |p| "#{p.resource_type}:#{p.action}" }
    
    assert_equal expected_permissions.sort, actual_permissions.sort
  end

  test "project_manager role has correct permissions" do
    project_manager_role = Role.project_manager
    assert_not_nil project_manager_role
    
    # Should have Project/Task/Comment management and Admin read
    expected_resources = %w[Project Task Comment]
    admin_read_permission = project_manager_role.permissions.find_by(resource_type: 'Admin', action: 'read')
    assert_not_nil admin_read_permission
    
    expected_resources.each do |resource|
      %w[read write delete manage].each do |action|
        assert project_manager_role.permissions.exists?(resource_type: resource, action: action),
               "Missing #{resource}:#{action} permission"
      end
    end
    
    # Should NOT have User permissions
    assert_not project_manager_role.permissions.exists?(resource_type: 'User')
  end

  test "llm_admin role has correct permissions" do
    llm_admin_role = Role.llm_admin
    assert_not_nil llm_admin_role
    
    # Should have Admin read/write/delete but not manage
    expected_permissions = %w[Admin:read Admin:write Admin:delete]
    actual_permissions = llm_admin_role.permissions.map { |p| "#{p.resource_type}:#{p.action}" }
    
    assert_equal expected_permissions.sort, actual_permissions.sort
    
    # Should NOT have Admin:manage
    assert_not llm_admin_role.permissions.exists?(resource_type: 'Admin', action: 'manage')
    
    # Should NOT have User permissions
    assert_not llm_admin_role.permissions.exists?(resource_type: 'User')
  end

  test "user with user_manager role has correct permission checks" do
    user = User.create!(
      name: "Test User Manager",
      email: "test_manager@example.com", 
      password: "password"
    )
    user.roles << Role.user_manager
    
    # Should have user management permissions
    assert user.has_permission?('User', 'read')
    assert user.has_permission?('User', 'write') 
    assert user.has_permission?('User', 'delete')
    assert user.has_permission?('Admin', 'read')
    
    # Should NOT have admin write/delete or user manage
    assert_not user.has_permission?('User', 'manage')
    assert_not user.has_permission?('Admin', 'write')
    assert_not user.has_permission?('Admin', 'delete')
    assert_not user.has_permission?('Admin', 'manage')
  end

  test "user with llm_admin role has correct permission checks" do
    user = User.create!(
      name: "Test LLM Admin",
      email: "test_llm@example.com",
      password: "password"
    )
    user.roles << Role.llm_admin
    
    # Should have admin permissions except manage
    assert user.has_permission?('Admin', 'read')
    assert user.has_permission?('Admin', 'write')
    assert user.has_permission?('Admin', 'delete')
    
    # Should NOT have admin manage or user permissions
    assert_not user.has_permission?('Admin', 'manage')
    assert_not user.has_permission?('User', 'read')
    assert_not user.has_permission?('User', 'write')
    assert_not user.has_permission?('Project', 'read')
  end

  test "seeds.rb is idempotent" do
    # Record initial state
    initial_permission_count = Permission.count
    initial_role_count = Role.count
    initial_admin_permissions = Role.admin.permission_ids.sort
    
    # Run seeds again
    Rails.application.load_seed
    
    # Should have same counts and permissions
    assert_equal initial_permission_count, Permission.count
    assert_equal initial_role_count, Role.count
    assert_equal initial_admin_permissions, Role.admin.permission_ids.sort
  end

  test "all required permissions exist" do
    required_permissions = [
      ['Admin', 'read'], ['Admin', 'write'], ['Admin', 'delete'], ['Admin', 'manage'],
      ['User', 'read'], ['User', 'write'], ['User', 'delete'], ['User', 'manage'],
      ['Project', 'read'], ['Project', 'write'], ['Project', 'delete'], ['Project', 'manage'],
      ['Task', 'read'], ['Task', 'write'], ['Task', 'delete'], ['Task', 'manage'],
      ['Comment', 'read'], ['Comment', 'write'], ['Comment', 'delete'], ['Comment', 'manage']
    ]

    required_permissions.each do |resource, action|
      assert Permission.exists?(resource_type: resource, action: action),
             "Missing permission: #{resource}:#{action}"
    end
  end

  test "all system roles exist" do
    expected_roles = %w[admin user_manager user_viewer project_manager llm_admin]
    
    expected_roles.each do |role_name|
      role = Role.find_by(name: role_name, system_role: true)
      assert_not_nil role, "Missing system role: #{role_name}"
    end
  end
end