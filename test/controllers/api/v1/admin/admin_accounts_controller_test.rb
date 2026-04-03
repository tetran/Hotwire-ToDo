require "test_helper"

module Api
  module V1
    module Admin
      class AdminAccountsControllerTest < ActionDispatch::IntegrationTest
        # index
        test "GET index returns 401 when not logged in" do
          get api_v1_admin_admin_accounts_path
          assert_response :unauthorized
        end

        test "GET index returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          get api_v1_admin_admin_accounts_path
          assert_response :unauthorized
        end

        # Admin:read is also the admin session gate (require_admin_access).
        # A user without Admin:read cannot establish an admin session,
        # so they receive 401 (covered above), not 403.
        # This differs from endpoints like UsersController where the base gate
        # (Admin:read) and the action capability (User:read) are different.

        test "GET index returns 200 when logged in as admin" do
          login_as_admin_api
          get api_v1_admin_admin_accounts_path
          assert_response :success
          json = response.parsed_body
          assert_kind_of Array, json
        end

        test "GET index only returns users with admin permissions" do
          login_as_admin_api
          get api_v1_admin_admin_accounts_path
          assert_response :success
          json = response.parsed_body
          emails = json.pluck("email")

          # Admin accounts (have roles with Admin:read)
          assert_includes emails, users(:admin_user).email
          assert_includes emails, users(:user_manager).email
          assert_includes emails, users(:user_viewer).email
          assert_includes emails, users(:llm_admin_user).email

          # Non-admin accounts should NOT be included
          assert_not_includes emails, users(:regular_user).email
          assert_not_includes emails, users(:no_role_user).email
        end

        test "GET index response includes roles for each admin account" do
          login_as_admin_api
          get api_v1_admin_admin_accounts_path
          assert_response :success
          admin_account = response.parsed_body.first
          assert admin_account.key?("roles")
          assert_kind_of Array, admin_account["roles"]
          role = admin_account["roles"].first
          assert role.key?("id")
          assert role.key?("name")
        end

        test "GET index response includes expected fields" do
          login_as_admin_api
          get api_v1_admin_admin_accounts_path
          assert_response :success
          admin_account = response.parsed_body.first
          assert admin_account.key?("id")
          assert admin_account.key?("email")
          assert admin_account.key?("name")
          assert admin_account.key?("created_at")
          assert admin_account.key?("updated_at")
          assert_not admin_account.key?("password_digest")
        end

        test "GET index with q param searches within admin accounts" do
          login_as_admin_api
          get api_v1_admin_admin_accounts_path, params: { q: "Admin User" }
          assert_response :success
          json = response.parsed_body
          assert json.any? { |u| u["email"] == users(:admin_user).email }
          assert json.none? { |u| u["email"] == users(:regular_user).email }
        end

        test "GET index with q param does not return non-admin users matching query" do
          login_as_admin_api
          get api_v1_admin_admin_accounts_path, params: { q: "norole" }
          assert_response :success
          json = response.parsed_body
          assert_empty json
        end

        # destroy
        test "DELETE destroy returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          delete api_v1_admin_admin_account_path(users(:llm_admin_user))
          assert_response :unauthorized
        end

        test "DELETE destroy returns 401 when not logged in" do
          delete api_v1_admin_admin_account_path(users(:user_viewer))
          assert_response :unauthorized
        end

        test "DELETE destroy returns 403 when logged in as read-only admin" do
          login_as_admin_api_read_only
          delete api_v1_admin_admin_account_path(users(:llm_admin_user))
          assert_response :forbidden
        end

        test "DELETE destroy deletes admin account" do
          login_as_admin_api
          target = users(:llm_admin_user)
          assert_difference "User.count", -1 do
            delete api_v1_admin_admin_account_path(target)
          end
          assert_response :no_content
        end

        test "DELETE destroy returns 403 when trying to delete self" do
          login_as_admin_api
          delete api_v1_admin_admin_account_path(users(:admin_user))
          assert_response :forbidden
          assert_equal "Cannot delete yourself", response.parsed_body["error"]
        end

        test "DELETE destroy returns 404 for non-admin user" do
          login_as_admin_api
          delete api_v1_admin_admin_account_path(users(:no_role_user))
          assert_response :not_found
        end

        test "DELETE destroy returns 404 for non-existent user" do
          login_as_admin_api
          delete api_v1_admin_admin_account_path(id: 0)
          assert_response :not_found
        end
      end
    end
  end
end
