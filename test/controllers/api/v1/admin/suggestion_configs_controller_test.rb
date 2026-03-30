require "test_helper"

module Api
  module V1
    module Admin
      class SuggestionConfigsControllerTest < ActionDispatch::IntegrationTest
        setup do
          SuggestionConfig.update_all(active: false)
          suggestion_configs(:active_config).update!(active: true)
        end

        # === index ===
        test "GET index returns 401 when not logged in" do
          get api_v1_admin_suggestion_configs_path
          assert_response :unauthorized
        end

        test "GET index returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          get api_v1_admin_suggestion_configs_path
          assert_response :unauthorized
        end

        test "GET index returns 403 when logged in as user_manager (no LlmProvider:read)" do
          user = users(:user_manager)
          post api_v1_admin_session_path, params: { email: user.email, password: TEST_PASSWORD }, as: :json
          get api_v1_admin_suggestion_configs_path
          assert_response :forbidden
        end

        test "GET index returns 200 with config list when logged in as admin" do
          login_as_admin_api
          get api_v1_admin_suggestion_configs_path
          assert_response :success
          json = response.parsed_body
          assert_kind_of Array, json
          ids = json.pluck("id")
          assert_includes ids, suggestion_configs(:active_config).id
          assert_includes ids, suggestion_configs(:inactive_config).id
        end

        test "GET index returns 200 when logged in as llm_admin" do
          login_as_llm_admin_api
          get api_v1_admin_suggestion_configs_path
          assert_response :success
        end

        test "GET index returns configs in descending order by id" do
          login_as_admin_api
          get api_v1_admin_suggestion_configs_path
          assert_response :success
          json = response.parsed_body
          ids = json.pluck("id")
          assert_equal ids.sort.reverse, ids
        end

        test "GET index includes entries with model and prompt_set names" do
          login_as_admin_api
          get api_v1_admin_suggestion_configs_path
          assert_response :success
          json = response.parsed_body
          active = json.find { |c| c["id"] == suggestion_configs(:active_config).id }
          assert active.key?("entries")
          assert_kind_of Array, active["entries"]
          entry = active["entries"].first
          assert entry.key?("llm_model")
          assert entry.key?("prompt_set")
          assert entry["llm_model"].key?("display_name")
          assert entry["prompt_set"].key?("name")
        end

        # === show ===
        test "GET show returns 401 when not logged in" do
          get api_v1_admin_suggestion_config_path(suggestion_configs(:active_config))
          assert_response :unauthorized
        end

        test "GET show returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          get api_v1_admin_suggestion_config_path(suggestion_configs(:active_config))
          assert_response :unauthorized
        end

        test "GET show returns 403 when logged in as user_manager (no LlmProvider:read)" do
          user = users(:user_manager)
          post api_v1_admin_session_path, params: { email: user.email, password: TEST_PASSWORD }, as: :json
          get api_v1_admin_suggestion_config_path(suggestion_configs(:active_config))
          assert_response :forbidden
        end

        test "GET show returns 200 with config details when logged in as admin" do
          login_as_admin_api
          config = suggestion_configs(:active_config)
          get api_v1_admin_suggestion_config_path(config)
          assert_response :success
          json = response.parsed_body
          assert_equal config.id, json["id"]
          assert_equal true, json["active"]
          assert json.key?("entries")
        end

        test "GET show returns 200 when logged in as llm_admin" do
          login_as_llm_admin_api
          get api_v1_admin_suggestion_config_path(suggestion_configs(:active_config))
          assert_response :success
        end

        test "GET show returns 404 for non-existent config" do
          login_as_admin_api
          get api_v1_admin_suggestion_config_path(id: 0)
          assert_response :not_found
        end

        test "GET show includes entries with model and prompt_set info" do
          login_as_admin_api
          config = suggestion_configs(:active_config)
          get api_v1_admin_suggestion_config_path(config)
          assert_response :success
          json = response.parsed_body
          assert json["entries"].length >= 2
          entry = json["entries"].first
          assert entry.key?("weight")
          assert entry.key?("llm_model")
          assert entry.key?("prompt_set")
        end

        # === create ===
        test "POST create returns 401 when not logged in" do
          post api_v1_admin_suggestion_configs_path,
               params: { suggestion_config: { entries_attributes: [] } }
          assert_response :unauthorized
        end

        test "POST create returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          post api_v1_admin_suggestion_configs_path,
               params: { suggestion_config: { entries_attributes: [] } }
          assert_response :unauthorized
        end

        test "POST create returns 403 when logged in as read-only admin" do
          login_as_admin_api_read_only
          post api_v1_admin_suggestion_configs_path,
               params: { suggestion_config: { entries_attributes: [] } }
          assert_response :forbidden
        end

        test "POST create creates suggestion config with entries" do
          login_as_admin_api
          assert_difference "SuggestionConfig.count", 1 do
            post api_v1_admin_suggestion_configs_path, params: {
              suggestion_config: {
                entries_attributes: [
                  { llm_model_id: llm_models(:gpt_turbo).id, prompt_set_id: prompt_sets(:general).id, weight: 100 },
                ],
              },
            }
          end
          assert_response :created
          json = response.parsed_body
          assert_equal true, json["active"]
          assert_equal 1, json["entries"].length
        end

        test "POST create deactivates previous active config" do
          login_as_admin_api
          old_active = suggestion_configs(:active_config)
          assert old_active.active?

          post api_v1_admin_suggestion_configs_path, params: {
            suggestion_config: {
              entries_attributes: [
                { llm_model_id: llm_models(:gpt_turbo).id, prompt_set_id: prompt_sets(:general).id, weight: 100 },
              ],
            },
          }
          assert_response :created
          assert_equal false, old_active.reload.active?
          assert_equal true, SuggestionConfig.last.active?
        end

        test "POST create returns 422 when weights do not sum to 100" do
          login_as_admin_api
          post api_v1_admin_suggestion_configs_path, params: {
            suggestion_config: {
              entries_attributes: [
                { llm_model_id: llm_models(:gpt_turbo).id, prompt_set_id: prompt_sets(:general).id, weight: 50 },
                { llm_model_id: llm_models(:gpt4).id, prompt_set_id: prompt_sets(:coding).id, weight: 40 },
              ],
            },
          }
          assert_response :unprocessable_entity
          assert response.parsed_body.key?("errors")
        end

        test "POST create returns 422 with no entries" do
          login_as_admin_api
          post api_v1_admin_suggestion_configs_path, params: {
            suggestion_config: {
              entries_attributes: [],
            },
          }
          assert_response :unprocessable_entity
        end

        test "POST create returns 422 with more than 3 entries" do
          login_as_admin_api
          post api_v1_admin_suggestion_configs_path, params: {
            suggestion_config: {
              entries_attributes: [
                { llm_model_id: llm_models(:gpt_turbo).id, prompt_set_id: prompt_sets(:general).id, weight: 25 },
                { llm_model_id: llm_models(:gpt4).id, prompt_set_id: prompt_sets(:coding).id, weight: 25 },
                { llm_model_id: llm_models(:claude).id, prompt_set_id: prompt_sets(:general).id, weight: 25 },
                { llm_model_id: llm_models(:claude).id, prompt_set_id: prompt_sets(:coding).id, weight: 25 },
              ],
            },
          }
          assert_response :unprocessable_entity
        end

        test "POST create returns 422 with duplicate model+prompt_set combination" do
          login_as_admin_api
          post api_v1_admin_suggestion_configs_path, params: {
            suggestion_config: {
              entries_attributes: [
                { llm_model_id: llm_models(:gpt_turbo).id, prompt_set_id: prompt_sets(:general).id, weight: 50 },
                { llm_model_id: llm_models(:gpt_turbo).id, prompt_set_id: prompt_sets(:general).id, weight: 50 },
              ],
            },
          }
          assert_response :unprocessable_entity
        end

        test "POST create succeeds when logged in as llm_admin" do
          login_as_llm_admin_api
          post api_v1_admin_suggestion_configs_path, params: {
            suggestion_config: {
              entries_attributes: [
                { llm_model_id: llm_models(:gpt_turbo).id, prompt_set_id: prompt_sets(:general).id, weight: 100 },
              ],
            },
          }
          assert_response :created
        end

        # === update ===
        test "PATCH update returns 401 when not logged in" do
          patch api_v1_admin_suggestion_config_path(suggestion_configs(:active_config)),
                params: { suggestion_config: { entries_attributes: [] } }
          assert_response :unauthorized
        end

        test "PATCH update returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          patch api_v1_admin_suggestion_config_path(suggestion_configs(:active_config)),
                params: { suggestion_config: { entries_attributes: [] } }
          assert_response :unauthorized
        end

        test "PATCH update returns 403 when logged in as read-only admin" do
          login_as_admin_api_read_only
          patch api_v1_admin_suggestion_config_path(suggestion_configs(:active_config)),
                params: { suggestion_config: { entries_attributes: [] } }
          assert_response :forbidden
        end

        test "PATCH update returns 422 when config is inactive" do
          login_as_admin_api
          patch api_v1_admin_suggestion_config_path(suggestion_configs(:inactive_config)),
                params: {
                  suggestion_config: {
                    entries_attributes: [
                      { llm_model_id: llm_models(:gpt_turbo).id, prompt_set_id: prompt_sets(:general).id, weight: 100 },
                    ],
                  },
                }
          assert_response :unprocessable_entity
          assert_equal "Only active suggestion configs can be updated", response.parsed_body["error"]
        end

        test "PATCH update can update entry weight on active config" do
          login_as_admin_api
          config = suggestion_configs(:active_config)
          entry = suggestion_config_entries(:entry_one)
          patch api_v1_admin_suggestion_config_path(config),
                params: {
                  suggestion_config: {
                    entries_attributes: [
                      { id: entry.id, weight: 60 },
                      { id: suggestion_config_entries(:entry_two).id, weight: 40 },
                    ],
                  },
                }
          assert_response :success
          assert_equal 60, entry.reload.weight
        end

        test "PATCH update returns 422 when updated weights do not sum to 100" do
          login_as_admin_api
          config = suggestion_configs(:active_config)
          entry = suggestion_config_entries(:entry_one)
          patch api_v1_admin_suggestion_config_path(config),
                params: {
                  suggestion_config: {
                    entries_attributes: [
                      { id: entry.id, weight: 99 },
                    ],
                  },
                }
          assert_response :unprocessable_entity
        end

        test "PATCH update returns 404 for non-existent config" do
          login_as_admin_api
          patch api_v1_admin_suggestion_config_path(id: 0),
                params: { suggestion_config: { entries_attributes: [] } }
          assert_response :not_found
        end

        test "PATCH update succeeds when logged in as llm_admin" do
          login_as_llm_admin_api
          config = suggestion_configs(:active_config)
          entry_one = suggestion_config_entries(:entry_one)
          entry_two = suggestion_config_entries(:entry_two)
          patch api_v1_admin_suggestion_config_path(config),
                params: {
                  suggestion_config: {
                    entries_attributes: [
                      { id: entry_one.id, weight: 60 },
                      { id: entry_two.id, weight: 40 },
                    ],
                  },
                }
          assert_response :success
        end
      end
    end
  end
end
