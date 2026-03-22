require "test_helper"

module Api
  module V1
    module Admin
      class AvailableModelsControllerTest < ActionDispatch::IntegrationTest
        test "GET index returns 401 when not logged in" do
          get api_v1_admin_llm_provider_available_models_path(llm_providers(:openai))
          assert_response :unauthorized
          assert_equal "Unauthorized", response.parsed_body["error"]
        end

        test "GET index returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          get api_v1_admin_llm_provider_available_models_path(llm_providers(:openai))
          assert_response :unauthorized
          assert_equal "Unauthorized", response.parsed_body["error"]
        end

        test "GET index returns 403 when logged in as read-only admin" do
          login_as_admin_api_read_only
          get api_v1_admin_llm_provider_available_models_path(llm_providers(:openai))
          assert_response :forbidden
        end

        test "GET index returns 200 with available models list when logged in as admin" do
          login_as_admin_api
          provider = llm_providers(:openai)
          mock_models = ["gpt-4", "gpt-3.5-turbo"]
          LlmProvider.any_instance.stubs(:api_key).returns("test-api-key")
          ModelListService.stubs(:fetch_models).returns(mock_models)
          get api_v1_admin_llm_provider_available_models_path(provider)
          assert_response :success
          json = response.parsed_body
          assert_kind_of Array, json
          assert_equal mock_models, json
        end

        test "GET index returns 404 for non-existent provider" do
          login_as_admin_api
          get api_v1_admin_llm_provider_available_models_path(llm_provider_id: 0)
          assert_response :not_found
        end

        test "GET index returns empty array when external API fails" do
          login_as_admin_api
          provider = llm_providers(:openai)
          LlmProvider.any_instance.stubs(:api_key).returns("test-api-key")
          ModelListService.stubs(:fetch_models).returns([])
          get api_v1_admin_llm_provider_available_models_path(provider)
          assert_response :success
          json = response.parsed_body
          assert_equal [], json
        end

        test "GET index returns 502 when external API raises error" do
          login_as_admin_api
          provider = llm_providers(:openai)
          LlmProvider.any_instance.stubs(:api_key).returns("test-api-key")
          ModelListService.stubs(:fetch_models).raises(LlmClient::ApiError.new("Connection failed"))
          get api_v1_admin_llm_provider_available_models_path(provider)
          assert_response :bad_gateway
          json = response.parsed_body
          assert json.key?("error")
        end
      end
    end
  end
end
