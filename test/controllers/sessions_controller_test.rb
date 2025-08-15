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
end
