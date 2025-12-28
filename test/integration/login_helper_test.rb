require "test_helper"

class LoginHelperTest < ActionDispatch::IntegrationTest
  test "bypass_totp: false で通常ログインできる" do
    user = users(:totp_disabled_user)

    login_as(user, bypass_totp: false)

    assert_equal user.id, session[:user_id], "Session should be set for non-TOTP user"
    assert_response :success
  end

  test "bypass_totp: true でTOTP有効ユーザーがログインできる" do
    user = users(:totp_enabled_user)

    # TOTP有効ユーザーでもbypass_totpでログインできる
    login_as(user, bypass_totp: true)

    assert_equal user.id, session[:user_id], "Session should be set even for TOTP user when bypassing"
    assert_response :success

    # TOTP状態が復元されていることを確認
    user.reload
    assert user.totp_enabled, "TOTP should remain enabled after login"
  end

  test "bypass_totp: false でTOTP有効ユーザーはチャレンジにリダイレクト" do
    user = users(:totp_enabled_user)

    login_as(user, bypass_totp: false)

    # TOTP有効ユーザーは通常ログインでチャレンジにリダイレクトされる
    assert_nil session[:user_id], "Session should not be set for TOTP user without bypass"
    assert_response :success
    assert_match /totp\/challenge/, response.body
  end
end
