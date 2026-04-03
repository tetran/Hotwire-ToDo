require "test_helper"

module Api
  module V1
    module Admin
      module AdminAccounts
        class RolesControllerTest < ActionDispatch::IntegrationTest
          # show
          test "GET show returns 401 when not logged in" do
            get api_v1_admin_admin_account_roles_path(users(:user_manager))
            assert_response :unauthorized
          end

          test "GET show returns 401 when logged in as regular user" do
            login_as(users(:regular_user))
            get api_v1_admin_admin_account_roles_path(users(:user_manager))
            assert_response :unauthorized
          end

          test "GET show returns 403 when admin lacks User:read" do
            login_as_llm_admin_api
            get api_v1_admin_admin_account_roles_path(users(:user_manager))
            assert_response :forbidden
          end

          test "GET show returns 200 with roles list" do
            login_as_admin_api
            target = users(:user_manager)
            get api_v1_admin_admin_account_roles_path(target)
            assert_response :success
            json = response.parsed_body
            assert_kind_of Array, json
            assert_equal 1, json.size
            role = json.first
            assert_equal roles(:user_manager).id, role["id"]
            assert_equal "user_manager", role["name"]
            assert role.key?("description")
            assert role.key?("system_role")
          end

          test "GET show returns 404 for non-admin user" do
            login_as_admin_api
            get api_v1_admin_admin_account_roles_path(users(:regular_user))
            assert_response :not_found
          end

          test "GET show returns 404 for non-existent user" do
            login_as_admin_api
            get api_v1_admin_admin_account_roles_path(admin_account_id: 0)
            assert_response :not_found
          end

          # update
          test "PATCH update returns 401 when not logged in" do
            patch api_v1_admin_admin_account_roles_path(users(:user_manager)),
                  params: { role_ids: [roles(:user_viewer).id] }
            assert_response :unauthorized
          end

          test "PATCH update returns 401 when logged in as regular user" do
            login_as(users(:regular_user))
            patch api_v1_admin_admin_account_roles_path(users(:user_manager)),
                  params: { role_ids: [roles(:user_viewer).id] }
            assert_response :unauthorized
          end

          test "PATCH update returns 403 when admin lacks User:write" do
            login_as_admin_api_read_only
            patch api_v1_admin_admin_account_roles_path(users(:user_manager)),
                  params: { role_ids: [roles(:user_viewer).id] }
            assert_response :forbidden
          end

          test "PATCH update returns 403 when trying to change own roles" do
            login_as_admin_api
            patch api_v1_admin_admin_account_roles_path(users(:admin_user)),
                  params: { role_ids: [roles(:admin).id] }
            assert_response :forbidden
            assert_equal "Cannot change your own roles", response.parsed_body["error"]
          end

          test "PATCH update returns 403 on privilege escalation" do
            # user_manager does not have LlmProvider permissions
            login_as_admin_api(users(:user_manager))
            patch api_v1_admin_admin_account_roles_path(users(:user_viewer)),
                  params: { role_ids: [roles(:llm_admin).id] }
            assert_response :forbidden
          end

          test "PATCH update returns 422 when role_ids is empty" do
            login_as_admin_api
            patch api_v1_admin_admin_account_roles_path(users(:user_manager)),
                  params: { role_ids: [] }
            assert_response :unprocessable_entity
            assert_equal "At least one role is required", response.parsed_body["error"]
          end

          test "PATCH update returns 422 when no role has admin access" do
            login_as_admin_api
            patch api_v1_admin_admin_account_roles_path(users(:user_manager)),
                  params: { role_ids: [roles(:regular).id] }
            assert_response :unprocessable_entity
            assert_equal "At least one role with admin access is required",
                         response.parsed_body["error"]
          end

          test "PATCH update returns 422 when role does not exist" do
            login_as_admin_api
            patch api_v1_admin_admin_account_roles_path(users(:user_manager)),
                  params: { role_ids: [0] }
            assert_response :unprocessable_entity
            assert_equal "Some roles were not found", response.parsed_body["error"]
          end

          test "PATCH update returns 404 for non-admin user" do
            login_as_admin_api
            patch api_v1_admin_admin_account_roles_path(users(:regular_user)),
                  params: { role_ids: [roles(:user_viewer).id] }
            assert_response :not_found
          end

          test "PATCH update successfully changes roles" do
            login_as_admin_api
            target = users(:user_viewer)
            new_role = roles(:user_manager)

            patch api_v1_admin_admin_account_roles_path(target),
                  params: { role_ids: [new_role.id] }
            assert_response :success
            json = response.parsed_body
            assert_kind_of Array, json
            assert_equal 1, json.size
            assert_equal new_role.id, json.first["id"]

            # Verify persisted
            target.reload
            assert_equal [new_role.id], target.role_ids
          end

          test "PATCH update allows assigning system roles" do
            login_as_admin_api
            target = users(:user_viewer)

            patch api_v1_admin_admin_account_roles_path(target),
                  params: { role_ids: [roles(:user_manager).id] }
            assert_response :success
            assert_equal "user_manager", response.parsed_body.first["name"]
          end

          test "PATCH update allows changing between system roles" do
            login_as_admin_api
            target = users(:user_viewer)

            # Change from user_viewer to user_manager (both system roles)
            patch api_v1_admin_admin_account_roles_path(target),
                  params: { role_ids: [roles(:user_manager).id] }
            assert_response :success

            target.reload
            assert_includes target.roles.pluck(:name), "user_manager"
            assert_not_includes target.roles.pluck(:name), "user_viewer"
          end

          test "PATCH update preserves admin account status" do
            login_as_admin_api
            target = users(:user_viewer)

            patch api_v1_admin_admin_account_roles_path(target),
                  params: { role_ids: [roles(:user_manager).id] }
            assert_response :success

            assert User.admin_accounts.exists?(id: target.id)
          end
        end
      end
    end
  end
end
