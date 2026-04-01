require "test_helper"

module Tasks
  module Suggestions
    class AbandonmentsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:regular_user)
        @project = projects(:one)
        login_as(@user)

        SuggestedTask.delete_all
        SuggestionResponse.delete_all
        SuggestionRequest.delete_all
        SuggestionSession.delete_all

        @session = SuggestionSession.create!(
          project: @project,
          requested_by: @user,
          goal: "Test goal",
        )
        @request_record = SuggestionRequest.create!(
          suggestion_session: @session,
          raw_request: "{}",
        )
        @response_record = SuggestionResponse.create!(
          suggestion_request: @request_record,
          raw_response: "{}",
          completion_tokens: 10,
          prompt_tokens: 20,
        )
        tasks = Array.new(2) do |i|
          { suggestion_response_id: @response_record.id, name: "T#{i + 1}",
            description: "D#{i + 1}", due_date: Date.current }
        end
        SuggestedTask.insert_all!(tasks)
      end

      test "records abandonment with 0% acceptance" do
        assert_difference "SuggestionOutcome.count", 1 do
          post tasks_suggestion_abandonment_path(@session),
               params: { suggestion_response_id: @response_record.id }
        end

        assert_response :no_content
        outcome = SuggestionOutcome.last
        assert_equal 2, outcome.total_suggested
        assert_equal 0, outcome.total_adopted
      end

      test "is idempotent" do
        post tasks_suggestion_abandonment_path(@session),
             params: { suggestion_response_id: @response_record.id }

        assert_no_difference "SuggestionOutcome.count" do
          post tasks_suggestion_abandonment_path(@session),
               params: { suggestion_response_id: @response_record.id }
        end

        assert_response :no_content
      end

      test "does not record abandonment for another user's suggestion_response" do
        other_user = users(:no_role_user)
        other_session = SuggestionSession.create!(project: @project, requested_by: other_user, goal: "Other")
        other_request = SuggestionRequest.create!(suggestion_session: other_session, raw_request: "{}")
        other_response = SuggestionResponse.create!(
          suggestion_request: other_request, raw_response: "{}", completion_tokens: 0, prompt_tokens: 0,
        )

        assert_no_difference "SuggestionOutcome.count" do
          post tasks_suggestion_abandonment_path(@session),
               params: { suggestion_response_id: other_response.id }
        end

        assert_response :no_content
      end

      test "returns no_content even with invalid response_id" do
        post tasks_suggestion_abandonment_path(@session),
             params: { suggestion_response_id: 0 }

        assert_response :no_content
      end

      test "does not record abandonment for response belonging to another session of same user" do
        other_session = SuggestionSession.create!(project: @project, requested_by: @user, goal: "Other session")
        other_request = SuggestionRequest.create!(suggestion_session: other_session, raw_request: "{}")
        other_response = SuggestionResponse.create!(
          suggestion_request: other_request, raw_response: "{}", completion_tokens: 0, prompt_tokens: 0,
        )

        assert_no_difference "SuggestionOutcome.count" do
          post tasks_suggestion_abandonment_path(@session),
               params: { suggestion_response_id: other_response.id }
        end

        assert_response :no_content
      end

      test "requires authentication" do
        delete logout_path
        post tasks_suggestion_abandonment_path(@session),
             params: { suggestion_response_id: @response_record.id }

        assert_redirected_to login_path
      end
    end
  end
end
