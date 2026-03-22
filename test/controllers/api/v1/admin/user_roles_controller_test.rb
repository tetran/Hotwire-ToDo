require "test_helper"

module Api
  module V1
    module Admin
      class UserRolesControllerTest < ActionDispatch::IntegrationTest
        # show
        test "GET show returns 401 when not logged in" do
          get api_v1_admin_user_roles_path(users(:regular_user))
          assert_response :unauthorized
        end

        test "GET show returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          get api_v1_admin_user_roles_path(users(:admin_user))
          assert_response :unauthorized
        end

        test "GET show returns 200 with roles when logged in as admin" do
          login_as_admin_api
          target = users(:admin_user)
          get api_v1_admin_user_roles_path(target)
          assert_response :success
          json = response.parsed_body
          assert_kind_of Array, json
          assert_includes json.pluck("name"), "admin"
        end

        test "GET show returns empty array for user with no roles" do
          login_as_admin_api
          get api_v1_admin_user_roles_path(users(:no_role_user))
          assert_response :success
          json = response.parsed_body
          assert_equal [], json
        end

        # update
        test "PATCH update returns 401 when not logged in" do
          patch api_v1_admin_user_roles_path(users(:regular_user)), params: { role_ids: [] }
          assert_response :unauthorized
        end

        test "PATCH update returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          patch api_v1_admin_user_roles_path(users(:regular_user)), params: { role_ids: [] }
          assert_response :unauthorized
        end

        test "PATCH update syncs roles when logged in as admin" do
          login_as_admin_api
          target = users(:no_role_user)
          role = roles(:regular)
          patch api_v1_admin_user_roles_path(target), params: { role_ids: [role.id] }
          assert_response :success
          json = response.parsed_body
          assert_includes json.pluck("id"), role.id
        end

        test "PATCH update removes all roles when given empty array" do
          login_as_admin_api
          target = users(:regular_user)
          patch api_v1_admin_user_roles_path(target), params: { role_ids: [] }
          assert_response :success
          json = response.parsed_body
          assert_equal [], json
        end

        # 操作別認可テスト
        test "PATCH update returns 403 when logged in as read-only admin" do
          login_as_admin_api_read_only
          patch api_v1_admin_user_roles_path(users(:no_role_user)), params: { role_ids: [] }
          assert_response :forbidden
        end

        # system role 付与防止テスト
        test "PATCH update returns 403 when attempting to assign a system role" do
          login_as_admin_api
          patch api_v1_admin_user_roles_path(users(:no_role_user)), params: { role_ids: [roles(:admin).id] }
          assert_response :forbidden
        end

        test "PATCH update returns 403 when attempting to assign user_manager system role" do
          login_as_admin_api
          patch api_v1_admin_user_roles_path(users(:no_role_user)),
                params: { role_ids: [roles(:user_manager).id] }
          assert_response :forbidden
        end

        test "PATCH update succeeds when assigning only non-system roles" do
          login_as_admin_api
          patch api_v1_admin_user_roles_path(users(:no_role_user)), params: { role_ids: [roles(:regular).id] }
          assert_response :success
          assert_includes response.parsed_body.pluck("id"), roles(:regular).id
        end

        # system role 剥奪防止テスト
        test "PATCH update returns 403 when removing system role from user" do
          login_as_admin_api
          target = users(:admin_user) # admin system role を持つ
          patch api_v1_admin_user_roles_path(target), params: { role_ids: [] }
          assert_response :forbidden
        end

        test "PATCH update returns 403 when partially removing system roles from user" do
          login_as_admin_api
          target = users(:admin_user) # admin system role を持つ
          patch api_v1_admin_user_roles_path(target), params: { role_ids: [roles(:regular).id] }
          assert_response :forbidden
        end

        # 権限昇格防止テスト
        test "PATCH update returns 403 when privilege escalation is attempted" do
          login_as_admin_api(users(:user_manager))
          # user_manager は llm_provider_read を持っていないため、そのロールを割当てようとすると 403
          dangerous_role = Role.create!(name: "dangerous_test_role", description: "test")
          dangerous_role.permissions << permissions(:llm_provider_read)
          patch api_v1_admin_user_roles_path(users(:no_role_user)),
                params: { role_ids: [dangerous_role.id] }
          assert_response :forbidden
        end

        # User:read チェックテスト
        test "GET show returns 403 when logged in as user without User:read permission" do
          login_as_llm_admin_api # LlmProvider 権限のみ（User:read なし）
          get api_v1_admin_user_roles_path(users(:no_role_user))
          assert_response :forbidden
        end

        test "GET show returns 200 when logged in as user_manager (has User:read)" do
          login_as_admin_api(users(:user_manager))
          get api_v1_admin_user_roles_path(users(:no_role_user))
          assert_response :success
        end
      end
    end
  end
end
