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
  end
end
