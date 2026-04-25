require "test_helper"

module Api
  module V1
    module Admin
      class UsersControllerTest < ActionDispatch::IntegrationTest
        # index — no status param (defaults to active)
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

        # Deactivated users must NOT be modifiable via update —
        # otherwise the sentinel email gets overwritten with the original,
        # breaking the re-registration guarantee.
        test "PATCH update returns 422 for deactivated user without modifying record" do
          login_as_admin_api
          target = users(:deactivated_user)
          original_sentinel_email = target.email
          original_name = target.name

          patch api_v1_admin_user_path(target),
                params: { user: { email: "hijack@example.com", name: "Hijacked" } }

          assert_response :unprocessable_entity
          assert_equal "Cannot modify a deactivated user", response.parsed_body["error"]

          target.reload
          assert_equal original_sentinel_email, target.email,
                       "Sentinel email must not be overwritten by update on deactivated user"
          assert_equal original_name, target.name
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
          login_as_llm_admin_api # llm_admin: Admin:read + LlmProvider 権限のみ（User:read なし）
          get api_v1_admin_users_path
          assert_response :forbidden
        end

        test "GET show returns 403 when logged in as user without User:read permission" do
          login_as_llm_admin_api # llm_admin: Admin:read + LlmProvider 権限のみ（User:read なし）
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
          non_admin_active_count = User.non_admin_accounts.active.count
          assert_equal non_admin_active_count, response.parsed_body["users"].size
        end

        # ---------------------------------------------------------------
        # Status filter tests
        # ---------------------------------------------------------------
        test "GET index with status=active returns only active non-admin users" do
          login_as_admin_api
          get api_v1_admin_users_path, params: { status: "active" }
          assert_response :success
          user_list = response.parsed_body["users"]
          emails = user_list.pluck("email")
          assert_includes emails, users(:regular_user).email
          assert_not_includes emails, users(:deactivated_user).email
        end

        test "GET index with status=deactivated returns only deactivated non-admin users" do
          login_as_admin_api
          get api_v1_admin_users_path, params: { status: "deactivated" }
          assert_response :success
          user_list = response.parsed_body["users"]
          ids = user_list.pluck("id")
          assert_includes ids, users(:deactivated_user).id
          assert_not_includes ids, users(:regular_user).id
        end

        test "GET index with status=all returns disjoint union of active and deactivated" do
          login_as_admin_api
          get api_v1_admin_users_path, params: { status: "active" }
          active_ids = response.parsed_body["users"].pluck("id")

          get api_v1_admin_users_path, params: { status: "deactivated" }
          deactivated_ids = response.parsed_body["users"].pluck("id")

          get api_v1_admin_users_path, params: { status: "all" }
          all_ids = response.parsed_body["users"].pluck("id")

          assert_equal (active_ids + deactivated_ids).sort, all_ids.sort,
                       "status=all must equal active + deactivated (disjoint)"
          assert_empty active_ids & deactivated_ids, "active and deactivated sets must be disjoint"
        end

        # ---------------------------------------------------------------
        # Sentinel email leak prevention
        # Deactivated users have email == sentinel (@deactivated.invalid).
        # The `email` field in the response for deactivated users must NOT
        # expose the sentinel — expose original_email instead.
        # ---------------------------------------------------------------
        test "GET index status=deactivated does not leak sentinel emails in response" do
          login_as_admin_api
          get api_v1_admin_users_path, params: { status: "deactivated" }
          assert_response :success
          body = response.body
          assert_no_match(/@deactivated\.invalid/, body,
                          "Sentinel email must not appear in index response")
        end

        test "GET index status=all does not leak sentinel emails in response" do
          login_as_admin_api
          get api_v1_admin_users_path, params: { status: "all" }
          assert_response :success
          body = response.body
          assert_no_match(/@deactivated\.invalid/, body,
                          "Sentinel email must not appear in all-status response")
        end

        test "GET show for deactivated user does not leak sentinel email" do
          login_as_admin_api
          target = users(:deactivated_user)
          get api_v1_admin_user_path(target)
          assert_response :success
          body = response.body
          assert_no_match(/@deactivated\.invalid/, body,
                          "Sentinel email must not appear in show response")
          json = response.parsed_body
          assert_equal deactivated_users(:deactivated_regular_user).original_email,
                       json["original_email"]
        end

        test "GET index status=deactivated response includes deactivation fields" do
          login_as_admin_api
          get api_v1_admin_users_path, params: { status: "deactivated" }
          assert_response :success
          deactivated = response.parsed_body["users"].find { |u| u["id"] == users(:deactivated_user).id }
          assert_not_nil deactivated
          assert deactivated.key?("deactivated_at")
          assert deactivated.key?("deactivation_reason")
          assert deactivated.key?("deactivated_by")
          assert deactivated.key?("original_email")
        end

        test "GET show for deactivated user includes deactivation fields" do
          login_as_admin_api
          target = users(:deactivated_user)
          get api_v1_admin_user_path(target)
          assert_response :success
          json = response.parsed_body
          assert json.key?("deactivated_at")
          assert json.key?("deactivation_reason")
          assert json.key?("deactivated_by")
          assert json.key?("original_email")
        end

        test "GET show for active user has nil deactivation fields" do
          login_as_admin_api
          target = users(:regular_user)
          get api_v1_admin_user_path(target)
          assert_response :success
          json = response.parsed_body
          assert_nil json["deactivated_at"]
          assert_nil json["deactivation_reason"]
          assert_nil json["deactivated_by"]
          assert_nil json["original_email"]
        end
      end
    end
  end
end
