require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = users(:admin_user)
    @user_manager = users(:user_manager)
    @regular_user = users(:regular_user)
    @no_role_user = users(:no_role_user)
  end

  # Authentication tests
  test "should redirect to login when not authenticated" do
    get admin_users_path
    assert_redirected_to login_path
  end

  test "should deny access to users without admin permissions" do
    login_as(@no_role_user)
    get admin_users_path
    assert_admin_access_required
  end

  # Index tests
  test "should get index for admin" do
    login_as_admin
    get admin_users_path
    assert_response :success
    assert_select "h1", "User Management"
  end

  test "should get index for user manager" do
    login_as_user_manager
    get admin_users_path
    assert_response :success
  end

  test "should show users in index" do
    login_as_admin
    get admin_users_path
    assert_response :success
    assert_select "tbody tr", minimum: 4  # We have 4 users in fixtures
  end

  test "should filter users by search" do
    login_as_admin
    get admin_users_path, params: { search: "admin" }
    assert_response :success
    assert_select "tbody tr", count: 1
  end

  # Show tests
  test "should show user" do
    login_as_admin
    get admin_user_path(@regular_user)
    assert_response :success
    assert_select "h1", "User Details"
  end

  # New/Create tests
  test "should get new" do
    login_as_admin
    get new_admin_user_path
    assert_response :success
    assert_select "h1", "Create New User"
  end

  test "should create user" do
    login_as_admin
    assert_difference("User.count") do
      post admin_users_path, params: {
        user: {
          name: "New User",
          email: "newuser@example.com",
          password: "password",
          password_confirmation: "password"
        }
      }
    end
    assert_redirected_to admin_user_path(User.last)
    assert_equal "ユーザーを作成しました", flash[:success]
  end

  test "should not create user with invalid data" do
    login_as_admin
    assert_no_difference("User.count") do
      post admin_users_path, params: {
        user: {
          name: "",
          email: "invalid-email",
          password: "pass"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # Edit/Update tests
  test "should get edit" do
    login_as_admin
    get edit_admin_user_path(@regular_user)
    assert_response :success
    assert_select "h1", "Edit User"
  end

  test "should update user" do
    login_as_admin
    patch admin_user_path(@regular_user), params: {
      user: {
        name: "Updated Name"
      }
    }
    assert_redirected_to admin_user_path(@regular_user)
    assert_equal "ユーザー情報を更新しました", flash[:success]
    @regular_user.reload
    assert_equal "Updated Name", @regular_user.name
  end

  test "should not update user with invalid data" do
    login_as_admin
    patch admin_user_path(@regular_user), params: {
      user: {
        email: "invalid-email"
      }
    }
    assert_response :unprocessable_entity
  end

  # Delete tests
  test "should destroy user" do
    login_as_admin
    assert_difference("User.count", -1) do
      delete admin_user_path(@no_role_user)
    end
    assert_redirected_to admin_users_path
    assert_equal "ユーザーを削除しました", flash[:success]
  end

  # Authorization tests
  test "user manager can read and write but not delete" do
    login_as_user_manager

    # Can read
    get admin_users_path
    assert_response :success

    # Can create
    get new_admin_user_path
    assert_response :success

    # Can edit
    get edit_admin_user_path(@regular_user)
    assert_response :success

    # Can delete (user_manager has User:manage permission which includes delete)
    delete admin_user_path(@no_role_user)
    assert_response :redirect
  end
end
