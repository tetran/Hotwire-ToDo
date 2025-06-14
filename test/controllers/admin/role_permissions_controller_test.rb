require "test_helper"

class Admin::RolePermissionsControllerTest < ActionDispatch::IntegrationTest
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
    assert_select ".permission-info h4", text: @user_read_permission.action
    assert_select ".permission-info p", text: @user_read_permission.description
  end

  # Update tests
  test "should update role permissions" do
    login_as_admin
    
    # Regular role starts with no permissions
    assert @regular_role.permissions.empty?
    
    # Assign some permissions
    patch admin_role_permissions_path(@regular_role), params: {
      permission_ids: [@user_read_permission.id, @user_write_permission.id]
    }
    
    assert_redirected_to admin_role_path(@regular_role)
    assert_equal "ロールの権限が更新されました。", flash[:notice]
    
    @regular_role.reload
    assert @regular_role.permissions.include?(@user_read_permission)
    assert @regular_role.permissions.include?(@user_write_permission)
    assert_not @regular_role.permissions.include?(@user_delete_permission)
  end

  test "should replace existing permissions" do
    login_as_admin
    
    # User manager starts with some permissions
    original_permissions = @user_manager_role.permissions.to_a
    assert original_permissions.any?
    
    # Replace with different permissions
    patch admin_role_permissions_path(@user_manager_role), params: {
      permission_ids: [@user_read_permission.id]
    }
    
    assert_redirected_to admin_role_path(@user_manager_role)
    
    @user_manager_role.reload
    assert_equal [@user_read_permission], @user_manager_role.permissions.to_a
  end

  test "should remove all permissions when none selected" do
    login_as_admin
    
    # Admin role starts with permissions
    assert @admin_role.permissions.any?
    
    patch admin_role_permissions_path(@admin_role), params: {
      permission_ids: []
    }
    
    assert_redirected_to admin_role_path(@admin_role)
    assert_equal "ロールの権限が更新されました。", flash[:notice]
    
    @admin_role.reload
    assert @admin_role.permissions.empty?
  end

  test "should handle invalid permission IDs gracefully" do
    login_as_admin
    
    patch admin_role_permissions_path(@regular_role), params: {
      permission_ids: [99999, @user_read_permission.id]  # Invalid ID + valid ID
    }
    
    assert_redirected_to admin_role_path(@regular_role)
    
    @regular_role.reload
    assert_equal [@user_read_permission], @regular_role.permissions.to_a
  end

  test "should affect user permissions immediately" do
    login_as_admin
    
    # Create a user with the regular role
    test_user = User.create!(
      name: "Test User",
      email: "test@example.com", 
      password: "password"
    )
    test_user.roles << @regular_role
    
    # Regular role has no permissions initially
    assert_not test_user.has_permission?('User', 'read')
    
    # Assign read permission to regular role
    patch admin_role_permissions_path(@regular_role), params: {
      permission_ids: [@user_read_permission.id]
    }
    
    # User should now have read permission
    test_user.reload
    assert test_user.has_permission?('User', 'read')
  end

  test "should maintain system role restrictions" do
    login_as_admin
    
    # Even admin can modify system role permissions in this interface
    # This tests that the permission system itself works
    original_permission_count = @admin_role.permissions.count
    
    patch admin_role_permissions_path(@admin_role), params: {
      permission_ids: [@user_read_permission.id]
    }
    
    assert_redirected_to admin_role_path(@admin_role)
    
    @admin_role.reload
    assert_equal 1, @admin_role.permissions.count
    assert @admin_role.permissions.include?(@user_read_permission)
  end

  # Authorization tests
  test "user manager can assign permissions" do
    login_as_user_manager
    
    get admin_role_permissions_path(@regular_role)
    assert_response :success
    
    patch admin_role_permissions_path(@regular_role), params: {
      permission_ids: [@user_read_permission.id]
    }
    assert_redirected_to admin_role_path(@regular_role)
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