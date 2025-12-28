require "test_helper"

class LoginHelperTest < ActionDispatch::IntegrationTest
  test "bypass_totp: false でTOTP無効ユーザーがログインできる" do
    user = users(:regular_user)
    user.update_column(:totp_enabled, false)

    login_as(user, bypass_totp: false)

    # セッションが正しく設定されているか確認
    assert_equal user.id, session[:user_id], "Session should be set for non-TOTP user"

    # 認証が必要なページにアクセスできるか確認
    get totp_setting_path
    assert_response :success, "Should be able to access authenticated pages"
  end

  test "bypass_totp: true でTOTP有効ユーザーがログインできる" do
    user = users(:regular_user)
    user.update_column(:totp_enabled, true)

    login_as(user, bypass_totp: true)

    # セッションが正しく設定されているか確認
    assert_equal user.id, session[:user_id], "Session should be set even with TOTP enabled"

    # 認証が必要なページにアクセスできるか確認
    get totp_setting_path
    assert_response :success, "Should be able to access authenticated pages with bypass_totp"
  end

  test "bypass_totp: false でTOTP有効ユーザーはチャレンジにリダイレクトされる" do
    user = users(:regular_user)
    user.update_column(:totp_enabled, true)

    login_as(user, bypass_totp: false)

    # TOTPチャレンジにリダイレクトされるため、セッションは設定されない
    assert_nil session[:user_id], "Session should not be set when TOTP challenge is required"

    # 認証が必要なページにアクセスするとログイン画面にリダイレクトされる
    get totp_setting_path
    assert_redirected_to login_path, "Should redirect to login when not authenticated"
  end
end
