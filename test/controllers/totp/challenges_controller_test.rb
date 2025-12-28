require "test_helper"

module Totp
  class ChallengesControllerTest < ActionDispatch::IntegrationTest
    test "有効なトークンでチャレンジ画面を表示できる" do
      user = users(:totp_enabled_user)
      token = user.generate_token_for(:totp_verification)

      get new_totp_challenge_path(token: token)
      assert_response :success
    end

    test "正しい検証コードでログインできる" do
      user = users(:totp_enabled_user)
      token = user.generate_token_for(:totp_verification)

      # 時刻を固定してTOTPコードの期限切れを防止
      freeze_time = Time.zone.parse("2025-01-15 12:00:00")
      travel_to(freeze_time) do
        totp = ROTP::TOTP.new(user.totp_secret, issuer: "Hobo Todo")
        valid_code = totp.at(freeze_time)

        post totp_challenge_path, params: { token: token, code: valid_code }
        assert_redirected_to project_path(user.inbox_project)
        assert_equal user.id, session[:user_id]
      end
    end

    test "間違った検証コードでログインできない" do
      user = users(:totp_enabled_user)
      token = user.generate_token_for(:totp_verification)

      invalid_code = "000000"

      post totp_challenge_path, params: { token: token, code: invalid_code }
      assert_response :unprocessable_content
      assert_nil session[:user_id]
    end

    test "無効なトークンでエラーになる" do
      invalid_token = "invalid_token"

      post totp_challenge_path, params: { token: invalid_token, code: "123456" }
      assert_redirected_to root_path
      assert_nil session[:user_id]
    end
  end
end
