require "test_helper"

module Api
  module V1
    module Admin
      class RolePermissionsControllerTest < ActionDispatch::IntegrationTest
        # show
        test "GET show returns 401 when not logged in" do
          get api_v1_admin_role_permissions_path(roles(:admin))
          assert_response :unauthorized
        end

        test "GET show returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          get api_v1_admin_role_permissions_path(roles(:admin))
          assert_response :unauthorized
        end

        test "GET show returns 200 with permissions when logged in as admin" do
          login_as_admin_api
          role = roles(:admin)
          get api_v1_admin_role_permissions_path(role)
          assert_response :success
          json = response.parsed_body
          assert_kind_of Array, json
          assert json.length.positive?
        end

        test "GET show returns empty array for role with no permissions" do
          login_as_admin_api
          role = roles(:regular)
          get api_v1_admin_role_permissions_path(role)
          assert_response :success
          json = response.parsed_body
          assert_equal [], json
        end

        test "GET show response includes expected permission fields" do
          login_as_admin_api
          get api_v1_admin_role_permissions_path(roles(:admin))
          assert_response :success
          perm = response.parsed_body.first
          assert perm.key?("id")
          assert perm.key?("resource_type")
          assert perm.key?("action")
        end

        # update
        test "PATCH update returns 401 when not logged in" do
          patch api_v1_admin_role_permissions_path(roles(:regular)), params: { permission_ids: [] }
          assert_response :unauthorized
        end

        test "PATCH update returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          patch api_v1_admin_role_permissions_path(roles(:regular)), params: { permission_ids: [] }
          assert_response :unauthorized
        end

        test "PATCH update syncs permissions when logged in as admin" do
          login_as_admin_api
          role = roles(:regular)
          perm = permissions(:user_read)
          patch api_v1_admin_role_permissions_path(role), params: { permission_ids: [perm.id] }
          assert_response :success
          json = response.parsed_body
          assert_includes json.pluck("id"), perm.id
        end

        test "PATCH update removes all permissions when given empty array" do
          login_as_admin_api
          role = roles(:regular)
          patch api_v1_admin_role_permissions_path(role), params: { permission_ids: [] }
          assert_response :success
          json = response.parsed_body
          assert_equal [], json
        end

        # 操作別認可テスト
        test "PATCH update returns 403 when logged in as read-only admin" do
          login_as_admin_api_read_only
          patch api_v1_admin_role_permissions_path(roles(:regular)), params: { permission_ids: [] }
          assert_response :forbidden
        end

        test "PATCH update returns 403 for non-system role when logged in as user_manager" do
          login_as_admin_api(users(:user_manager))
          patch api_v1_admin_role_permissions_path(roles(:regular)), params: { permission_ids: [] }
          assert_response :forbidden
        end

        test "PATCH update returns 403 when logged in as llm_admin" do
          login_as_admin_api(users(:llm_admin_user))
          patch api_v1_admin_role_permissions_path(roles(:regular)), params: { permission_ids: [] }
          assert_response :forbidden
        end

        # system role 保護テスト
        test "PATCH update returns 403 when trying to modify permissions of a system role" do
          login_as_admin_api
          patch api_v1_admin_role_permissions_path(roles(:admin)), params: { permission_ids: [] }
          assert_response :forbidden
        end

        test "PATCH update returns 403 when trying to modify user_manager system role permissions" do
          login_as_admin_api
          patch api_v1_admin_role_permissions_path(roles(:user_manager)), params: { permission_ids: [] }
          assert_response :forbidden
        end
      end
    end
  end
end
