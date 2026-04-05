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

    test "completing recurring task with active series generates next task via broadcast" do
      recurring = tasks(:recurring_weekly)
      post task_complete_path(recurring), as: :turbo_stream
      assert_response :success

      # The response removes the completed task card; the next-instance card
      # is delivered to subscribed clients via Task#broadcast_task_create
      # (see app/views/tasks/completes/create.turbo_stream.erb).
      assert_match 'action="remove"', response.body
      # The new task was generated in the DB
      assert TaskSeries.find(recurring.task_series_id).tasks.uncompleted.exists?
    end

    test "completing recurring task with stopped series does not generate a new task" do
      recurring = tasks(:recurring_weekly)
      recurring.task_series.stop!
      post task_complete_path(recurring), as: :turbo_stream
      assert_response :success

      assert_not TaskSeries.find(recurring.task_series_id).tasks.uncompleted.exists?
    end

    test "completing twice does not generate a second pending instance" do
      recurring = tasks(:recurring_weekly)
      post task_complete_path(recurring), as: :turbo_stream
      assert_response :success
      series_id = recurring.task_series_id

      before_count = Task.where(task_series_id: series_id).count
      post task_complete_path(recurring), as: :turbo_stream
      assert_response :success
      assert_equal before_count, Task.where(task_series_id: series_id).count
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
