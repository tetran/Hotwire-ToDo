require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "should redirect to login when not authenticated" do
    get admin_root_path
    assert_redirected_to login_path
  end

  test "should redirect when user has no admin access" do
    login_as(users(:no_role_user))
    get admin_root_path
    assert_admin_access_required
  end

  test "should allow access for admin users" do
    login_as_admin
    get admin_root_path
    assert_response :success
  end

  test "should allow access for user managers" do
    login_as_user_manager
    get admin_root_path
    assert_response :success
    assert_select "h1", "管理者ダッシュボード"
  end

  test "should display statistics" do
    login_as_admin
    get admin_root_path
    assert_response :success

    # Check for stats cards
    assert_select "h3", count: 3
    assert_select "h3", text: /ユーザー数/
    assert_select "h3", text: /プロジェクト数/
    assert_select "h3", text: /タスク数/
  end
end
