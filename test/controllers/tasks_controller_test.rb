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

  test "create without recurrence (frequency=none) does not create series" do
    login_as_regular_user
    project = projects(:two)

    assert_difference("TaskSeries.count", 0) do
      post tasks_url, params: {
        project_id: project.id,
        task: { name: "単発タスク", due_date: Date.current },
        recurrence: { frequency: "none" },
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
    assert_equal "新しい説明", ActionController::Base.helpers.strip_tags(series.description.to_s).strip
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

  test "create with invalid recurrence combo returns 422 and does not create task/series" do
    login_as_regular_user
    project = projects(:two)

    assert_no_difference(["Task.count", "TaskSeries.count"]) do
      post tasks_url, params: {
        project_id: project.id,
        task: { name: "定例会議", due_date: Date.current },
        recurrence: {
          frequency: "weekly",
          interval: "1",
          by_weekday: %w[mo],
          end_mode: "count",
          # count intentionally missing → invalid
        },
      }
    end

    assert_response :unprocessable_content
    # Response should be the re-rendered :new form, not a generic error page.
    assert_select "form.task-form"
  end

  test "update with invalid recurrence rolls back and returns 422 without partial write" do
    login_as_regular_user
    task = tasks(:recurring_weekly)
    series = task.task_series
    original_name = task.name
    original_series_frequency = series.frequency

    patch task_url(task), params: {
      scope: "all_future",
      task: { name: "changed", due_date: task.due_date },
      recurrence: {
        frequency: "daily",
        interval: "0", # invalid
        end_mode: "infinite",
      },
    }

    assert_response :unprocessable_content
    assert_equal original_name, task.reload.name
    assert_equal original_series_frequency, series.reload.frequency
  end

  test "update with frequency=none stops the series" do
    login_as_regular_user
    task = tasks(:recurring_weekly)
    series = task.task_series
    assert_nil series.stopped_at

    patch task_url(task), params: {
      scope: "only_this",
      task: { name: task.name, due_date: task.due_date },
      recurrence: { frequency: "none", interval: "1", end_mode: "infinite" },
    }

    assert_redirected_to task_url(task)
    assert_not_nil series.reload.stopped_at
  end

  test "create with end_mode=count seeds occurrences_generated so seed counts as first" do
    login_as_regular_user
    project = projects(:two)

    post tasks_url, params: {
      project_id: project.id,
      task: { name: "1回だけタスク", due_date: Date.current },
      recurrence: {
        frequency: "daily", interval: "1",
        end_mode: "count", count: "1"
      },
    }

    series = Task.order(:id).last.task_series
    assert_not_nil series
    assert_equal 1, series.occurrences_generated,
                 "seed task must count as the first occurrence"
    assert series.terminated?, "count=1 series should be exhausted after seed"
  end

  test "update converts non-recurring task into a recurring series" do
    login_as_regular_user
    task = tasks(:two)
    assert_nil task.task_series

    assert_difference("TaskSeries.count", 1) do
      patch task_url(task), params: {
        scope: "",
        task: { name: task.name, due_date: task.due_date },
        recurrence: {
          frequency: "weekly", interval: "1",
          by_weekday: %w[mo], end_mode: "infinite"
        },
      }
    end

    assert_redirected_to task_url(task)
    task.reload
    assert_not_nil task.task_series_id
    assert_equal "weekly", task.task_series.frequency
    assert_equal "mo", task.task_series.by_weekday
    assert_equal 1, task.task_series.occurrences_generated
  end

  test "update scope=all_future clears stale by_weekday when switching from weekly to daily" do
    login_as_regular_user
    task = tasks(:recurring_weekly)
    series = task.task_series
    assert_equal "mo,we,fr", series.by_weekday

    # Simulate the form submitting stale by_weekday checkboxes (hidden by JS
    # but still present in the DOM) while the user switches frequency to daily.
    patch task_url(task), params: {
      scope: "all_future",
      task: { name: task.name, due_date: task.due_date },
      recurrence: { frequency: "daily", interval: "1",
                    by_weekday: %w[mo we fr], end_mode: "infinite" },
    }

    assert_redirected_to task_url(task)
    series.reload
    assert_equal "daily", series.frequency
    assert_nil series.by_weekday
  end
end
