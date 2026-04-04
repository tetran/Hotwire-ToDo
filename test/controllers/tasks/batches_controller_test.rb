require "test_helper"

module Tasks
  class BatchesControllerTest < ActionDispatch::IntegrationTest
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
      tasks_data = %w[A B C].map do |letter|
        { suggestion_response_id: @response_record.id, name: "Task #{letter}", description: "Desc #{letter}",
          due_date: Date.current }
      end
      SuggestedTask.insert_all!(tasks_data)
      @suggested_tasks = @response_record.suggested_tasks.reload
    end

    test "creates tasks and records adoption outcome" do
      assert_difference "SuggestionOutcome.count", 1 do
        post tasks_batches_path, params: {
          project_id: @project.id,
          suggestion_response_id: @response_record.id,
          tasks: {
            @suggested_tasks[0].id => { checked: "1", name: "Task A", description: "Desc A", due_date: Date.current },
            @suggested_tasks[1].id => { checked: "1", name: "Task B", description: "Desc B", due_date: Date.current },
            @suggested_tasks[2].id => { checked: "0", name: "Task C", description: "Desc C", due_date: Date.current },
          },
        }, as: :turbo_stream
      end

      outcome = SuggestionOutcome.last
      assert_equal 3, outcome.total_suggested
      assert_equal 2, outcome.total_adopted
      assert_in_delta 66.67, outcome.acceptance_rate, 0.01
    end

    test "creates tasks without outcome when suggestion_response_id is missing" do
      assert_no_difference "SuggestionOutcome.count" do
        post tasks_batches_path, params: {
          project_id: @project.id,
          tasks: {
            @suggested_tasks[0].id => { checked: "1", name: "Task A", description: "Desc A", due_date: Date.current },
          },
        }, as: :turbo_stream
      end

      assert_response :success
    end

    test "does not record outcome for another user's suggestion_response" do
      other_user = users(:no_role_user)
      other_session = SuggestionSession.create!(project: @project, requested_by: other_user, goal: "Other")
      other_request = SuggestionRequest.create!(suggestion_session: other_session, raw_request: "{}")
      other_response = SuggestionResponse.create!(
        suggestion_request: other_request, raw_response: "{}", completion_tokens: 0, prompt_tokens: 0,
      )

      assert_no_difference "SuggestionOutcome.count" do
        post tasks_batches_path, params: {
          project_id: @project.id,
          suggestion_response_id: other_response.id,
          tasks: {
            @suggested_tasks[0].id => { checked: "1", name: "Task A", description: "Desc A", due_date: Date.current },
          },
        }, as: :turbo_stream
      end
    end

    test "does not record outcome when suggestion_response belongs to different project" do
      other_project = projects(:two)
      other_session = SuggestionSession.create!(project: other_project, requested_by: @user, goal: "Other project")
      other_request = SuggestionRequest.create!(suggestion_session: other_session, raw_request: "{}")
      other_response = SuggestionResponse.create!(
        suggestion_request: other_request, raw_response: "{}", completion_tokens: 0, prompt_tokens: 0,
      )

      assert_no_difference "SuggestionOutcome.count" do
        post tasks_batches_path, params: {
          project_id: @project.id,
          suggestion_response_id: other_response.id,
          tasks: {
            @suggested_tasks[0].id => { checked: "1", name: "Task A", description: "Desc A", due_date: Date.current },
          },
        }, as: :turbo_stream
      end
    end

    test "creates parent task from session goal with subtasks" do
      assert_difference "Task.count", 3 do # 1 parent + 2 subtasks
        post tasks_batches_path, params: {
          project_id: @project.id,
          suggestion_session_id: @session.id,
          suggestion_response_id: @response_record.id,
          tasks: {
            @suggested_tasks[0].id => { checked: "1", name: "Task A", description: "Desc A", due_date: Date.current },
            @suggested_tasks[1].id => { checked: "1", name: "Task B", description: "Desc B", due_date: Date.current },
            @suggested_tasks[2].id => { checked: "0", name: "Task C", description: "Desc C", due_date: Date.current },
          },
        }, as: :turbo_stream
      end

      parent = Task.find_by(name: "Test goal")
      assert_not_nil parent
      assert_nil parent.parent_id
      assert_equal @project, parent.project
      assert_equal 2, parent.subtasks.count
      assert_equal ["Task A", "Task B"], parent.subtasks.order(:created_at).pluck(:name)
    end

    test "truncates parent task name from goal exceeding 100 chars" do
      long_goal = "a" * 100 # SuggestionSession validates max 100
      @session.update!(goal: long_goal)
      assert_difference "Task.count", 2 do # 1 parent + 1 subtask
        post tasks_batches_path, params: {
          project_id: @project.id,
          suggestion_session_id: @session.id,
          tasks: {
            @suggested_tasks[0].id => { checked: "1", name: "Task A", description: "Desc A", due_date: Date.current },
          },
        }, as: :turbo_stream
      end

      parent = Task.where(parent_id: nil).order(:created_at).last
      assert_equal 100, parent.name.length
    end

    test "outcome recording is idempotent" do
      SuggestionOutcomeService.record_adoption(
        suggestion_response: @response_record,
        adopted_count: 1,
      )

      assert_no_difference "SuggestionOutcome.count" do
        post tasks_batches_path, params: {
          project_id: @project.id,
          suggestion_response_id: @response_record.id,
          tasks: {
            @suggested_tasks[0].id => { checked: "1", name: "Task A", description: "Desc A", due_date: Date.current },
          },
        }, as: :turbo_stream
      end
    end
  end
end
