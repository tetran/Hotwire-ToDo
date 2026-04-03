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
        # create
        test "POST create returns 401 when not logged in" do
          post api_v1_admin_admin_accounts_path, params: {
            admin_account: {
              email: "new@example.com", name: "New Admin",
              password: "password123", role_ids: [roles(:user_viewer).id]
            },
          }
          assert_response :unauthorized
        end

        test "POST create returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          post api_v1_admin_admin_accounts_path, params: {
            admin_account: {
              email: "new@example.com", name: "New Admin",
              password: "password123", role_ids: [roles(:user_viewer).id]
            },
          }
          assert_response :unauthorized
        end

        test "POST create returns 403 when logged in as read-only admin" do
          login_as_admin_api_read_only
          post api_v1_admin_admin_accounts_path, params: {
            admin_account: {
              email: "new@example.com", name: "New Admin",
              password: "password123", role_ids: [roles(:user_viewer).id]
            },
          }
          assert_response :forbidden
        end

        test "POST create creates admin account with roles" do
          login_as_admin_api
          viewer_role = roles(:user_viewer)
          assert_difference "User.count", 1 do
            post api_v1_admin_admin_accounts_path, params: {
              admin_account: {
                email: "newadmin@example.com", name: "New Admin",
                password: "password123", role_ids: [viewer_role.id]
              },
            }
          end
          assert_response :created
          json = response.parsed_body
          assert_equal "newadmin@example.com", json["email"]
          assert_equal "New Admin", json["name"]
          assert_equal 1, json["roles"].size
          assert_equal viewer_role.name, json["roles"].first["name"]
          assert User.admin_accounts.exists?(email: "newadmin@example.com")
        end

        test "POST create returns 422 when role_ids is empty" do
          login_as_admin_api
          assert_no_difference "User.count" do
            post api_v1_admin_admin_accounts_path, params: {
              admin_account: {
                email: "new@example.com", name: "New Admin",
                password: "password123", role_ids: []
              },
            }
          end
          assert_response :unprocessable_entity
          assert_equal "At least one role is required", response.parsed_body["error"]
        end

        test "POST create returns 422 when no role has admin access" do
          login_as_admin_api
          assert_no_difference "User.count" do
            post api_v1_admin_admin_accounts_path, params: {
              admin_account: {
                email: "new@example.com", name: "New Admin",
                password: "password123", role_ids: [roles(:regular).id]
              },
            }
          end
          assert_response :unprocessable_entity
          assert_equal "At least one role with admin access is required",
                       response.parsed_body["error"]
        end

        test "POST create returns 422 with validation errors on blank email" do
          login_as_admin_api
          assert_no_difference "User.count" do
            post api_v1_admin_admin_accounts_path, params: {
              admin_account: {
                email: "", name: "New Admin",
                password: "password123", role_ids: [roles(:user_viewer).id]
              },
            }
          end
          assert_response :unprocessable_entity
          assert response.parsed_body.key?("errors")
        end

        test "POST create returns 422 with duplicate email" do
          login_as_admin_api
          assert_no_difference "User.count" do
            post api_v1_admin_admin_accounts_path, params: {
              admin_account: {
                email: users(:admin_user).email, name: "Dup",
                password: "password123", role_ids: [roles(:user_viewer).id]
              },
            }
          end
          assert_response :unprocessable_entity
          assert response.parsed_body.key?("errors")
        end

        test "POST create returns 422 when role_id does not exist" do
          login_as_admin_api
          assert_no_difference "User.count" do
            post api_v1_admin_admin_accounts_path, params: {
              admin_account: {
                email: "new@example.com", name: "New Admin",
                password: "password123", role_ids: [0]
              },
            }
          end
          assert_response :unprocessable_entity
          assert_equal "Some roles were not found", response.parsed_body["error"]
        end

        test "POST create returns 403 on privilege escalation" do
          # user_manager doesn't have LlmProvider permissions
          login_as_admin_api(users(:user_manager))
          assert_no_difference "User.count" do
            post api_v1_admin_admin_accounts_path, params: {
              admin_account: {
                email: "new@example.com", name: "New Admin",
                password: "password123", role_ids: [roles(:llm_admin).id]
              },
            }
          end
          assert_response :forbidden
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

        # show
        test "GET show returns 401 when not logged in" do
          get api_v1_admin_admin_account_path(users(:admin_user))
          assert_response :unauthorized
        end

        test "GET show returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          get api_v1_admin_admin_account_path(users(:admin_user))
          assert_response :unauthorized
        end

        test "GET show returns 200 with account detail" do
          login_as_admin_api
          target = users(:user_manager)
          get api_v1_admin_admin_account_path(target)
          assert_response :success
          json = response.parsed_body
          assert_equal target.id, json["id"]
          assert_equal target.email, json["email"]
          assert_equal target.name, json["name"]
          assert json.key?("created_at")
          assert json.key?("updated_at")
          assert_not json.key?("password_digest")
        end

        test "GET show includes roles with detail fields" do
          login_as_admin_api
          get api_v1_admin_admin_account_path(users(:user_manager))
          assert_response :success
          roles = response.parsed_body["roles"]
          assert_kind_of Array, roles
          assert_equal 1, roles.size
          role = roles.first
          assert role.key?("id")
          assert role.key?("name")
          assert role.key?("description")
          assert role.key?("system_role")
        end

        test "GET show includes permission_matrix with all resource types and actions" do
          login_as_admin_api
          get api_v1_admin_admin_account_path(users(:user_manager))
          assert_response :success
          matrix = response.parsed_body["permission_matrix"]
          assert_kind_of Hash, matrix

          booleans = [true, false]
          Permission::RESOURCE_TYPES.each do |rt|
            assert matrix.key?(rt), "Missing resource type: #{rt}"
            Permission::ACTIONS.each do |action|
              assert booleans.include?(matrix[rt][action]),
                     "Expected boolean for #{rt}:#{action}"
            end
          end
        end

        test "GET show permission_matrix reflects actual permissions" do
          login_as_admin_api
          # user_manager has User:read/write/delete and Admin:read
          get api_v1_admin_admin_account_path(users(:user_manager))
          assert_response :success
          matrix = response.parsed_body["permission_matrix"]

          assert_equal true, matrix["User"]["read"]
          assert_equal true, matrix["User"]["write"]
          assert_equal true, matrix["User"]["delete"]
          assert_equal false, matrix["User"]["manage"]
          assert_equal true, matrix["Admin"]["read"]
          assert_equal false, matrix["Admin"]["write"]
          assert_equal false, matrix["Project"]["read"]
        end

        test "GET show permission_matrix manage implies read/write/delete" do
          login_as_admin_api
          # admin role has User:manage
          get api_v1_admin_admin_account_path(users(:admin_user))
          assert_response :success
          matrix = response.parsed_body["permission_matrix"]

          assert_equal true, matrix["User"]["manage"]
          assert_equal true, matrix["User"]["read"]
          assert_equal true, matrix["User"]["write"]
          assert_equal true, matrix["User"]["delete"]
        end

        test "GET show returns 404 for non-admin user" do
          login_as_admin_api
          get api_v1_admin_admin_account_path(users(:regular_user))
          assert_response :not_found
        end

        test "GET show returns 404 for non-existent user" do
          login_as_admin_api
          get api_v1_admin_admin_account_path(id: 0)
          assert_response :not_found
        end
      end
    end
  end
end
