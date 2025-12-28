require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get login_path
    assert_response :success
  end

  test "should get create with invalid credentials" do
    post login_path, params: { email: "invalid@example.com", password: "wrong" }
    assert_response :unprocessable_content
  end

  test "should destroy session" do
    login_as(users(:regular_user))
    delete logout_path
    assert_redirected_to login_path
  end

  test "TOTP有効ユーザーのログイン時にチャレンジ画面にリダイレクトされる" do
    user = users(:regular_user)
    user.update_column(:totp_enabled, true)

    post login_path, params: { email: user.email, password: "password" }
    assert_response :redirect
    assert_match %r{/totp/challenge/new\?token=}, response.location
    assert_nil session[:user_id]
  end

  test "TOTP無効ユーザーは通常通りログインできる" do
    user = users(:regular_user)
    user.update_column(:totp_enabled, false)

    post login_path, params: { email: user.email, password: "password" }
    assert_redirected_to project_path(user.inbox_project)
    assert_equal user.id, session[:user_id]
  end
end
