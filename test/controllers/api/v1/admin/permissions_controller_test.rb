require "test_helper"

module Api
  module V1
    module Admin
      class PermissionsControllerTest < ActionDispatch::IntegrationTest
        # index
        test "GET index returns 401 when not logged in" do
          get api_v1_admin_permissions_path
          assert_response :unauthorized
        end

        test "GET index returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          get api_v1_admin_permissions_path
          assert_response :unauthorized
        end

        test "GET index returns 200 with permissions list when logged in as admin" do
          login_as_admin_api
          get api_v1_admin_permissions_path
          assert_response :success
          json = response.parsed_body
          assert json.key?("permissions")
          assert json.key?("meta")
          assert json["permissions"].length.positive?
        end

        test "GET index response includes expected fields" do
          login_as_admin_api
          get api_v1_admin_permissions_path
          assert_response :success
          perm = response.parsed_body["permissions"].first
          assert perm.key?("id")
          assert perm.key?("resource_type")
          assert perm.key?("action")
        end

        # show
        test "GET show returns 401 when not logged in" do
          get api_v1_admin_permission_path(permissions(:user_read))
          assert_response :unauthorized
        end

        test "GET show returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          get api_v1_admin_permission_path(permissions(:user_read))
          assert_response :unauthorized
        end

        test "GET show returns 200 with permission details when logged in as admin" do
          login_as_admin_api
          perm = permissions(:user_read)
          get api_v1_admin_permission_path(perm)
          assert_response :success
          json = response.parsed_body
          assert_equal perm.id, json["id"]
          assert_equal "User", json["resource_type"]
          assert_equal "read", json["action"]
        end

        test "GET show returns 404 for non-existent permission" do
          login_as_admin_api
          get api_v1_admin_permission_path(id: 0)
          assert_response :not_found
        end

        test "GET show response includes roles array" do
          login_as_admin_api
          perm = permissions(:user_read)
          get api_v1_admin_permission_path(perm)
          assert_response :success
          json = response.parsed_body
          assert json.key?("roles"), "レスポンスに roles キーが含まれるべき"
          assert_kind_of Array, json["roles"]
        end

        test "GET show roles array contains role fields" do
          login_as_admin_api
          perm = permissions(:admin_read) # admin, user_manager, user_viewer 等が持つ
          get api_v1_admin_permission_path(perm)
          assert_response :success
          json = response.parsed_body
          assert json["roles"].length.positive?, "admin_read は複数ロールに割り当て済みのはず"
          role = json["roles"].first
          assert role.key?("id")
          assert role.key?("name")
          assert role.key?("system_role")
        end
      end
    end
  end
end
