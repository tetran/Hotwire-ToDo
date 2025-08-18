require "test_helper"

module Admin
  class UserRolePermissionsIntegrationTest < ActionDispatch::IntegrationTest
    setup do
      @admin_user = users(:admin_user)
      @regular_user = users(:regular_user)
      @user_manager = users(:user_manager)
      @no_role_user = users(:no_role_user)

      # Ensure user_manager has Admin:read + User:read + User:write
      admin_read_perm = Permission.find_or_create_by!(resource_type: "Admin", action: "read") do |p|
        p.description = "Admin read"
      end
      user_read_perm = Permission.find_or_create_by!(resource_type: "User", action: "read") do |p|
        p.description = "User read"
      end
      user_write_perm = Permission.find_or_create_by!(resource_type: "User", action: "write") do |p|
        p.description = "User write"
      end

      user_manager_role = @user_manager.roles.first
      user_manager_role.permissions << admin_read_perm unless user_manager_role.permissions.include?(admin_read_perm)
      user_manager_role.permissions << user_read_perm unless user_manager_role.permissions.include?(user_read_perm)
      user_manager_role.permissions << user_write_perm unless user_manager_role.permissions.include?(user_write_perm)
    end

    # Issue #126: Admin:read + User:read requirement tests
    test "user with Admin:read + User:read can access user list" do
      login_as(@user_manager)
      get admin_users_path
      assert_response :success
    end

    test "user with Admin:read + User:read can view user details" do
      login_as(@user_manager)
      get admin_user_path(@regular_user)
      assert_response :success
    end

    test "user with Admin:read + User:write can create users" do
      login_as(@user_manager)
      get new_admin_user_path
      assert_response :success

      post admin_users_path, params: {
        user: {
          name: "Test User",
          email: "test#{Time.current.to_i}@example.com",
          password: "password123",
          password_confirmation: "password123",
        },
      }
      assert_response :redirect
    end

    test "user with Admin:read + User:write can edit users" do
      login_as(@user_manager)
      get edit_admin_user_path(@regular_user)
      assert_response :success

      patch admin_user_path(@regular_user), params: {
        user: { name: "Updated Name" },
      }
      assert_response :redirect
    end

    test "user with only Admin:read cannot access user management" do
      # Create user with only Admin:read permission
      admin_read_only_user = users(:no_role_user)
      admin_read_perm = Permission.find_by!(resource_type: "Admin", action: "read")
      admin_read_role = Role.create!(name: "admin_read_only", system_role: false)
      admin_read_role.permissions << admin_read_perm
      admin_read_only_user.roles << admin_read_role

      login_as(admin_read_only_user)

      # Should be denied access to user list (needs User:read)
      get admin_users_path
      assert_response :redirect
      assert_match(/権限がありません/, flash[:error])
    end

    test "user with only User:read cannot access admin area" do
      # Create user with only User:read permission (no Admin:read)
      user_read_only_user = users(:no_role_user)
      user_read_perm = Permission.find_by!(resource_type: "User", action: "read")
      user_read_role = Role.create!(name: "user_read_only", system_role: false)
      user_read_role.permissions << user_read_perm
      user_read_only_user.roles << user_read_role

      login_as(user_read_only_user)

      # Should be denied access to user list (needs Admin:read first)
      get admin_users_path
      assert_response :redirect
      assert_match(/管理者権限が必要です/, flash[:error])
    end

    # Issue #126: Role management permission tests
    test "user with Admin:read + User:read can access role list" do
      login_as(@user_manager)
      get admin_roles_path
      assert_response :success
    end

    test "user with Admin:read + User:write can create roles" do
      login_as(@user_manager)
      get new_admin_role_path
      assert_response :success

      post admin_roles_path, params: {
        role: {
          name: "test_role_#{Time.current.to_i}",
          description: "Test Role",
        },
      }
      assert_response :redirect
    end

    # Issue #126: Permission viewing tests
    test "user with Admin:read + User:read can view permissions" do
      login_as(@user_manager)
      get admin_permissions_path
      assert_response :success
    end

    # Issue #126: User role management tests
    test "user with Admin:read + User:read can view user roles" do
      login_as(@user_manager)
      get admin_user_roles_path(user_id: @regular_user.id)
      assert_response :success
    end

    test "user with Admin:read + User:write can update user roles" do
      login_as(@user_manager)
      role = Role.first

      patch admin_user_roles_path(user_id: @regular_user.id), params: {
        role_ids: [role.id],
      }
      assert_response :redirect
    end

    # Issue #126: Role permission management tests
    test "user with Admin:read + User:read can view role permissions" do
      login_as(@user_manager)
      role = Role.first

      get admin_role_permissions_path(role_id: role.id)
      assert_response :success
    end

    test "user with Admin:read + User:write can update role permissions" do
      login_as(@user_manager)
      role = Role.first
      permission = Permission.first

      patch admin_role_permissions_path(role_id: role.id), params: {
        permission_ids: [permission.id],
      }
      assert_response :redirect
    end

    # Issue #126: System role protection tests
    test "system role deletion protection is maintained" do
      login_as(@admin_user) # Even admin should not be able to delete system roles
      system_role = Role.find_by(system_role: true)

      delete admin_role_path(system_role)
      assert_response :redirect
      assert_match(/システムロールは削除できません/, flash[:error])
    end
  end
end
