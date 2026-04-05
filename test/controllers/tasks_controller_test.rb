require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @task = tasks(:one)
  end

  test "should get new" do
    login_as_regular_user
    get new_task_url(project_id: projects(:one).id)
    assert_response :success
  end

  test "should create task" do
    login_as_regular_user

    assert_difference("Task.count") do
      post tasks_url, params: { project_id: projects(:one).id, task: { due_date: @task.due_date, name: @task.name } }
    end

    assert_redirected_to task_url(Task.last)
  end

  test "should show task" do
    login_as_regular_user
    get task_url(@task)
    assert_response :success
  end

  test "should get edit" do
    login_as_regular_user
    get edit_task_url(@task)
    assert_response :success
  end

  test "should update task" do
    login_as_regular_user
    patch task_url(@task), params: { task: { completed: @task.completed, due_date: @task.due_date, name: @task.name } }
    assert_redirected_to task_url(@task)
  end

  test "should destroy task" do
    login_as_regular_user
    assert_difference("Task.count", -1) do
      delete task_url(@task)
    end

    assert_redirected_to tasks_url
  end

  test "create with recurrence enabled builds series and template subtasks" do
    login_as_regular_user
    project = projects(:two)

    assert_difference("Task.count", 1) do
      assert_difference("TaskSeries.count", 1) do
        assert_difference("TaskSeriesSubtask.count", 2) do
          post tasks_url, params: {
            project_id: project.id,
            task: { name: "定例会議", due_date: Date.current },
            recurrence: {
              enabled: "1",
              frequency: "weekly",
              interval: "1",
              by_weekday: %w[mo we],
              end_mode: "infinite",
              subtask_names: %w[アジェンダ準備 議事録作成],
            },
          }
        end
      end
    end

    created = Task.order(:id).last
    assert_not_nil created.task_series_id
    series = created.task_series
    assert_equal "weekly", series.frequency
    assert_equal 1, series.interval
    assert_equal "mo,we", series.by_weekday
    assert_equal %w[アジェンダ準備 議事録作成], series.series_subtasks.order(:position).pluck(:name)
  end

  test "create without recurrence enabled does not create series" do
    login_as_regular_user
    project = projects(:two)

    assert_difference("TaskSeries.count", 0) do
      post tasks_url, params: {
        project_id: project.id,
        task: { name: "単発タスク", due_date: Date.current },
        recurrence: { enabled: "0", frequency: "weekly" },
      }
    end

    assert_nil Task.order(:id).last.task_series_id
  end

  test "update scope=only_this does not change series template" do
    login_as_regular_user
    task = tasks(:recurring_weekly)
    series = task.task_series
    original_name = series.name

    patch task_url(task), params: {
      scope: "only_this",
      task: { name: "変更後タスク名", due_date: task.due_date },
    }

    assert_redirected_to task_url(task)
    assert_equal "変更後タスク名", task.reload.name
    assert_equal original_name, series.reload.name
  end

  test "update scope=all_future syncs series with task name and description" do
    login_as_regular_user
    task = tasks(:recurring_weekly)
    series = task.task_series

    patch task_url(task), params: {
      scope: "all_future",
      task: { name: "新タスク名", due_date: task.due_date, description: "新しい説明" },
    }

    assert_redirected_to task_url(task)
    assert_equal "新タスク名", series.reload.name
    assert_equal "新しい説明", series.description.to_s.strip.gsub(/<[^>]*>/, "").strip
  end

  test "update scope=only_this rejects frequency change with 422" do
    login_as_regular_user
    task = tasks(:recurring_weekly)

    patch task_url(task), params: {
      scope: "only_this",
      task: { name: task.name, due_date: task.due_date },
      recurrence: { frequency: "daily", interval: "1", end_mode: "infinite" },
    }

    assert_response :unprocessable_content
    assert_equal "weekly", task.task_series.reload.frequency
  end

  test "update scope=all_future with frequency change updates series template" do
    login_as_regular_user
    task = tasks(:recurring_weekly)
    series = task.task_series

    patch task_url(task), params: {
      scope: "all_future",
      task: { name: task.name, due_date: task.due_date },
      recurrence: { frequency: "daily", interval: "2", by_weekday: [], end_mode: "infinite" },
    }

    assert_redirected_to task_url(task)
    series.reload
    assert_equal "daily", series.frequency
    assert_equal 2, series.interval
    assert_nil series.by_weekday
  end
end
