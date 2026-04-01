require "test_helper"

module Api
  module V1
    module Admin
      class LlmProvidersControllerTest < ActionDispatch::IntegrationTest
        # index
        test "GET index returns 401 when not logged in" do
          get api_v1_admin_llm_providers_path
          assert_response :unauthorized
          assert_equal "Unauthorized", response.parsed_body["error"]
        end

        test "GET index returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          get api_v1_admin_llm_providers_path
          assert_response :unauthorized
          assert_equal "Unauthorized", response.parsed_body["error"]
        end

        test "GET index returns 200 with provider list when logged in as admin" do
          login_as_admin_api
          get api_v1_admin_llm_providers_path
          assert_response :success
          json = response.parsed_body
          assert_kind_of Array, json
          names = json.pluck("name")
          assert_includes names, llm_providers(:openai).name
          assert_includes names, llm_providers(:anthropic).name
        end

        test "GET index response does not include api_key_encrypted" do
          login_as_admin_api
          get api_v1_admin_llm_providers_path
          assert_response :success
          json = response.parsed_body
          json.each do |provider|
            assert_not provider.key?("api_key_encrypted")
          end
        end

        test "GET index response includes expected fields" do
          login_as_admin_api
          get api_v1_admin_llm_providers_path
          assert_response :success
          provider = response.parsed_body.first
          assert provider.key?("id")
          assert provider.key?("name")
          assert provider.key?("active")
          assert provider.key?("created_at")
          assert provider.key?("updated_at")
        end

        # show
        test "GET show returns 401 when not logged in" do
          get api_v1_admin_llm_provider_path(llm_providers(:openai))
          assert_response :unauthorized
        end

        test "GET show returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          get api_v1_admin_llm_provider_path(llm_providers(:openai))
          assert_response :unauthorized
        end

        test "GET show returns 200 with provider details when logged in as admin" do
          login_as_admin_api
          provider = llm_providers(:openai)
          get api_v1_admin_llm_provider_path(provider)
          assert_response :success
          json = response.parsed_body
          assert_equal provider.id, json["id"]
          assert_equal provider.name, json["name"]
          assert_not json.key?("api_key_encrypted")
        end

        test "GET show returns 404 for non-existent provider" do
          login_as_admin_api
          get api_v1_admin_llm_provider_path(id: 0)
          assert_response :not_found
        end

        # update
        test "PATCH update returns 401 when not logged in" do
          patch api_v1_admin_llm_provider_path(llm_providers(:openai)),
                params: { llm_provider: { organization_id: "org-new" } }
          assert_response :unauthorized
        end

        test "PATCH update returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          patch api_v1_admin_llm_provider_path(llm_providers(:openai)),
                params: { llm_provider: { organization_id: "org-new" } }
          assert_response :unauthorized
        end

        test "PATCH update updates provider when logged in as admin" do
          login_as_admin_api
          provider = llm_providers(:openai)
          patch api_v1_admin_llm_provider_path(provider), params: { llm_provider: { organization_id: "org-updated" } }
          assert_response :success
          json = response.parsed_body
          assert_equal "org-updated", json["organization_id"]
          assert_not json.key?("api_key_encrypted")
        end

        test "PATCH update returns 422 on invalid params" do
          login_as_admin_api
          provider = llm_providers(:openai)
          patch api_v1_admin_llm_provider_path(provider), params: { llm_provider: { name: "" } }
          assert_response :unprocessable_entity
          assert response.parsed_body.key?("errors")
        end

        # 操作別認可テスト（write_access チェック）
        test "PATCH update returns 403 when logged in as read-only admin" do
          login_as_admin_api_read_only
          provider = llm_providers(:openai)
          patch api_v1_admin_llm_provider_path(provider),
                params: { llm_provider: { organization_id: "org-hacked" } }
          assert_response :forbidden
        end

        # LlmProvider resource権限テスト
        test "GET index returns 403 when logged in as user_viewer (no LlmProvider:read)" do
          login_as_admin_api_read_only
          get api_v1_admin_llm_providers_path
          assert_response :forbidden
        end

        test "GET index returns 403 when logged in as user_manager (no LlmProvider:read)" do
          user = users(:user_manager)
          post api_v1_admin_session_path, params: { email: user.email, password: TEST_PASSWORD }, as: :json
          get api_v1_admin_llm_providers_path
          assert_response :forbidden
        end

        test "GET index returns 200 when logged in as llm_admin" do
          login_as_llm_admin_api
          get api_v1_admin_llm_providers_path
          assert_response :success
        end

        test "GET show returns 403 when logged in as user_viewer (no LlmProvider:read)" do
          login_as_admin_api_read_only
          get api_v1_admin_llm_provider_path(llm_providers(:openai))
          assert_response :forbidden
        end

        test "GET show returns 200 when logged in as llm_admin" do
          login_as_llm_admin_api
          get api_v1_admin_llm_provider_path(llm_providers(:openai))
          assert_response :success
        end

        test "PATCH update returns 403 when logged in as llm_admin without write permission" do
          # llm_adminはllm_provider_writeを持つので成功するはずだが、user_managerはできない
          user = users(:user_manager)
          post api_v1_admin_session_path, params: { email: user.email, password: TEST_PASSWORD }, as: :json
          patch api_v1_admin_llm_provider_path(llm_providers(:openai)),
                params: { llm_provider: { organization_id: "org-hacked" } }
          assert_response :forbidden
        end

        test "PATCH update succeeds when logged in as llm_admin" do
          login_as_llm_admin_api
          provider = llm_providers(:openai)
          patch api_v1_admin_llm_provider_path(provider),
                params: { llm_provider: { organization_id: "org-llm" } }
          assert_response :success
        end
      end
    end
  end
end
