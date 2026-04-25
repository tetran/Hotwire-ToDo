require "test_helper"

class ApplicationControllerEnforceActiveAccountTest < ActionDispatch::IntegrationTest
  test "deactivated user is logged out and redirected to login on next authed request" do
    user = users(:regular_user)
    login_as(user)
    assert_equal user.id, session[:user_id]

    Account::DeactivationService.call(user: user, performer: user)

    get project_path(user.inbox_project)
    assert_redirected_to login_path
    assert_nil session[:user_id]

    follow_redirect!
    expected_alert = I18n.t("controllers.sessions.account_unavailable")
    assert_match expected_alert, flash[:alert].to_s
  end

  test "active users are not affected by enforce_active_account" do
    user = users(:regular_user)
    login_as(user)

    get project_path(user.inbox_project)
    assert_response :success
    assert_equal user.id, session[:user_id]
  end
end
