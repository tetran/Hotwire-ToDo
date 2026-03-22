require "test_helper"

class AdminControllerTest < ActionDispatch::IntegrationTest
  test "GET /admin redirects to /admin/login when not logged in" do
    get admin_root_path
    assert_redirected_to "/admin/login"
  end

  test "GET /admin/login returns 200 even when not logged in" do
    get "/admin/login"
    assert_response :success
  end

  test "GET /admin/some/path redirects to /admin/login when not logged in" do
    get "/admin/users"
    assert_redirected_to "/admin/login"
  end

  test "GET /admin returns 200 when admin logged in" do
    login_as_admin_api
    get admin_root_path
    assert_response :success
  end

  test "GET /admin/users returns 200 when admin logged in" do
    login_as_admin_api
    get "/admin/users"
    assert_response :success
  end

  test "GET /admin レスポンスに Content-Security-Policy ヘッダーが含まれる" do
    login_as_admin_api
    get admin_root_path
    assert_response :success
    csp = response.headers["Content-Security-Policy"]
    assert csp.present?, "Content-Security-Policy header should be present"
    assert_includes csp, "script-src"
    assert_includes csp, "font-src"
    assert_includes csp, "fonts.gstatic.com"
  end
end
