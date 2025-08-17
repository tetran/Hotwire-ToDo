require "test_helper"

module Admin
  class PermissionsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin_user = users(:admin_user)
      @user_manager = users(:user_manager)
      @user_read_permission = permissions(:user_read)
      @user_write_permission = permissions(:user_write)
      @admin_manage_permission = permissions(:admin_manage)
    end

    # Authentication and authorization tests
    test "should redirect to login when not authenticated" do
      get admin_permissions_path
      assert_redirected_to login_path
    end

    test "should deny access to users without admin permissions" do
      login_as(users(:no_role_user))
      get admin_permissions_path
      assert_admin_access_required
    end

    # Index tests
    test "should get index for admin" do
      login_as_admin
      get admin_permissions_path
      assert_response :success
      assert_select "h1", "Permission Management"
    end

    test "should get index for user manager" do
      login_as_user_manager
      get admin_permissions_path
      assert_response :success
    end

    test "should group permissions by resource type" do
      login_as_admin
      get admin_permissions_path
      assert_response :success
      assert_select ".permissions-section h2", text: "User Permissions"
      assert_select ".permissions-section h2", text: "Project Permissions"
      assert_select ".permissions-section h2", text: "Admin Permissions"
    end

    test "should show all permissions with details" do
      login_as_admin
      get admin_permissions_path
      assert_response :success

      # Should show permission cards
      assert_select ".permission-card", minimum: Permission.count
      assert_select ".permission-card h3", text: @user_read_permission.name
      assert_select ".permission-card p", text: @user_read_permission.description
    end

    test "should show roles that have each permission" do
      login_as_admin
      get admin_permissions_path
      assert_response :success

      # Should show which roles have the permission
      assert_select ".permission-roles", minimum: 1
    end

    # Show tests
    test "should show permission details" do
      login_as_admin
      get admin_permission_path(@user_read_permission)
      assert_response :success
      assert_select "h1", "Permission Details"
    end

    test "should show permission information" do
      login_as_admin
      get admin_permission_path(@user_read_permission)
      assert_response :success

      assert_select "td", text: @user_read_permission.resource_type
      assert_select "td", text: @user_read_permission.action
      assert_select "td", text: @user_read_permission.description
    end

    test "should show roles with this permission" do
      login_as_admin
      get admin_permission_path(@user_read_permission)
      assert_response :success

      # Should show roles that have this permission
      @user_read_permission.roles.each do |role|
        assert_select ".role-card h3", text: /#{role.name}/
      end
    end

    test "should show users with this permission through roles" do
      login_as_admin
      get admin_permission_path(@admin_manage_permission)
      assert_response :success

      # Should show roles who have this permission
      assert_select ".detail-section"
    end

    test "should handle permission with no roles" do
      Permission.where(resource_type: "Project", action: "read").destroy_all
      # Create a permission with no roles
      unused_permission = Permission.create!(
        resource_type: "Project",
        action: "read",
        description: "Unused permission",
      )

      login_as_admin
      get admin_permission_path(unused_permission)
      assert_response :success
      assert_select ".empty-state", text: /No roles have this permission./
    end

    # Navigation tests
    test "should show back link to permissions index" do
      login_as_admin
      get admin_permission_path(@user_read_permission)
      assert_response :success
      assert_select "a[href='#{admin_permissions_path}']", "Back to List"
    end

    # Read-only nature tests
    test "should not have edit or delete links" do
      login_as_admin
      get admin_permissions_path
      assert_response :success

      # Permissions are read-only, should not have edit/delete links
      assert_select "a", text: "編集", count: 0
      assert_select "a", text: "削除", count: 0
    end

    test "should not have new permission link" do
      login_as_admin
      get admin_permissions_path
      assert_response :success

      # Should not have create new permission functionality
      assert_select "a", text: /新.*権限.*作成/, count: 0
    end

    # Authorization level tests
    test "user manager can view permissions" do
      login_as_user_manager

      # Can view index
      get admin_permissions_path
      assert_response :success

      # Can view individual permission
      get admin_permission_path(@user_read_permission)
      assert_response :success
    end

    # Data integrity tests
    test "should show correct permission counts" do
      login_as_admin
      get admin_permissions_path
      assert_response :success

      # Check that we're showing all permissions
      user_permissions = Permission.where(resource_type: "User")
      project_permissions = Permission.where(resource_type: "Project")
      admin_permissions = Permission.where(resource_type: "Admin")

      assert_select ".permissions-section:has(h2:contains('User')) .permission-card", count: user_permissions.count
      assert_select ".permissions-section:has(h2:contains('Project')) .permission-card",
                    count: project_permissions.count
      assert_select ".permissions-section:has(h2:contains('Admin')) .permission-card", count: admin_permissions.count
    end

    test "should handle permissions with special characters in description" do
      Permission.where(resource_type: "Project", action: "read").destroy_all
      special_permission = Permission.create!(
        resource_type: "Project",
        action: "read",
        description: "Permission with special chars: <>&\"",
      )

      login_as_admin
      get admin_permission_path(special_permission)
      assert_response :success

      # Should properly escape special characters
      assert_select "td", text: "Permission with special chars: <>&\""
    end
  end
end
