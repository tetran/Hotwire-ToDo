require "test_helper"

module Account
  class DeactivationsControllerTest < ActionDispatch::IntegrationTest
    test "GET new requires login" do
      get new_account_deactivation_path
      assert_redirected_to login_path
    end

    test "GET new renders the form for logged-in users" do
      login_as(users(:regular_user))
      get new_account_deactivation_path
      assert_response :success
    end

    test "POST create with the correct password deactivates the user, resets session, and redirects to login" do
      user = users(:regular_user)
      original_email = user.email
      login_as(user)

      assert_difference("DeactivatedUser.count", 1) do
        post account_deactivation_path, params: {
          user: { password_challenge: TEST_PASSWORD, reason: "Self-deactivated for test" },
          confirm_deactivation: "1",
        }
      end

      assert_redirected_to login_path
      assert_nil session[:user_id]

      user.reload
      assert user.deactivated?
      assert_equal original_email, user.deactivation.original_email
      assert_equal "Self-deactivated for test", user.deactivation.reason
      assert_equal user.id, user.deactivation.deactivated_by_id, "self-deactivation records the user as performer"
    end

    test "POST create with wrong password re-renders new with 422 and does not deactivate" do
      user = users(:regular_user)
      login_as(user)

      assert_no_difference("DeactivatedUser.count") do
        post account_deactivation_path, params: {
          user: { password_challenge: "wrong-password", reason: "" },
          confirm_deactivation: "1",
        }
      end

      assert_response :unprocessable_content
      assert_not_nil session[:user_id], "session is preserved when validation fails"
    end

    test "POST create requires login" do
      assert_no_difference("DeactivatedUser.count") do
        post account_deactivation_path, params: { user: { password_challenge: "x", reason: "" } }
      end
      assert_redirected_to login_path
    end

    test "POST create with malformed params (missing user key) returns 400 not 500" do
      login_as(users(:regular_user))
      assert_no_difference("DeactivatedUser.count") do
        post account_deactivation_path, params: {}
      end
      assert_response :bad_request
    end

    # Admin self-deactivation lockout guard (Plan §13: Admin 自己 Deactivate ブロック)
    test "GET new is blocked for admin-capable users (prevents admin panel lockout)" do
      login_as(users(:admin_user))
      get new_account_deactivation_path
      assert_redirected_to user_path
      follow_redirect!
      assert_match I18n.t("controllers.account/deactivations.admin_blocked"), flash[:alert].to_s
    end

    test "POST create is blocked for admin-capable users" do
      login_as(users(:admin_user))
      assert_no_difference("DeactivatedUser.count") do
        post account_deactivation_path, params: {
          user: { password_challenge: TEST_PASSWORD, reason: "" },
        }
      end
      assert_redirected_to user_path
    end

    test "POST create is blocked for user_manager (User:write capable, also locks panel)" do
      login_as(users(:user_manager))
      assert_no_difference("DeactivatedUser.count") do
        post account_deactivation_path, params: {
          user: { password_challenge: TEST_PASSWORD, reason: "" },
        }
      end
      assert_redirected_to user_path
    end

    # Race / double-submit: service raises RecordNotUnique → recoverable form error (not 500)
    test "POST create renders form with 422 when DeactivationService raises RecordNotUnique" do
      user = users(:regular_user)
      login_as(user)

      Account::DeactivationService.expects(:call).raises(ActiveRecord::RecordNotUnique.new("uniq"))

      assert_no_difference("DeactivatedUser.count") do
        post account_deactivation_path, params: {
          user: { password_challenge: TEST_PASSWORD, reason: "" },
          confirm_deactivation: "1",
        }
      end
      assert_response :unprocessable_content
      assert_not_nil session[:user_id], "session must remain live for recovery"
    end

    test "POST create renders form with 422 when DeactivationService raises RecordInvalid" do
      user = users(:regular_user)
      login_as(user)

      record = User.new
      record.errors.add(:base, "Some validation failure")
      Account::DeactivationService.expects(:call).raises(ActiveRecord::RecordInvalid.new(record))

      assert_no_difference("DeactivatedUser.count") do
        post account_deactivation_path, params: {
          user: { password_challenge: TEST_PASSWORD, reason: "" },
          confirm_deactivation: "1",
        }
      end
      assert_response :unprocessable_content
    end

    # Server-side confirm_deactivation guard: prevents bypass via direct POST
    test "POST create without confirm_deactivation is rejected with 422 (defense-in-depth)" do
      user = users(:regular_user)
      login_as(user)

      Account::DeactivationService.expects(:call).never
      assert_no_difference("DeactivatedUser.count") do
        post account_deactivation_path, params: {
          user: { password_challenge: TEST_PASSWORD, reason: "" },
        }
      end
      assert_response :unprocessable_content
      assert_not_nil session[:user_id]
    end
  end
end
