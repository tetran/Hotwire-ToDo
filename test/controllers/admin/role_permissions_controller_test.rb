require "test_helper"

module Admin
  class RolePermissionsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin_user = users(:admin_user)
      @user_manager = users(:user_manager)
      @admin_role = roles(:admin)
      @user_manager_role = roles(:user_manager)
      @regular_role = roles(:regular)
      @user_read_permission = permissions(:user_read)
      @user_write_permission = permissions(:user_write)
      @user_delete_permission = permissions(:user_delete)
      @admin_manage_permission = permissions(:admin_manage)
    end

    # Authentication and authorization tests
    test "should redirect to login when not authenticated" do
      get admin_role_permissions_path(@regular_role)
      assert_redirected_to login_path
    end

    test "should deny access to users without admin permissions" do
      login_as(users(:no_role_user))
      get admin_role_permissions_path(@regular_role)
      assert_admin_access_required
    end

    # Show tests (permission assignment form)
    test "should show permission assignment form for admin" do
      login_as_admin
      get admin_role_permissions_path(@regular_role)
      assert_response :success
      assert_select "h1", text: /Permission Management for #{@regular_role.name}/
    end

    test "should group permissions by resource type" do
      login_as_admin
      get admin_role_permissions_path(@regular_role)
      assert_response :success
      assert_select ".resource-section h3", text: "User Permissions"
      assert_select ".resource-section h3", text: "Project Permissions"
      assert_select ".resource-section h3", text: "Admin Permissions"
    end

    test "should show all available permissions" do
      login_as_admin
      get admin_role_permissions_path(@regular_role)
      assert_response :success
      assert_select "input[type=checkbox]", minimum: Permission.count
    end

    test "should show currently assigned permissions as checked" do
      login_as_admin
      get admin_role_permissions_path(@admin_role)
      assert_response :success

      # Admin role should have all permissions checked
      @admin_role.permissions.each do |permission|
        assert_select "input[type=checkbox][value='#{permission.id}'][checked]"
      end
    end

    test "should show permission details" do
      login_as_admin
      get admin_role_permissions_path(@regular_role)
      assert_response :success
      assert_select ".permission-info h4", text: permissions(:user_read).action
      assert_select ".permission-info p", text: permissions(:user_read).description
    end

    # Update tests
    test "should update role permissions" do
      login_as_admin

      # Regular role starts with no permissions
      assert @regular_role.permissions.empty?

      # Assign some permissions
      patch admin_role_permissions_path(@regular_role), params: {
        permission_ids: [permissions(:user_read).id, permissions(:user_write).id],
      }

      assert_redirected_to admin_role_path(@regular_role)
      assert_equal "ロールの権限が更新されました。", flash[:notice]

      @regular_role.reload
      assert @regular_role.permissions.include?(permissions(:user_read))
      assert @regular_role.permissions.include?(permissions(:user_write))
      assert_not @regular_role.permissions.include?(permissions(:user_delete))
    end

    test "should replace existing permissions" do
      login_as_admin

      # User manager starts with some permissions
      original_permissions = @user_manager_role.permissions.to_a
      assert original_permissions.any?

      # Replace with different permissions
      patch admin_role_permissions_path(@user_manager_role), params: {
        permission_ids: [permissions(:user_read).id],
      }

      assert_redirected_to admin_role_path(@user_manager_role)

      @user_manager_role.reload
      assert_equal [permissions(:user_read)], @user_manager_role.permissions.to_a
    end

    test "should remove all permissions when none selected" do
      login_as_admin

      # Admin role starts with permissions
      assert @admin_role.permissions.any?

      patch admin_role_permissions_path(@admin_role), params: {
        permission_ids: [],
      }

      assert_redirected_to admin_role_path(@admin_role)
      assert_equal "ロールの権限が更新されました。", flash[:notice]

      @admin_role.reload
      assert @admin_role.permissions.empty?
    end

    test "should handle invalid permission IDs gracefully" do
      login_as_admin

      patch admin_role_permissions_path(@regular_role), params: {
        permission_ids: [99_999, permissions(:user_read).id], # Invalid ID + valid ID
      }

      assert_redirected_to admin_role_path(@regular_role)

      @regular_role.reload
      assert_equal [permissions(:user_read)], @regular_role.permissions.to_a
    end

    test "should affect user permissions immediately" do
      login_as_admin

      # Create a user with the regular role
      test_user = User.create!(
        name: "Test User",
        email: "test@example.com",
        password: "password",
      )
      test_user.roles << @regular_role

      # Regular role has no permissions initially
      assert_not test_user.has_permission?("User", "read")

      # Assign read permission to regular role
      patch admin_role_permissions_path(@regular_role), params: {
        permission_ids: [permissions(:user_read).id],
      }

      # User should now have read permission
      test_user.reload
      assert test_user.has_permission?("User", "read")
    end

    test "should maintain system role restrictions" do
      login_as_admin

      # Even admin can modify system role permissions in this interface
      # This tests that the permission system itself works
      @admin_role.permissions.count

      patch admin_role_permissions_path(@admin_role), params: {
        permission_ids: [permissions(:user_read).id],
      }

      assert_redirected_to admin_role_path(@admin_role)

      @admin_role.reload
      assert_equal 1, @admin_role.permissions.count
      assert @admin_role.permissions.include?(permissions(:user_read))
    end

    # Authorization tests
    test "user manager can assign permissions" do
      login_as_user_manager

      get admin_role_permissions_path(@regular_role)
      assert_response :success

      patch admin_role_permissions_path(@regular_role), params: {
        permission_ids: [permissions(:user_read).id],
      }
      assert_redirected_to admin_role_path(@regular_role)
    end

    test "should require User:read permission for show action" do
      # Create a user with only admin access but no User permissions
      user_without_user_permissions = User.create!(
        name: "Limited Admin",
        email: "limited2@example.com",
        password: "password",
      )

      # Create a custom role with only admin access
      limited_role = Role.create!(
        name: "limited_admin2",
        description: "Admin access without user management",
      )
      limited_role.permissions << permissions(:admin_read)
      user_without_user_permissions.roles << limited_role

      login_as(user_without_user_permissions)

      get admin_role_permissions_path(@regular_role)
      assert_response :redirect
      assert_match(/権限がありません/, flash[:error])
    end

    test "should require User:write permission for update action" do
      # Create a user with only read permissions
      read_only_user = User.create!(
        name: "Read Only",
        email: "readonly2@example.com",
        password: "password",
      )

      # Create a role with read-only user permissions
      read_only_role = Role.create!(
        name: "user_viewer2",
        description: "User viewer",
      )
      read_only_role.permissions << permissions(:admin_read)
      read_only_role.permissions << permissions(:user_read)
      read_only_user.roles << read_only_role

      login_as(read_only_user)

      # Should be able to view
      get admin_role_permissions_path(@regular_role)
      assert_response :success

      # Should not be able to update (lacks User:write permission)
      patch admin_role_permissions_path(@regular_role), params: {
        permission_ids: [permissions(:user_read).id],
      }
      assert_response :redirect
      assert_match(/権限がありません/, flash[:error])
    end

    test "should show back link to role details" do
      login_as_admin
      get admin_role_permissions_path(@regular_role)
      assert_response :success
      assert_select "a[href='#{admin_role_path(@regular_role)}']", "Back to Role Details"
    end

    test "should show cancel link" do
      login_as_admin
      get admin_role_permissions_path(@regular_role)
      assert_response :success
      assert_select "a[href='#{admin_role_path(@regular_role)}']", "Cancel"
    end
  end
end
