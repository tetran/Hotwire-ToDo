require "test_helper"

module Tasks
  class SubtasksControllerTest < ActionDispatch::IntegrationTest
    setup do
      @parent = tasks(:parent_task)
      @project = projects(:two)
    end

    test "should get new" do
      login_as_regular_user
      get new_task_subtask_path(@parent)
      assert_response :success
    end

    test "should create subtask" do
      login_as_regular_user
      assert_difference("Task.count") do
        post task_subtasks_path(@parent), params: {
          task: { name: "New Subtask", due_date: "2024-02-01" },
        }
      end

      subtask = Task.last
      assert_equal @parent, subtask.parent
      assert_equal @project, subtask.project
      assert_equal "New Subtask", subtask.name
    end

    test "should not create subtask for non-member project task" do
      # login as no_role_user who is NOT a member of project :two
      login_as(users(:no_role_user))
      assert_no_difference("Task.count") do
        post task_subtasks_path(@parent), params: {
          task: { name: "Sneaky Subtask" },
        }
      end
    end

    test "should not create subtask under a subtask" do
      login_as_regular_user
      subtask = tasks(:subtask_one)
      assert_no_difference("Task.count") do
        post task_subtasks_path(subtask), params: {
          task: { name: "Grandchild" },
        }
      end
      assert_response :unprocessable_content
    end
  end
end
