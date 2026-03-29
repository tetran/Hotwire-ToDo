require "test_helper"

module Api
  module V1
    module Admin
      class UsersControllerTest < ActionDispatch::IntegrationTest
        # index
        test "GET index returns 401 when not logged in" do
          get api_v1_admin_users_path
          assert_response :unauthorized
          assert_equal "Unauthorized", response.parsed_body["error"]
        end

        test "GET index returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          get api_v1_admin_users_path
          assert_response :unauthorized
          assert_equal "Unauthorized", response.parsed_body["error"]
        end

        test "GET index returns 200 with user list when logged in as admin" do
          login_as_admin_api
          get api_v1_admin_users_path
          assert_response :success
          json = response.parsed_body
          assert_kind_of Array, json
          emails = json.pluck("email")
          assert_includes emails, users(:admin_user).email
        end

        test "GET index response includes expected fields" do
          login_as_admin_api
          get api_v1_admin_users_path
          assert_response :success
          user = response.parsed_body.first
          assert user.key?("id")
          assert user.key?("email")
          assert user.key?("name")
          assert user.key?("created_at")
          assert user.key?("updated_at")
          assert_not user.key?("password_digest")
        end

        test "GET index response includes roles for each user" do
          login_as_admin_api
          get api_v1_admin_users_path
          assert_response :success
          user = response.parsed_body.first
          assert user.key?("roles")
          assert_kind_of Array, user["roles"]
          unless user["roles"].empty?
            role = user["roles"].first
            assert role.key?("id")
            assert role.key?("name")
          end
        end

        # show
        test "GET show returns 401 when not logged in" do
          get api_v1_admin_user_path(users(:regular_user))
          assert_response :unauthorized
        end

        test "GET show returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          get api_v1_admin_user_path(users(:admin_user))
          assert_response :unauthorized
        end

        test "GET show returns 200 with user details when logged in as admin" do
          login_as_admin_api
          target = users(:regular_user)
          get api_v1_admin_user_path(target)
          assert_response :success
          json = response.parsed_body
          assert_equal target.id, json["id"]
          assert_equal target.email, json["email"]
          assert_not json.key?("password_digest")
        end

        test "GET show returns 404 for non-existent user" do
          login_as_admin_api
          get api_v1_admin_user_path(id: 0)
          assert_response :not_found
        end

        # create
        test "POST create returns 401 when not logged in" do
          post api_v1_admin_users_path,
               params: { user: { email: "new@example.com", password: "password123", name: "New User" } }
          assert_response :unauthorized
        end

        test "POST create returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          post api_v1_admin_users_path,
               params: { user: { email: "new@example.com", password: "password123", name: "New User" } }
          assert_response :unauthorized
        end

        test "POST create creates a new user when logged in as admin" do
          login_as_admin_api
          assert_difference "User.count", 1 do
            post api_v1_admin_users_path,
                 params: { user: { email: "newuser@example.com", password: "password123", name: "New User" } }
          end
          assert_response :created
          json = response.parsed_body
          assert_equal "newuser@example.com", json["email"]
          assert_equal "New User", json["name"]
        end

        test "POST create returns 422 with validation errors on invalid params" do
          login_as_admin_api
          post api_v1_admin_users_path, params: { user: { email: "", password: "password123", name: "New User" } }
          assert_response :unprocessable_entity
          json = response.parsed_body
          assert json.key?("errors")
        end

        # update
        test "PATCH update returns 401 when not logged in" do
          patch api_v1_admin_user_path(users(:regular_user)), params: { user: { name: "Updated" } }
          assert_response :unauthorized
        end

        test "PATCH update returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          patch api_v1_admin_user_path(users(:admin_user)), params: { user: { name: "Updated" } }
          assert_response :unauthorized
        end

        test "PATCH update updates user when logged in as admin" do
          login_as_admin_api
          target = users(:regular_user)
          patch api_v1_admin_user_path(target), params: { user: { name: "Updated Name" } }
          assert_response :success
          json = response.parsed_body
          assert_equal "Updated Name", json["name"]
        end

        test "PATCH update returns 422 on invalid params" do
          login_as_admin_api
          target = users(:regular_user)
          patch api_v1_admin_user_path(target), params: { user: { email: "" } }
          assert_response :unprocessable_entity
          assert response.parsed_body.key?("errors")
        end

        # destroy
        test "DELETE destroy returns 401 when not logged in" do
          delete api_v1_admin_user_path(users(:no_role_user))
          assert_response :unauthorized
        end

        test "DELETE destroy returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          delete api_v1_admin_user_path(users(:no_role_user))
          assert_response :unauthorized
        end

        test "DELETE destroy deletes a user when logged in as admin" do
          login_as_admin_api
          target = users(:no_role_user)
          assert_difference "User.count", -1 do
            delete api_v1_admin_user_path(target)
          end
          assert_response :no_content
        end

        test "DELETE destroy returns 403 when trying to delete self" do
          login_as_admin_api
          delete api_v1_admin_user_path(users(:admin_user))
          assert_response :forbidden
          assert_equal "Cannot delete yourself", response.parsed_body["error"]
        end

        # 操作別認可テスト
        test "POST create returns 403 when logged in as read-only admin" do
          login_as_admin_api_read_only
          post api_v1_admin_users_path,
               params: { user: { email: "new@example.com", password: "password123", name: "New" } }
          assert_response :forbidden
        end

        test "PATCH update returns 403 when logged in as read-only admin" do
          login_as_admin_api_read_only
          patch api_v1_admin_user_path(users(:no_role_user)), params: { user: { name: "Updated" } }
          assert_response :forbidden
        end

        test "DELETE destroy returns 403 when logged in as read-only admin" do
          login_as_admin_api_read_only
          delete api_v1_admin_user_path(users(:no_role_user))
          assert_response :forbidden
        end

        test "POST create succeeds when logged in as user_manager" do
          login_as_admin_api(users(:user_manager))
          assert_difference "User.count", 1 do
            post api_v1_admin_users_path,
                 params: { user: { email: "mgrnew@example.com", password: "password123", name: "Mgr New" } }
          end
          assert_response :created
        end

        test "DELETE destroy succeeds when logged in as user_manager (has User:delete)" do
          login_as_admin_api(users(:user_manager))
          assert_difference "User.count", -1 do
            delete api_v1_admin_user_path(users(:no_role_user))
          end
          assert_response :no_content
        end

        # リソース単位の read 認可テスト（User:read が必要）
        test "GET index returns 403 when logged in as user without User:read permission" do
          login_as_llm_admin_api  # llm_admin: Admin:read + LlmProvider 権限のみ（User:read なし）
          get api_v1_admin_users_path
          assert_response :forbidden
        end

        test "GET show returns 403 when logged in as user without User:read permission" do
          login_as_llm_admin_api  # llm_admin: Admin:read + LlmProvider 権限のみ（User:read なし）
          get api_v1_admin_user_path(users(:no_role_user))
          assert_response :forbidden
        end

        test "GET index returns 200 when logged in as user_manager" do
          login_as_admin_api(users(:user_manager))
          get api_v1_admin_users_path
          assert_response :success
        end

        # search
        test "GET index with q param filters users by name" do
          login_as_admin_api
          get api_v1_admin_users_path, params: { q: "Admin" }
          assert_response :success
          json = response.parsed_body
          assert json.all? { |u| u["name"]&.downcase&.include?("admin") || u["email"]&.downcase&.include?("admin") }
          assert json.none? { |u| u["email"] == "norole@example.com" }
        end

        test "GET index with q param filters users by email" do
          login_as_admin_api
          get api_v1_admin_users_path, params: { q: "manager@" }
          assert_response :success
          json = response.parsed_body
          assert_equal 1, json.size
          assert_equal "manager@example.com", json.first["email"]
        end

        test "GET index with empty q param returns all users" do
          login_as_admin_api
          get api_v1_admin_users_path, params: { q: "" }
          assert_response :success
          all_count = User.count
          assert_equal all_count, response.parsed_body.size
        end
      end
    end
  end
end
