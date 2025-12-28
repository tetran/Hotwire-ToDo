require "test_helper"

module Totp
  class SettingsControllerTest < ActionDispatch::IntegrationTest
    test "ログイン済みユーザーはTOTP設定画面にアクセスできる" do
      user = users(:regular_user)
      login_as(user)

      get totp_setting_path
      assert_response :success
    end

    test "未ログインユーザーはTOTP設定画面にアクセスできない" do
      get totp_setting_path
      assert_redirected_to login_path
    end

    test "正しい検証コードでTOTPを有効化できる" do
      user = users(:totp_setup_user)
      login_as(user)

      # 時刻を固定してTOTPコードの期限切れを防止
      freeze_time = Time.zone.parse("2025-01-15 12:00:00")
      travel_to(freeze_time) do
        # fixtureのtotp_secretから現在の検証コードを生成
        totp = ROTP::TOTP.new(user.totp_secret, issuer: "Hobo Todo")
        valid_code = totp.at(freeze_time)

        assert_not user.totp_enabled

        post totp_setting_path, params: { code: valid_code }, as: :turbo_stream
        assert_response :success

        user.reload
        assert user.totp_enabled
      end
    end

    test "間違った検証コードでTOTPを有効化できない" do
      user = users(:totp_setup_user_invalid_code)
      login_as(user)

      invalid_code = "000000"

      assert_not user.totp_enabled

      post totp_setting_path, params: { code: invalid_code }
      assert_response :unprocessable_content

      user.reload
      assert_not user.totp_enabled
    end

    test "TOTP設定をリセットできる" do
      user = users(:regular_user)
      login_as(user)

      # まずTOTPを有効化（テスト分離のためupdate_columnを使用）
      user.reload
      user.update_column(:totp_enabled, true)
      old_totp_secret = user.totp_secret

      # リセット
      patch totp_setting_path, as: :turbo_stream
      assert_response :success

      user.reload
      assert_not user.totp_enabled
      assert_not_equal old_totp_secret, user.totp_secret
    end
  end
end
