require "test_helper"

module Tasks
  class SuggestionsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:regular_user)
      @project = projects(:one)
      login_as(@user)

      # Clear recent sessions to avoid rate limit
      SuggestedTask.delete_all
      SuggestionResponse.delete_all
      SuggestionRequest.delete_all
      SuggestionSession.delete_all

      # Set up active config
      SuggestionConfig.update_all(active: false)
      @model = llm_models(:gpt_turbo)
      @prompt_set = prompt_sets(:general)
      @config = SuggestionConfig.create_with_entries!(
        entries_attributes: [{ llm_model_id: @model.id, prompt_set_id: @prompt_set.id, weight: 100 }],
      )
      @entry = @config.entries.first

      @valid_json = '{"tasks":[{"name":"Task 1","description":"Do something","due_date":"2024/01/10"}]}'
      @valid_response = { content: @valid_json, model: "gpt-3.5-turbo",
                          usage: { input_tokens: 100, output_tokens: 50 } }
    end

    test "creates session and returns suggestions on success" do
      mock_client = build_mock_client
      mock_client.stubs(:chat).returns(@valid_response)
      LlmClientFactory.stubs(:create_client_from_model).returns(mock_client)

      assert_difference ["SuggestionSession.count", "SuggestionRequest.count", "SuggestionResponse.count"], 1 do
        post tasks_suggestions_path, params: {
          suggestion_session: {
            goal: "Build an app",
            context: "iOS development",
            start_date: Date.current,
            due_date: Date.current + 1.week,
            project_id: @project.id,
          },
        }
      end

      assert_response :success
      session = SuggestionSession.last
      assert_equal "Build an app", session.goal
      assert_equal @user, session.requested_by
    end

    test "returns error with retry form when no suggestion config is active" do
      SuggestionConfig.update_all(active: false)

      post tasks_suggestions_path, params: {
        suggestion_session: {
          goal: "Build an app",
          project_id: @project.id,
        },
      }

      assert_response :success
      assert_includes response.body, "simple-error"
      assert_includes response.body, "task-suggestion-form"
    end

    test "returns error with retry form when LLM call fails" do
      mock_client = build_mock_client
      mock_client.stubs(:chat).raises(LlmClient::ApiError.new("Unauthorized", 401))
      LlmClientFactory.stubs(:create_client_from_model).returns(mock_client)

      post tasks_suggestions_path, params: {
        suggestion_session: {
          goal: "Build an app",
          project_id: @project.id,
        },
      }

      assert_response :success
      assert_includes response.body, "simple-error"
      assert_includes response.body, "task-suggestion-form"
    end

    test "returns unprocessable when session validation fails" do
      post tasks_suggestions_path, params: {
        suggestion_session: {
          goal: "", # blank goal
          project_id: @project.id,
        },
      }

      assert_response :unprocessable_content
    end

    test "rejects project_id the user does not belong to" do
      other_project = projects(:admin_user_inbox)

      post tasks_suggestions_path, params: {
        suggestion_session: {
          goal: "Build an app",
          project_id: other_project.id,
        },
      }

      assert_response :not_found
    end

    test "enforces rate limiting via session" do
      mock_client = build_mock_client
      mock_client.stubs(:chat).returns(@valid_response)
      LlmClientFactory.stubs(:create_client_from_model).returns(mock_client)

      # Create 2 sessions to reach limit
      2.times do |i|
        post tasks_suggestions_path, params: {
          suggestion_session: {
            goal: "Goal #{i}",
            project_id: @project.id,
          },
        }
      end

      # Third should fail
      post tasks_suggestions_path, params: {
        suggestion_session: {
          goal: "Too many",
          project_id: @project.id,
        },
      }

      assert_response :unprocessable_content
    end

    private

      def build_mock_client
        mock_client = mock("llm_client")
        mock_client.stubs(:json_output_options).returns({})
        mock_client
      end
  end
end
