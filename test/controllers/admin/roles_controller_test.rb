require "test_helper"

class Admin::RolesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = users(:admin_user)
    @user_manager = users(:user_manager)
    @admin_role = roles(:admin)
    @user_manager_role = roles(:user_manager)
    @regular_role = roles(:regular)
  end

  # Authentication and authorization tests
  test "should redirect to login when not authenticated" do
    get admin_roles_path
    assert_redirected_to login_path
  end

  test "should deny access to users without admin permissions" do
    login_as(users(:no_role_user))
    get admin_roles_path
    assert_admin_access_required
  end

  # Index tests
  test "should get index for admin" do
    login_as_admin
    get admin_roles_path
    assert_response :success
    assert_select "h1", "Role Management"
  end

  test "should separate system and custom roles" do
    login_as_admin
    get admin_roles_path
    assert_response :success
    assert_select "h2", "System Roles"
    assert_select "h2", "Custom Roles"
  end

  # Show tests
  test "should show role" do
    login_as_admin
    get admin_role_path(@admin_role)
    assert_response :success
    assert_select "h1", "Role Details"
  end

  # New/Create tests
  test "should get new" do
    login_as_admin
    get new_admin_role_path
    assert_response :success
    assert_select "h1", "Create New Role"
  end

  test "should create custom role" do
    login_as_admin
    assert_difference("Role.count") do
      post admin_roles_path, params: {
        role: {
          name: "new_custom_role",
          description: "新しいカスタムロール"
        }
      }
    end
    assert_redirected_to admin_role_path(Role.last)
    assert_equal "ロールを作成しました", flash[:success]
    assert_not Role.last.system_role?
  end

  test "should not create role with invalid data" do
    login_as_admin
    assert_no_difference("Role.count") do
      post admin_roles_path, params: {
        role: {
          name: "",
          description: ""
        }
      }
    end
    assert_response :unprocessable_content
  end

  # Edit/Update tests
  test "should get edit for custom role" do
    login_as_admin
    get edit_admin_role_path(@regular_role)
    assert_response :success
    assert_select "h1", "Edit Role"
  end

  test "should update custom role" do
    login_as_admin
    patch admin_role_path(@regular_role), params: {
      role: {
        name: "updated_role",
        description: "更新されたロール"
      }
    }
    assert_redirected_to admin_role_path(@regular_role)
    assert_equal "ロールを更新しました", flash[:success]
    @regular_role.reload
    assert_equal "updated_role", @regular_role.name
  end

  test "should show warning when editing system role" do
    login_as_admin
    get edit_admin_role_path(@admin_role)
    assert_response :success
    assert_equal "システムロールの名前と説明は変更できません", flash[:warning]
  end

  test "should not update system role name and description" do
    login_as_admin
    original_name = @admin_role.name
    original_description = @admin_role.description
    
    patch admin_role_path(@admin_role), params: {
      role: {
        name: "new_name",
        description: "new description"
      }
    }
    
    @admin_role.reload
    assert_equal original_name, @admin_role.name
    assert_equal original_description, @admin_role.description
  end

  # Delete tests
  test "should destroy custom role" do
    # Create a custom role first
    custom_role = Role.create!(name: "deletable_role", description: "削除可能", system_role: false)
    
    login_as_admin
    assert_difference("Role.count", -1) do
      delete admin_role_path(custom_role)
    end
    assert_redirected_to admin_roles_path
    assert_equal "ロールを削除しました", flash[:success]
  end

  test "should not destroy system role" do
    login_as_admin
    assert_no_difference("Role.count") do
      delete admin_role_path(@admin_role)
    end
    assert_redirected_to admin_role_path(@admin_role)
    assert_equal "システムロールは削除できません", flash[:error]
  end

  # Permission tests
  test "should show role with permissions" do
    login_as_admin
    get admin_role_path(@admin_role)
    assert_response :success
    assert_select ".permission-item", minimum: 1
  end

  test "should show role with users" do
    login_as_admin
    get admin_role_path(@admin_role)
    assert_response :success
    assert_select "tbody tr", minimum: 1  # Admin user should be assigned
  end
end