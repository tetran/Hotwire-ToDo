require "test_helper"

# Base behavior tests for Api::V1::Admin namespace using the dashboard endpoint
# which is the root of this namespace
module Api
  module V1
    module Admin
      class BaseTest < ActionDispatch::IntegrationTest
        test "returns 401 when not logged in" do
          get api_v1_admin_root_path
          assert_response :unauthorized
          json = response.parsed_body
          assert_equal "Unauthorized", json["error"]
        end

        test "returns 401 when logged in as regular user via general session" do
          login_as(users(:regular_user))
          get api_v1_admin_root_path
          assert_response :unauthorized
          json = response.parsed_body
          assert_equal "Unauthorized", json["error"]
        end

        test "returns 403 when admin session set to non-admin user" do
          # defense-in-depth: session[:admin_user_id] が何らかの理由で非 admin ユーザー ID を持つ場合
          user = users(:admin_user)
          login_as_admin_api(user)
          user.roles.clear
          get api_v1_admin_root_path
          assert_response :forbidden
          json = response.parsed_body
          assert_equal "Forbidden", json["error"]
        end

        test "returns 200 when logged in as admin user" do
          login_as_admin_api
          get api_v1_admin_root_path
          assert_response :success
        end
      end
    end
  end
end
