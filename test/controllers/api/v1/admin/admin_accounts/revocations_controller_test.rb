require "test_helper"

module Api
  module V1
    module Admin
      module AdminAccounts
        class RevocationsControllerTest < ActionDispatch::IntegrationTest
          test "POST create returns 401 when not logged in" do
            post api_v1_admin_admin_account_revocation_path(users(:llm_admin_user))
            assert_response :unauthorized
          end

          test "POST create returns 401 when logged in as regular user" do
            login_as(users(:regular_user))
            post api_v1_admin_admin_account_revocation_path(users(:llm_admin_user))
            assert_response :unauthorized
          end

          test "POST create returns 403 when logged in as read-only admin" do
            login_as_admin_api_read_only
            post api_v1_admin_admin_account_revocation_path(users(:llm_admin_user))
            assert_response :forbidden
          end

          test "POST create revokes admin access and removes admin roles" do
            login_as_admin_api
            target = users(:user_viewer)
            assert User.admin_accounts.exists?(id: target.id)

            post api_v1_admin_admin_account_revocation_path(target)
            assert_response :no_content

            # Should no longer be an admin account
            assert_not User.admin_accounts.exists?(id: target.id)
            # User should still exist
            assert User.exists?(id: target.id)
          end

          test "POST create returns 403 when trying to revoke own admin access" do
            login_as_admin_api
            post api_v1_admin_admin_account_revocation_path(users(:admin_user))
            assert_response :forbidden
            assert_equal "Cannot revoke your own admin access",
                         response.parsed_body["error"]
          end

          test "POST create returns 404 for non-admin user" do
            login_as_admin_api
            post api_v1_admin_admin_account_revocation_path(users(:no_role_user))
            assert_response :not_found
          end

          test "POST create moves user from admin_accounts to non_admin_accounts" do
            login_as_admin_api
            target = users(:user_viewer)
            assert User.admin_accounts.exists?(id: target.id)
            assert_not User.non_admin_accounts.exists?(id: target.id)

            post api_v1_admin_admin_account_revocation_path(target)
            assert_response :no_content

            assert_not User.admin_accounts.exists?(id: target.id)
            assert User.non_admin_accounts.exists?(id: target.id)
          end

          test "POST create returns 403 when target has higher privileges" do
            # user_manager cannot revoke admin_user (who has more permissions)
            login_as_admin_api(users(:user_manager))
            post api_v1_admin_admin_account_revocation_path(users(:admin_user))
            assert_response :forbidden
          end
        end
      end
    end
  end
end
