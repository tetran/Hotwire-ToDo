require "test_helper"

module Api
  module V1
    module Admin
      class RolesControllerTest < ActionDispatch::IntegrationTest
        # index
        test "GET index returns 401 when not logged in" do
          get api_v1_admin_roles_path
          assert_response :unauthorized
        end

        test "GET index returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          get api_v1_admin_roles_path
          assert_response :unauthorized
        end

        test "GET index returns 200 with roles list when logged in as admin" do
          login_as_admin_api
          get api_v1_admin_roles_path
          assert_response :success
          json = response.parsed_body
          assert_kind_of Array, json
          names = json.pluck("name")
          assert_includes names, "admin"
        end

        test "GET index response includes expected fields" do
          login_as_admin_api
          get api_v1_admin_roles_path
          assert_response :success
          role = response.parsed_body.first
          assert role.key?("id")
          assert role.key?("name")
          assert role.key?("description")
          assert role.key?("system_role")
        end

        # show
        test "GET show returns 401 when not logged in" do
          get api_v1_admin_role_path(roles(:admin))
          assert_response :unauthorized
        end

        test "GET show returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          get api_v1_admin_role_path(roles(:admin))
          assert_response :unauthorized
        end

        test "GET show returns 200 with role details when logged in as admin" do
          login_as_admin_api
          role = roles(:admin)
          get api_v1_admin_role_path(role)
          assert_response :success
          json = response.parsed_body
          assert_equal role.id, json["id"]
          assert_equal "admin", json["name"]
        end

        test "GET show returns 404 for non-existent role" do
          login_as_admin_api
          get api_v1_admin_role_path(id: 0)
          assert_response :not_found
        end

        # create
        test "POST create returns 401 when not logged in" do
          post api_v1_admin_roles_path, params: { role: { name: "new_role", description: "A new role" } }
          assert_response :unauthorized
        end

        test "POST create returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          post api_v1_admin_roles_path, params: { role: { name: "new_role", description: "A new role" } }
          assert_response :unauthorized
        end

        test "POST create creates a new role when logged in as admin" do
          login_as_admin_api
          assert_difference "Role.count", 1 do
            post api_v1_admin_roles_path, params: { role: { name: "new_role", description: "A new role" } }
          end
          assert_response :created
          json = response.parsed_body
          assert_equal "new_role", json["name"]
        end

        test "POST create returns 422 with validation errors on invalid params" do
          login_as_admin_api
          post api_v1_admin_roles_path, params: { role: { name: "" } }
          assert_response :unprocessable_entity
          assert response.parsed_body.key?("errors")
        end

        # update
        test "PATCH update returns 401 when not logged in" do
          patch api_v1_admin_role_path(roles(:regular)), params: { role: { description: "Updated" } }
          assert_response :unauthorized
        end

        test "PATCH update returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          patch api_v1_admin_role_path(roles(:regular)), params: { role: { description: "Updated" } }
          assert_response :unauthorized
        end

        test "PATCH update updates role when logged in as admin" do
          login_as_admin_api
          role = roles(:regular)
          patch api_v1_admin_role_path(role), params: { role: { description: "Updated description" } }
          assert_response :success
          json = response.parsed_body
          assert_equal "Updated description", json["description"]
        end

        test "PATCH update returns 422 on invalid params" do
          login_as_admin_api
          patch api_v1_admin_role_path(roles(:regular)), params: { role: { name: "" } }
          assert_response :unprocessable_entity
          assert response.parsed_body.key?("errors")
        end

        # destroy
        test "DELETE destroy returns 401 when not logged in" do
          delete api_v1_admin_role_path(roles(:regular))
          assert_response :unauthorized
        end

        test "DELETE destroy returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          delete api_v1_admin_role_path(roles(:regular))
          assert_response :unauthorized
        end

        test "DELETE destroy deletes a role when logged in as admin" do
          login_as_admin_api
          role = roles(:regular)
          assert_difference "Role.count", -1 do
            delete api_v1_admin_role_path(role)
          end
          assert_response :no_content
        end

        # 操作別認可テスト
        test "POST create returns 403 when logged in as read-only admin" do
          login_as_admin_api_read_only
          post api_v1_admin_roles_path, params: { role: { name: "test_role", description: "test" } }
          assert_response :forbidden
        end

        test "PATCH update returns 403 when logged in as read-only admin" do
          login_as_admin_api_read_only
          patch api_v1_admin_role_path(roles(:regular)), params: { role: { description: "Updated" } }
          assert_response :forbidden
        end

        test "DELETE destroy returns 403 when logged in as read-only admin" do
          login_as_admin_api_read_only
          delete api_v1_admin_role_path(roles(:regular))
          assert_response :forbidden
        end

        test "DELETE destroy returns 403 when logged in as user_manager" do
          login_as_admin_api(users(:user_manager))
          delete api_v1_admin_role_path(roles(:regular))
          assert_response :forbidden
        end

        test "POST create returns 403 when logged in as user_manager" do
          login_as_admin_api(users(:user_manager))
          post api_v1_admin_roles_path, params: { role: { name: "test_role", description: "test" } }
          assert_response :forbidden
        end

        test "POST create returns 403 when logged in as llm_admin" do
          login_as_admin_api(users(:llm_admin_user))
          post api_v1_admin_roles_path, params: { role: { name: "test_role", description: "test" } }
          assert_response :forbidden
        end

        test "PATCH update returns 403 when logged in as llm_admin" do
          login_as_admin_api(users(:llm_admin_user))
          patch api_v1_admin_role_path(roles(:regular)), params: { role: { description: "Updated" } }
          assert_response :forbidden
        end

        test "DELETE destroy returns 403 when logged in as llm_admin" do
          login_as_admin_api(users(:llm_admin_user))
          delete api_v1_admin_role_path(roles(:regular))
          assert_response :forbidden
        end

        # system role 保護テスト
        test "PATCH update returns 403 when trying to update a system role" do
          login_as_admin_api
          patch api_v1_admin_role_path(roles(:admin)), params: { role: { description: "Hacked" } }
          assert_response :forbidden
        end

        test "DELETE destroy returns 403 when trying to delete a system role" do
          login_as_admin_api
          delete api_v1_admin_role_path(roles(:admin))
          assert_response :forbidden
        end

        test "DELETE destroy returns 403 when trying to delete user_manager system role" do
          login_as_admin_api
          delete api_v1_admin_role_path(roles(:user_manager))
          assert_response :forbidden
        end

        test "PATCH update returns 403 for non-system role when logged in as user_manager" do
          login_as_admin_api(users(:user_manager))
          patch api_v1_admin_role_path(roles(:regular)), params: { role: { description: "OK" } }
          assert_response :forbidden
        end

        # system_role パラメータ無視テスト（権限昇格防止）
        test "POST create ignores system_role param" do
          login_as_admin_api
          post api_v1_admin_roles_path, params: { role: { name: "evil_role", description: "test", system_role: true } }
          assert_response :created
          assert_not Role.find_by(name: "evil_role").system_role?
        end

        test "PATCH update ignores system_role param" do
          login_as_admin_api
          role = roles(:regular)
          patch api_v1_admin_role_path(role), params: { role: { description: "Updated", system_role: true } }
          assert_response :success
          assert_not role.reload.system_role?
        end
      end
    end
  end
end
