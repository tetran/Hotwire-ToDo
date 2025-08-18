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
end
