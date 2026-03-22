require "test_helper"

module Api
  module V1
    module Admin
      class LlmModelsControllerTest < ActionDispatch::IntegrationTest
        # index
        test "GET index returns 401 when not logged in" do
          get api_v1_admin_llm_provider_llm_models_path(llm_providers(:openai))
          assert_response :unauthorized
          assert_equal "Unauthorized", response.parsed_body["error"]
        end

        test "GET index returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          get api_v1_admin_llm_provider_llm_models_path(llm_providers(:openai))
          assert_response :unauthorized
          assert_equal "Unauthorized", response.parsed_body["error"]
        end

        test "GET index returns 200 with model list for the provider" do
          login_as_admin_api
          provider = llm_providers(:openai)
          get api_v1_admin_llm_provider_llm_models_path(provider)
          assert_response :success
          json = response.parsed_body
          assert_kind_of Array, json
          names = json.pluck("name")
          assert_includes names, llm_models(:gpt_turbo).name
          assert_includes names, llm_models(:gpt4).name
        end

        test "GET index only returns models for the specified provider" do
          login_as_admin_api
          provider = llm_providers(:openai)
          get api_v1_admin_llm_provider_llm_models_path(provider)
          assert_response :success
          json = response.parsed_body
          provider_ids = json.pluck("llm_provider_id").uniq
          assert_equal [provider.id], provider_ids
        end

        test "GET index returns 404 for non-existent provider" do
          login_as_admin_api
          get api_v1_admin_llm_provider_llm_models_path(llm_provider_id: 0)
          assert_response :not_found
        end

        test "GET index response includes expected fields" do
          login_as_admin_api
          get api_v1_admin_llm_provider_llm_models_path(llm_providers(:openai))
          assert_response :success
          model = response.parsed_body.first
          assert model.key?("id")
          assert model.key?("name")
          assert model.key?("display_name")
          assert model.key?("active")
          assert model.key?("default_model")
          assert model.key?("llm_provider_id")
        end

        # show
        test "GET show returns 401 when not logged in" do
          get api_v1_admin_llm_provider_llm_model_path(llm_providers(:openai), llm_models(:gpt_turbo))
          assert_response :unauthorized
        end

        test "GET show returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          get api_v1_admin_llm_provider_llm_model_path(llm_providers(:openai), llm_models(:gpt_turbo))
          assert_response :unauthorized
        end

        test "GET show returns 200 with model details when logged in as admin" do
          login_as_admin_api
          model = llm_models(:gpt_turbo)
          get api_v1_admin_llm_provider_llm_model_path(llm_providers(:openai), model)
          assert_response :success
          json = response.parsed_body
          assert_equal model.id, json["id"]
          assert_equal model.name, json["name"]
          assert_equal model.display_name, json["display_name"]
        end

        test "GET show returns 404 for non-existent model" do
          login_as_admin_api
          get api_v1_admin_llm_provider_llm_model_path(llm_providers(:openai), id: 0)
          assert_response :not_found
        end

        # create
        test "POST create returns 401 when not logged in" do
          post api_v1_admin_llm_provider_llm_models_path(llm_providers(:openai)),
               params: { llm_model: { name: "gpt-new", display_name: "GPT New" } }
          assert_response :unauthorized
        end

        test "POST create returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          post api_v1_admin_llm_provider_llm_models_path(llm_providers(:openai)),
               params: { llm_model: { name: "gpt-new", display_name: "GPT New" } }
          assert_response :unauthorized
        end

        test "POST create creates a new model when logged in as admin" do
          login_as_admin_api
          provider = llm_providers(:openai)
          assert_difference "LlmModel.count", 1 do
            post api_v1_admin_llm_provider_llm_models_path(provider),
                 params: { llm_model: { name: "gpt-new-model", display_name: "GPT New Model" } }
          end
          assert_response :created
          json = response.parsed_body
          assert_equal "gpt-new-model", json["name"]
          assert_equal "GPT New Model", json["display_name"]
          assert_equal provider.id, json["llm_provider_id"]
        end

        test "POST create returns 422 with validation errors on invalid params" do
          login_as_admin_api
          post api_v1_admin_llm_provider_llm_models_path(llm_providers(:openai)),
               params: { llm_model: { name: "", display_name: "No Name" } }
          assert_response :unprocessable_entity
          assert response.parsed_body.key?("errors")
        end

        # update
        test "PATCH update returns 401 when not logged in" do
          patch api_v1_admin_llm_provider_llm_model_path(llm_providers(:openai), llm_models(:gpt_turbo)),
                params: { llm_model: { display_name: "Updated" } }
          assert_response :unauthorized
        end

        test "PATCH update returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          patch api_v1_admin_llm_provider_llm_model_path(llm_providers(:openai), llm_models(:gpt_turbo)),
                params: { llm_model: { display_name: "Updated" } }
          assert_response :unauthorized
        end

        test "PATCH update updates model when logged in as admin" do
          login_as_admin_api
          model = llm_models(:gpt_turbo)
          patch api_v1_admin_llm_provider_llm_model_path(llm_providers(:openai), model),
                params: { llm_model: { display_name: "Updated Display Name" } }
          assert_response :success
          json = response.parsed_body
          assert_equal "Updated Display Name", json["display_name"]
        end

        test "PATCH update returns 422 on invalid params" do
          login_as_admin_api
          model = llm_models(:gpt_turbo)
          patch api_v1_admin_llm_provider_llm_model_path(llm_providers(:openai), model),
                params: { llm_model: { name: "" } }
          assert_response :unprocessable_entity
          assert response.parsed_body.key?("errors")
        end

        # destroy
        test "DELETE destroy returns 401 when not logged in" do
          delete api_v1_admin_llm_provider_llm_model_path(llm_providers(:anthropic), llm_models(:claude))
          assert_response :unauthorized
        end

        test "DELETE destroy returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          delete api_v1_admin_llm_provider_llm_model_path(llm_providers(:anthropic), llm_models(:claude))
          assert_response :unauthorized
        end

        test "DELETE destroy deletes a model when logged in as admin" do
          login_as_admin_api
          model = llm_models(:claude)
          assert_difference "LlmModel.count", -1 do
            delete api_v1_admin_llm_provider_llm_model_path(llm_providers(:anthropic), model)
          end
          assert_response :no_content
        end

        # 操作別認可テスト（write/delete_access チェック）
        test "POST create returns 403 when logged in as read-only admin" do
          login_as_admin_api_read_only
          post api_v1_admin_llm_provider_llm_models_path(llm_providers(:openai)),
               params: { llm_model: { name: "hacked-model", display_name: "Hacked" } }
          assert_response :forbidden
        end

        test "PATCH update returns 403 when logged in as read-only admin" do
          login_as_admin_api_read_only
          patch api_v1_admin_llm_provider_llm_model_path(llm_providers(:openai), llm_models(:gpt_turbo)),
                params: { llm_model: { display_name: "Hacked" } }
          assert_response :forbidden
        end

        test "DELETE destroy returns 403 when logged in as read-only admin" do
          login_as_admin_api_read_only
          delete api_v1_admin_llm_provider_llm_model_path(llm_providers(:anthropic), llm_models(:claude))
          assert_response :forbidden
        end

        # LlmProvider resource権限テスト
        test "GET index returns 403 when logged in as user_viewer (no LlmProvider:read)" do
          login_as_admin_api_read_only
          get api_v1_admin_llm_provider_llm_models_path(llm_providers(:openai))
          assert_response :forbidden
        end

        test "GET index returns 403 when logged in as user_manager (no LlmProvider:read)" do
          user = users(:user_manager)
          post api_v1_admin_session_path, params: { email: user.email, password: TEST_PASSWORD }, as: :json
          get api_v1_admin_llm_provider_llm_models_path(llm_providers(:openai))
          assert_response :forbidden
        end

        test "GET index returns 200 when logged in as llm_admin" do
          login_as_llm_admin_api
          get api_v1_admin_llm_provider_llm_models_path(llm_providers(:openai))
          assert_response :success
        end

        test "GET show returns 403 when logged in as user_viewer (no LlmProvider:read)" do
          login_as_admin_api_read_only
          get api_v1_admin_llm_provider_llm_model_path(llm_providers(:openai), llm_models(:gpt_turbo))
          assert_response :forbidden
        end

        test "GET show returns 200 when logged in as llm_admin" do
          login_as_llm_admin_api
          get api_v1_admin_llm_provider_llm_model_path(llm_providers(:openai), llm_models(:gpt_turbo))
          assert_response :success
        end
      end
    end
  end
end
