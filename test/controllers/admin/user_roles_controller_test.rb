require "test_helper"

class Admin::UserRolesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = users(:admin_user)
    @user_manager = users(:user_manager)
    @regular_user = users(:regular_user)
    @no_role_user = users(:no_role_user)
    @admin_role = roles(:admin)
    @user_manager_role = roles(:user_manager)
    @regular_role = roles(:regular)
  end

  # Authentication and authorization tests
  test "should redirect to login when not authenticated" do
    get admin_user_roles_path(@regular_user)
    assert_redirected_to login_path
  end

  test "should deny access to users without admin permissions" do
    login_as(@no_role_user)
    get admin_user_roles_path(@regular_user)
    assert_admin_access_required
  end

  # Show tests (role assignment form)
  test "should show role assignment form for admin" do
    login_as_admin
    get admin_user_roles_path(@regular_user)
    assert_response :success
    assert_select "h1", text: /#{@regular_user.user_name}.*のロール管理/
  end

  test "should show available roles" do
    login_as_admin
    get admin_user_roles_path(@regular_user)
    assert_response :success
    assert_select "input[type=checkbox]", minimum: Role.count
  end

  test "should show currently assigned roles as checked" do
    login_as_admin
    get admin_user_roles_path(@admin_user)
    assert_response :success
    
    # Admin user should have admin role checked
    assert_select "input[type=checkbox][value='#{@admin_role.id}'][checked]"
  end

  test "should show role descriptions and permissions" do
    login_as_admin
    get admin_user_roles_path(@regular_user)
    assert_response :success
    assert_select ".role-info h3", text: /#{@admin_role.name}/
    assert_select ".role-info p", text: /#{@admin_role.description}/
  end

  # Update tests
  test "should update user roles" do
    login_as_admin
    
    # Initially regular user has regular role
    assert @regular_user.roles.include?(@regular_role)
    assert_not @regular_user.roles.include?(@user_manager_role)
    
    # Assign user_manager role instead
    patch admin_user_roles_path(@regular_user), params: {
      role_ids: [@user_manager_role.id]
    }
    
    assert_redirected_to admin_user_path(@regular_user)
    assert_equal "ユーザーのロールが更新されました。", flash[:notice]
    
    @regular_user.reload
    assert_not @regular_user.roles.include?(@regular_role)
    assert @regular_user.roles.include?(@user_manager_role)
  end

  test "should assign multiple roles" do
    login_as_admin
    
    patch admin_user_roles_path(@no_role_user), params: {
      role_ids: [@regular_role.id, @user_manager_role.id]
    }
    
    assert_redirected_to admin_user_path(@no_role_user)
    assert_equal "ユーザーのロールが更新されました。", flash[:notice]
    
    @no_role_user.reload
    assert @no_role_user.roles.include?(@regular_role)
    assert @no_role_user.roles.include?(@user_manager_role)
    assert_equal 2, @no_role_user.roles.count
  end

  test "should remove all roles when no roles selected" do
    login_as_admin
    
    # Regular user starts with regular role
    assert @regular_user.roles.any?
    
    patch admin_user_roles_path(@regular_user), params: {
      role_ids: []
    }
    
    assert_redirected_to admin_user_path(@regular_user)
    assert_equal "ユーザーのロールが更新されました。", flash[:notice]
    
    @regular_user.reload
    assert @regular_user.roles.empty?
  end

  test "should handle invalid role IDs gracefully" do
    login_as_admin
    
    patch admin_user_roles_path(@regular_user), params: {
      role_ids: [99999, @regular_role.id]  # Invalid ID + valid ID
    }
    
    assert_redirected_to admin_user_path(@regular_user)
    
    @regular_user.reload
    assert_equal [@regular_role], @regular_user.roles.to_a
  end

  test "should maintain existing permissions through role changes" do
    login_as_admin
    
    # User manager has user management permissions
    assert @user_manager.has_permission?('User', 'read')
    assert @user_manager.has_permission?('User', 'write')
    
    # Remove user_manager role, add admin role
    patch admin_user_roles_path(@user_manager), params: {
      role_ids: [@admin_role.id]
    }
    
    @user_manager.reload
    
    # Should still have user permissions through admin role
    assert @user_manager.has_permission?('User', 'read')
    assert @user_manager.has_permission?('User', 'write')
    # Plus additional admin permissions
    assert @user_manager.has_permission?('User', 'delete')
  end

  # Authorization tests
  test "user manager can assign roles" do
    login_as_user_manager
    
    get admin_user_roles_path(@regular_user)
    assert_response :success
    
    patch admin_user_roles_path(@regular_user), params: {
      role_ids: [@user_manager_role.id]
    }
    assert_redirected_to admin_user_path(@regular_user)
  end

  test "should show back link to user details" do
    login_as_admin
    get admin_user_roles_path(@regular_user)
    assert_response :success
    assert_select "a[href='#{admin_user_path(@regular_user)}']", "ユーザー詳細に戻る"
  end
end