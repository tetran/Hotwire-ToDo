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

    test "completing subtask returns replace stream keeping it visible as completed" do
      post task_complete_path(@subtask_one), as: :turbo_stream
      assert_response :success

      # サブタスクの partial を差し替える turbo-stream が返ること
      assert_match 'action="replace"', response.body
      assert_match %(target="#{ActionView::RecordIdentifier.dom_id(@subtask_one)}"), response.body
      # 完了状態のクラスが含まれていること（グレー＋取り消し線表示）
      assert_match "task-card--complete", response.body
      # モーダル見出しバッジを更新する turbo-stream も含まれていること
      assert_match %(target="show-subtasks-header-#{@subtask_one.parent_id}"), response.body
      # 通知ストリームも併せて返ること
      assert_match 'target="notification"', response.body
    end

    test "completing root task returns remove stream" do
      post task_complete_path(@parent), as: :turbo_stream
      assert_response :success

      assert_match 'action="remove"', response.body
      assert_match %(target="#{ActionView::RecordIdentifier.dom_id(@parent)}"), response.body
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
