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

        test "GET index returns 200 with non-admin user list when logged in as admin" do
          login_as_admin_api
          get api_v1_admin_users_path
          assert_response :success
          json = response.parsed_body
          assert json.key?("users")
          assert json.key?("meta")
          emails = json["users"].pluck("email")
          # Non-admin users should be included
          assert_includes emails, users(:regular_user).email
          assert_includes emails, users(:no_role_user).email
          # Admin accounts should NOT be included
          assert_not_includes emails, users(:admin_user).email
          assert_not_includes emails, users(:user_manager).email
          assert_not_includes emails, users(:user_viewer).email
          assert_not_includes emails, users(:llm_admin_user).email
        end

        test "GET index response includes expected fields" do
          login_as_admin_api
          get api_v1_admin_users_path
          assert_response :success
          user = response.parsed_body["users"].first
          assert user.key?("id")
          assert user.key?("email")
          assert user.key?("name")
          assert user.key?("created_at")
          assert user.key?("updated_at")
          assert_not user.key?("password_digest")
        end

        test "GET index response does not include roles" do
          login_as_admin_api
          get api_v1_admin_users_path
          assert_response :success
          user = response.parsed_body["users"].first
          assert_not user.key?("roles")
        end

        test "GET index response includes pagination meta" do
          login_as_admin_api
          get api_v1_admin_users_path
          assert_response :success
          meta = response.parsed_body["meta"]
          assert meta.key?("page")
          assert meta.key?("per_page")
          assert meta.key?("total_count")
          assert meta.key?("total_pages")
          assert_equal 1, meta["page"]
        end

        test "GET index respects page and per_page params" do
          login_as_admin_api
          get api_v1_admin_users_path, params: { page: 2, per_page: 1 }
          assert_response :success
          meta = response.parsed_body["meta"]
          assert_equal 2, meta["page"]
          assert_equal 1, meta["per_page"]
        end

        test "GET index clamps page edge cases" do
          login_as_admin_api
          get api_v1_admin_users_path, params: { page: 0 }
          assert_response :success
          assert_equal 1, response.parsed_body["meta"]["page"]

          get api_v1_admin_users_path, params: { page: -1 }
          assert_response :success
          assert_equal 1, response.parsed_body["meta"]["page"]
        end

        test "GET index clamps per_page edge cases" do
          login_as_admin_api
          get api_v1_admin_users_path, params: { per_page: 0 }
          assert_response :success
          assert_equal 1, response.parsed_body["meta"]["per_page"]

          get api_v1_admin_users_path, params: { per_page: -1 }
          assert_response :success
          assert_equal 1, response.parsed_body["meta"]["per_page"]

          get api_v1_admin_users_path, params: { per_page: 999 }
          assert_response :success
          assert_equal 100, response.parsed_body["meta"]["per_page"]
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

        test "POST create succeeds when logged in as user_manager" do
          login_as_admin_api(users(:user_manager))
          assert_difference "User.count", 1 do
            post api_v1_admin_users_path,
                 params: { user: { email: "mgrnew@example.com", password: "password123", name: "Mgr New" } }
          end
          assert_response :created
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
        test "GET index with q param filters non-admin users by name" do
          login_as_admin_api
          get api_v1_admin_users_path, params: { q: "Regular" }
          assert_response :success
          users = response.parsed_body["users"]
          assert users.all? { |u|
            u["name"]&.downcase&.include?("regular") || u["email"]&.downcase&.include?("regular")
          }
        end

        test "GET index with q param filters non-admin users by email" do
          login_as_admin_api
          get api_v1_admin_users_path, params: { q: "norole@" }
          assert_response :success
          users = response.parsed_body["users"]
          assert_equal 1, users.size
          assert_equal "norole@example.com", users.first["email"]
        end

        test "GET index with q param does not return admin accounts" do
          login_as_admin_api
          get api_v1_admin_users_path, params: { q: "admin" }
          assert_response :success
          user_list = response.parsed_body["users"]
          assert user_list.none? { |u| u["email"] == users(:admin_user).email }
        end

        # boundary: admin accounts are not accessible via UsersController
        test "GET show returns 404 for admin account" do
          login_as_admin_api
          get api_v1_admin_user_path(users(:llm_admin_user))
          assert_response :not_found
        end

        test "PATCH update returns 404 for admin account" do
          login_as_admin_api
          patch api_v1_admin_user_path(users(:llm_admin_user)), params: { user: { name: "Hacked" } }
          assert_response :not_found
        end

        test "DELETE destroy returns 404 for admin account" do
          login_as_admin_api
          assert_no_difference "User.count" do
            delete api_v1_admin_user_path(users(:llm_admin_user))
          end
          assert_response :not_found
        end

        test "GET index with empty q param returns all non-admin users" do
          login_as_admin_api
          get api_v1_admin_users_path, params: { q: "" }
          assert_response :success
          non_admin_count = User.non_admin_accounts.count
          assert_equal non_admin_count, response.parsed_body["users"].size
        end
      end
    end
  end
end
