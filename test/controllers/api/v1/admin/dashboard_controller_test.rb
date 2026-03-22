require "test_helper"

module Api
  module V1
    module Admin
      class DashboardControllerTest < ActionDispatch::IntegrationTest
        test "GET index returns 401 when not logged in" do
          get api_v1_admin_root_path
          assert_response :unauthorized
        end

        test "GET index returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          get api_v1_admin_root_path
          assert_response :unauthorized
        end

        test "GET index returns status ok when logged in as admin" do
          login_as_admin_api
          get api_v1_admin_root_path
          assert_response :success
          json = response.parsed_body
          assert_equal "ok", json["status"]
        end

        test "GET index returns stats with counts when logged in as admin" do
          login_as_admin_api
          get api_v1_admin_root_path
          assert_response :success
          json = response.parsed_body
          stats = json["stats"]
          assert_not_nil stats
          assert stats.key?("users_count")
          assert stats.key?("roles_count")
          assert stats.key?("llm_providers_count")
          assert stats.key?("llm_models_count")
          assert_equal User.count, stats["users_count"]
          assert_equal Role.count, stats["roles_count"]
          assert_equal LlmProvider.count, stats["llm_providers_count"]
          assert_equal LlmModel.count, stats["llm_models_count"]
        end

        test "GET index returns recent_users array when logged in as admin" do
          login_as_admin_api
          get api_v1_admin_root_path
          assert_response :success
          json = response.parsed_body
          recent_users = json["recent_users"]
          assert_kind_of Array, recent_users
          assert recent_users.length <= 5
          unless recent_users.empty?
            user = recent_users.first
            assert user.key?("id")
            assert user.key?("name")
            assert user.key?("email")
            assert user.key?("created_at")
            assert_not user.key?("password_digest")
          end
        end

        test "GET index recent_users are ordered by created_at desc" do
          login_as_admin_api
          get api_v1_admin_root_path
          assert_response :success
          recent_users = response.parsed_body["recent_users"]
          timestamps = recent_users.map { |u| Time.zone.parse(u["created_at"]) }
          assert_equal timestamps.sort.reverse, timestamps
        end

        # User:read権限によるrecent_usersのアクセス制御
        test "GET index returns empty recent_users when logged in as llm_admin (no User:read)" do
          login_as_llm_admin_api # llm_admin: Admin:read + LlmProvider 権限のみ（User:read なし）
          get api_v1_admin_root_path
          assert_response :success
          json = response.parsed_body
          assert_equal [], json["recent_users"]
        end

        test "GET index returns recent_users when logged in as user_manager (has User:read)" do
          user = users(:user_manager)
          post api_v1_admin_session_path, params: { email: user.email, password: TEST_PASSWORD }, as: :json
          get api_v1_admin_root_path
          assert_response :success
          json = response.parsed_body
          assert_kind_of Array, json["recent_users"]
          assert json["recent_users"].length >= 1
        end
      end
    end
  end
end
