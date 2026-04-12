require "test_helper"

module Api
  module V1
    module Admin
      class PromptSetsControllerTest < ActionDispatch::IntegrationTest
        # === index ===
        test "GET index returns 401 when not logged in" do
          get api_v1_admin_prompt_sets_path
          assert_response :unauthorized
        end

        test "GET index returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          get api_v1_admin_prompt_sets_path
          assert_response :unauthorized
        end

        test "GET index returns 403 when logged in as user_manager (no LlmProvider:read)" do
          user = users(:user_manager)
          post api_v1_admin_session_path, params: { email: user.email, password: TEST_PASSWORD }, as: :json
          get api_v1_admin_prompt_sets_path
          assert_response :forbidden
        end

        test "GET index returns 200 with prompt set list when logged in as admin" do
          login_as_admin_api
          get api_v1_admin_prompt_sets_path
          assert_response :success
          json = response.parsed_body
          assert json.key?("prompt_sets")
          assert json.key?("meta")
          names = json["prompt_sets"].pluck("name")
          assert_includes names, prompt_sets(:general).name
          assert_includes names, prompt_sets(:coding).name
        end

        test "GET index returns 200 when logged in as llm_admin" do
          login_as_llm_admin_api
          get api_v1_admin_prompt_sets_path
          assert_response :success
        end

        test "GET index includes nested prompts" do
          login_as_admin_api
          get api_v1_admin_prompt_sets_path
          assert_response :success
          json = response.parsed_body["prompt_sets"]
          ps = json.find { |p| p["name"] == prompt_sets(:general).name }
          assert ps.key?("prompts")
          assert_kind_of Array, ps["prompts"]
          assert ps["prompts"].length >= 2
        end

        # === show ===
        test "GET show returns 401 when not logged in" do
          get api_v1_admin_prompt_set_path(prompt_sets(:general))
          assert_response :unauthorized
        end

        test "GET show returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          get api_v1_admin_prompt_set_path(prompt_sets(:general))
          assert_response :unauthorized
        end

        test "GET show returns 403 when logged in as user_manager (no LlmProvider:read)" do
          user = users(:user_manager)
          post api_v1_admin_session_path, params: { email: user.email, password: TEST_PASSWORD }, as: :json
          get api_v1_admin_prompt_set_path(prompt_sets(:general))
          assert_response :forbidden
        end

        test "GET show returns 200 with prompt set details when logged in as admin" do
          login_as_admin_api
          ps = prompt_sets(:general)
          get api_v1_admin_prompt_set_path(ps)
          assert_response :success
          json = response.parsed_body
          assert_equal ps.id, json["id"]
          assert_equal ps.name, json["name"]
          assert json.key?("prompts")
        end

        test "GET show includes in_use true when prompt set is used in active config" do
          login_as_admin_api
          get api_v1_admin_prompt_set_path(prompt_sets(:general))
          assert_response :success
          assert_equal true, response.parsed_body["in_use"]
        end

        test "GET show includes in_use false when prompt set is not in active config" do
          login_as_admin_api
          get api_v1_admin_prompt_set_path(prompt_sets(:inactive))
          assert_response :success
          assert_equal false, response.parsed_body["in_use"]
        end

        test "GET show returns 200 when logged in as llm_admin" do
          login_as_llm_admin_api
          get api_v1_admin_prompt_set_path(prompt_sets(:general))
          assert_response :success
        end

        test "GET show returns 404 for non-existent prompt set" do
          login_as_admin_api
          get api_v1_admin_prompt_set_path(id: 0)
          assert_response :not_found
        end

        # === create ===
        test "POST create returns 401 when not logged in" do
          post api_v1_admin_prompt_sets_path, params: { prompt_set: { name: "New" } }
          assert_response :unauthorized
        end

        test "POST create returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          post api_v1_admin_prompt_sets_path, params: { prompt_set: { name: "New" } }
          assert_response :unauthorized
        end

        test "POST create returns 403 when logged in as read-only admin" do
          login_as_admin_api_read_only
          post api_v1_admin_prompt_sets_path, params: { prompt_set: { name: "New" } }
          assert_response :forbidden
        end

        test "POST create creates prompt set with nested prompts" do
          login_as_admin_api
          assert_difference "PromptSet.count", 1 do
            assert_difference "Prompt.count", 2 do
              post api_v1_admin_prompt_sets_path, params: {
                prompt_set: {
                  name: "Brand New Set",
                  prompts_attributes: [
                    { role: "system", body: "System prompt", position: 1 },
                    { role: "user", body: "User prompt {{goal}}", position: 2 },
                  ],
                },
              }
            end
          end
          assert_response :created
          json = response.parsed_body
          assert_equal "Brand New Set", json["name"]
          assert_equal 2, json["prompts"].length
        end

        test "POST create returns 422 with invalid params" do
          login_as_admin_api
          post api_v1_admin_prompt_sets_path, params: { prompt_set: { name: "" } }
          assert_response :unprocessable_entity
          assert response.parsed_body.key?("errors")
        end

        test "POST create returns 422 with duplicate name" do
          login_as_admin_api
          post api_v1_admin_prompt_sets_path, params: { prompt_set: { name: prompt_sets(:general).name } }
          assert_response :unprocessable_entity
        end

        test "POST create succeeds when logged in as llm_admin" do
          login_as_llm_admin_api
          post api_v1_admin_prompt_sets_path, params: {
            prompt_set: {
              name: "LLM Admin Created",
              prompts_attributes: [
                { role: "system", body: "Test prompt", position: 1 },
              ],
            },
          }
          assert_response :created
        end

        # === update ===
        test "PATCH update returns 401 when not logged in" do
          patch api_v1_admin_prompt_set_path(prompt_sets(:general)),
                params: { prompt_set: { name: "Updated" } }
          assert_response :unauthorized
        end

        test "PATCH update returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          patch api_v1_admin_prompt_set_path(prompt_sets(:general)),
                params: { prompt_set: { name: "Updated" } }
          assert_response :unauthorized
        end

        test "PATCH update returns 403 when logged in as read-only admin" do
          login_as_admin_api_read_only
          patch api_v1_admin_prompt_set_path(prompt_sets(:general)),
                params: { prompt_set: { name: "Updated" } }
          assert_response :forbidden
        end

        test "PATCH update updates prompt set when logged in as admin" do
          login_as_admin_api
          ps = prompt_sets(:general)
          patch api_v1_admin_prompt_set_path(ps),
                params: { prompt_set: { name: "Updated Name" } }
          assert_response :success
          json = response.parsed_body
          assert_equal "Updated Name", json["name"]
        end

        test "PATCH update returns 422 on invalid params" do
          login_as_admin_api
          patch api_v1_admin_prompt_set_path(prompt_sets(:general)),
                params: { prompt_set: { name: "" } }
          assert_response :unprocessable_entity
        end

        test "PATCH update returns 404 for non-existent prompt set" do
          login_as_admin_api
          patch api_v1_admin_prompt_set_path(id: 0),
                params: { prompt_set: { name: "Updated" } }
          assert_response :not_found
        end

        test "PATCH update includes in_use flag when prompt set is used in active config" do
          login_as_admin_api
          ps = prompt_sets(:general)
          patch api_v1_admin_prompt_set_path(ps),
                params: { prompt_set: { name: "Still General" } }
          assert_response :success
          json = response.parsed_body
          assert_equal true, json["in_use"]
        end

        test "PATCH update includes in_use false when prompt set is not in active config" do
          login_as_admin_api
          ps = prompt_sets(:inactive)
          patch api_v1_admin_prompt_set_path(ps),
                params: { prompt_set: { name: "Still Inactive" } }
          assert_response :success
          json = response.parsed_body
          assert_equal false, json["in_use"]
        end

        test "PATCH update can update nested prompts" do
          login_as_admin_api
          ps = prompt_sets(:coding)
          prompt = ps.prompts.first
          patch api_v1_admin_prompt_set_path(ps),
                params: {
                  prompt_set: {
                    prompts_attributes: [
                      { id: prompt.id, body: "Updated body" },
                    ],
                  },
                }
          assert_response :success
          assert_equal "Updated body", prompt.reload.body
        end

        test "PATCH update can add new prompts" do
          login_as_admin_api
          ps = prompt_sets(:coding)
          original_count = ps.prompts.count
          patch api_v1_admin_prompt_set_path(ps),
                params: {
                  prompt_set: {
                    prompts_attributes: [
                      { role: "user", body: "Additional prompt", position: 99 },
                    ],
                  },
                }
          assert_response :success
          assert_equal original_count + 1, ps.prompts.reload.count
        end

        test "PATCH update can destroy prompts via _destroy" do
          login_as_admin_api
          ps = prompt_sets(:coding)
          prompt = ps.prompts.first
          assert_difference "Prompt.count", -1 do
            patch api_v1_admin_prompt_set_path(ps),
                  params: {
                    prompt_set: {
                      prompts_attributes: [
                        { id: prompt.id, _destroy: true },
                      ],
                    },
                  }
          end
          assert_response :success
        end

        test "PATCH update returns 422 when prompt has invalid role" do
          login_as_admin_api
          ps = prompt_sets(:coding)
          patch api_v1_admin_prompt_set_path(ps),
                params: {
                  prompt_set: {
                    prompts_attributes: [
                      { role: "invalid", body: "test", position: 99 },
                    ],
                  },
                }
          assert_response :unprocessable_entity
        end

        test "PATCH update returns 422 when prompt body is blank" do
          login_as_admin_api
          ps = prompt_sets(:coding)
          prompt = ps.prompts.first
          patch api_v1_admin_prompt_set_path(ps),
                params: {
                  prompt_set: {
                    prompts_attributes: [
                      { id: prompt.id, body: "" },
                    ],
                  },
                }
          assert_response :unprocessable_entity
        end

        test "PATCH update response returns prompts ordered by position" do
          login_as_admin_api
          ps = prompt_sets(:coding)
          patch api_v1_admin_prompt_set_path(ps),
                params: { prompt_set: { name: "Order Check" } }
          assert_response :success
          positions = response.parsed_body["prompts"].pluck("position")
          assert_equal positions.sort, positions
        end

        test "PATCH update succeeds when logged in as llm_admin" do
          login_as_llm_admin_api
          patch api_v1_admin_prompt_set_path(prompt_sets(:coding)),
                params: { prompt_set: { name: "LLM Admin Updated" } }
          assert_response :success
        end
      end
    end
  end
end
