require "test_helper"

module Tasks
  class CompletesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:regular_user)
      @parent = tasks(:parent_task)
      @subtask_one = tasks(:subtask_one)
      @subtask_two = tasks(:subtask_two)
      login_as(@user)
    end

    test "completing parent task cascades to uncompleted subtasks" do
      post task_complete_path(@parent), as: :turbo_stream
      assert_response :success

      assert @parent.reload.completed?
      assert @subtask_one.reload.completed?
      assert @subtask_two.reload.completed? # was already completed
    end

    test "completing subtask does not affect parent" do
      post task_complete_path(@subtask_one), as: :turbo_stream
      assert_response :success

      assert @subtask_one.reload.completed?
      assert_not @parent.reload.completed?
    end

    test "completed tasks index shows root tasks with subtasks nested" do
      @parent.complete!
      project = projects(:two)
      get tasks_completes_path(project_id: project.id, show: true), as: :turbo_stream
      assert_response :success
      assert_match @parent.name, response.body
      # Subtask two (standalone task) should NOT appear as a root-level task
      standalone = tasks(:two)
      standalone.complete!
      get tasks_completes_path(project_id: project.id, show: true), as: :turbo_stream
      assert_match standalone.name, response.body
    end
  end
end
