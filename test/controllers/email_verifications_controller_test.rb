require "test_helper"

class EmailVerificationsControllerTest < ActionDispatch::IntegrationTest
  test "有効なトークンでメール確認ができる" do
    user = users(:regular_user)
    user.update_column(:verified, false)

    token = user.generate_token_for(:email_verification)

    assert_not user.verified

    get email_verification_path(token)
    assert_redirected_to root_path

    user.reload
    assert user.verified
  end

  test "無効なトークンでメール確認ができない" do
    invalid_token = "invalid_token"

    get email_verification_path(invalid_token)
    assert_redirected_to root_path
  end

  test "ログイン済みユーザーが確認メールを送信できる" do
    user = users(:regular_user)
    user.update_column(:verified, false)
    login_as(user)

    assert_emails 1 do
      post email_verifications_path, as: :turbo_stream
    end
    assert_response :success
  end
end
